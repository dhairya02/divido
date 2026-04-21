import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'receipt_scanner.dart';

/// Thrown when the Gemini API call fails or returns something we couldn't
/// parse. Callers (typically [ReceiptScannerService]) catch this to fall back
/// to on-device OCR so the user still gets *something* useful.
class GeminiScanException implements Exception {
  GeminiScanException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'GeminiScanException(${statusCode ?? '-'}): $message';
}

/// Calls Google's Gemini multimodal API with the raw receipt image and asks
/// for a structured JSON breakdown. Massively more accurate than line-by-line
/// OCR + regex once the network is available.
///
/// The API key is *never* persisted by this class — callers pass it in (we
/// store it in the SQLite `settings` table on the device).
class GeminiReceiptScanner {
  GeminiReceiptScanner({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Prompt focuses Gemini on returning *only* what we can use programmatically
  /// — no preamble, no markdown, just the JSON we asked for. The
  /// `response_mime_type=application/json` config below is the real
  /// guarantee, but the prompt belt-and-braces it.
  static const _systemPrompt = '''
You extract structured data from a single photograph of a restaurant or retail
receipt.

Return ONLY a JSON object that conforms to the provided schema. All monetary
values must be expressed as integer cents (multiply the printed amount by 100
and round to the nearest integer). Quantity defaults to 1 when unclear.

Rules:
- Skip payment / change / loyalty lines — only include actual purchased items.
- If a line has a quantity prefix like "2 x" or "x3", extract it into
  `quantity` and put the unit price (NOT the line total) into `priceCents`.
- `merchant` should be the store / restaurant name from the top of the
  receipt, not an address.
- `taxCents` should sum every tax-like line (sales tax, GST, VAT, HST).
- `tipCents` should reflect any printed tip / gratuity / service charge.
- `subtotalCents` is the pre-tax/tip subtotal. If the receipt prints one,
  use that; otherwise leave it null.
- `totalCents` is the final printed grand total, when shown.
- If you cannot read the receipt at all, return an object with empty `items`
  and null totals.
''';

  /// JSON schema passed via `responseSchema` so Gemini's output matches what
  /// our parser expects. Field names mirror [ScannedItem] / [ScannedTotals]
  /// for a 1-to-1 mapping.
  static const _schema = <String, Object?>{
    'type': 'OBJECT',
    'properties': {
      'merchant': {'type': 'STRING', 'nullable': true},
      'currency': {'type': 'STRING', 'nullable': true},
      'items': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'quantity': {'type': 'INTEGER'},
            'priceCents': {'type': 'INTEGER'},
          },
          'required': ['name', 'priceCents'],
        },
      },
      'subtotalCents': {'type': 'INTEGER', 'nullable': true},
      'taxCents': {'type': 'INTEGER', 'nullable': true},
      'tipCents': {'type': 'INTEGER', 'nullable': true},
      'totalCents': {'type': 'INTEGER', 'nullable': true},
    },
    'required': ['items'],
  };

  Future<ScanResult> scanFile(File file) async {
    final bytes = await file.readAsBytes();
    final mime = _mimeFromPath(file.path);
    return scanBytes(bytes, mimeType: mime);
  }

  Future<ScanResult> scanBytes(
    List<int> bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final uri = Uri.parse(
      '$_endpoint/$model:generateContent?key=$apiKey',
    );
    final body = jsonEncode(<String, Object?>{
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Extract the items and totals from this receipt as JSON.',
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'response_mime_type': 'application/json',
        'response_schema': _schema,
      },
    });

    http.Response resp;
    try {
      resp = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException catch (e) {
      throw GeminiScanException('Network error: ${e.message}');
    }

    if (resp.statusCode != 200) {
      throw GeminiScanException(
        _extractApiError(resp.body) ?? resp.body,
        statusCode: resp.statusCode,
      );
    }

    final decoded = jsonDecode(resp.body) as Map<String, Object?>;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw GeminiScanException('No candidates in response');
    }
    final firstCandidate = candidates.first as Map<String, Object?>;
    final content = firstCandidate['content'] as Map<String, Object?>?;
    final parts = content?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw GeminiScanException('Empty response content');
    }
    final text = (parts.first as Map<String, Object?>)['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw GeminiScanException('Model returned no text');
    }

    final Map<String, Object?> json;
    try {
      json = jsonDecode(text) as Map<String, Object?>;
    } catch (e) {
      throw GeminiScanException('Could not parse JSON: $e');
    }

    return _toScanResult(json);
  }

  void dispose() => _client.close();

  static ScanResult _toScanResult(Map<String, Object?> json) {
    final rawItems = json['items'];
    final items = <ScannedItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final name = (raw['name'] as String?)?.trim();
        final price = _asInt(raw['priceCents']);
        if (name == null || name.isEmpty || price == null || price <= 0) {
          continue;
        }
        final qty = (_asInt(raw['quantity']) ?? 1).clamp(1, 99);
        items.add(
          ScannedItem(name: name, priceCents: price, quantity: qty),
        );
      }
    }

    final totals = ScannedTotals(
      subtotalCents: _asInt(json['subtotalCents']),
      taxCents: _asInt(json['taxCents']),
      tipCents: _asInt(json['tipCents']),
      totalCents: _asInt(json['totalCents']),
    );

    // If the model didn't surface a subtotal but did extract items, fall back
    // to summing them — same heuristic as the on-device parser, so the UI's
    // "use these items" footer always shows a sensible number.
    if (totals.subtotalCents == null && items.isNotEmpty) {
      totals.subtotalCents = items.fold<int>(
        0,
        (acc, it) => acc + it.priceCents * it.quantity,
      );
    }

    final merchant = (json['merchant'] as String?)?.trim();
    return ScanResult(
      items: items,
      totals: totals,
      merchant: (merchant == null || merchant.isEmpty) ? null : merchant,
    );
  }

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
    return null;
  }

  static String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  /// Gemini surfaces errors as `{"error": {"message": "...", "status": "..."}}`.
  /// Pull the human-readable bit out so our snackbar isn't a wall of JSON.
  static String? _extractApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final err = decoded['error'] as Map;
        return err['message'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
