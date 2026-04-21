import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'apple_receipt_scanner.dart';
import 'gemini_receipt_scanner.dart';

/// A single line item parsed from a receipt photo.
class ScannedItem {
  ScannedItem({
    required this.name,
    required this.priceCents,
    this.quantity = 1,
  });

  String name;
  int priceCents;
  int quantity;
}

/// Totals (tax, tip, subtotal, grand total) recognised on a receipt. Any of
/// these may be `null` when not detected — the UI then leaves the matching
/// field blank for the user to fill in.
class ScannedTotals {
  ScannedTotals({
    this.subtotalCents,
    this.taxCents,
    this.tipCents,
    this.totalCents,
  });

  int? subtotalCents;
  int? taxCents;
  int? tipCents;
  int? totalCents;

  bool get hasAny =>
      subtotalCents != null ||
      taxCents != null ||
      tipCents != null ||
      totalCents != null;
}

/// Result of scanning a single receipt image.
class ScanResult {
  ScanResult({
    required this.items,
    required this.totals,
    required this.merchant,
  });

  final List<ScannedItem> items;
  final ScannedTotals totals;

  /// Best-guess merchant / store name extracted from the top of the receipt.
  /// Used to pre-fill the bill's venue field.
  final String? merchant;
}

/// Where the receipt image should come from.
enum ReceiptSource { camera, gallery }

/// Which engine actually produced a [ScanResult]. Surfaced so the UI can show
/// a "Powered by Gemini" hint or warn the user that a fallback engine kicked
/// in.
///
/// Priority on iOS 26+ Apple-Intelligence devices:
///   [appleIntelligence] → [gemini] (if a key is configured) → [onDevice].
/// On every other platform / older OS we skip [appleIntelligence] entirely.
enum ScanEngine { appleIntelligence, gemini, onDevice }

/// A scan plus metadata about *how* it was produced.
class ScanOutcome {
  ScanOutcome({
    required this.result,
    required this.engine,
    this.fallbackReason,
  });

  final ScanResult result;
  final ScanEngine engine;

  /// Populated when [engine] is something other than the caller's preferred
  /// path *because* the higher-priority engine failed. Lets the UI tell the
  /// user why we fell back without leaking raw API errors in the happy path.
  final String? fallbackReason;
}

/// Resolves the API key to use for a Gemini-powered scan. The `Future`
/// signature lets callers read it from SharedPreferences / SQLite asynchronously
/// without blocking the constructor.
typedef GeminiApiKeyResolver = Future<String?> Function();

/// Compile-time fallback key — set with
/// `flutter run --dart-define=GEMINI_API_KEY=ya29...` for local development.
/// Empty string when not provided.
const String kGeminiApiKeyDartDefine =
    String.fromEnvironment('GEMINI_API_KEY');

/// Key used in the [LocalRepository] settings table for the user-supplied
/// Gemini API key. Account screen writes here, scanner reads from it.
const String kGeminiApiKeySettingName = 'gemini_api_key';

/// Wraps `image_picker` and dispatches OCR to whichever scanner is best for
/// the device. Priority:
///
/// 1. [AppleReceiptScanner] — Vision OCR + on-device Foundation Models LLM
///    with guided generation. iOS 26+ on Apple-Intelligence-eligible
///    hardware. Free, offline, private.
/// 2. [GeminiReceiptScanner] — cloud multimodal model. Used when the user
///    has supplied a Gemini API key (or one is set via `--dart-define`).
/// 3. ML Kit `TextRecognizer` + the heuristic parser below — original
///    implementation, kept as the universal safety net.
class ReceiptScannerService {
  ReceiptScannerService({
    ImagePicker? picker,
    TextRecognizer? recognizer,
    this.geminiApiKey,
    this.geminiKeyResolver,
    GeminiReceiptScanner? gemini,
    AppleReceiptScanner? apple,
  })  : _picker = picker ?? ImagePicker(),
        _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin),
        _gemini = gemini,
        _apple = apple ?? AppleReceiptScanner();

  final ImagePicker _picker;
  final TextRecognizer _recognizer;

  /// Static API key (e.g. from `--dart-define=GEMINI_API_KEY=...`). When
  /// non-null this takes precedence over [geminiKeyResolver].
  final String? geminiApiKey;

  /// Lazily resolves a key at scan time — typically reads from the on-device
  /// settings table so users can paste a key in the Account screen.
  final GeminiApiKeyResolver? geminiKeyResolver;

  GeminiReceiptScanner? _gemini;
  final AppleReceiptScanner _apple;

  /// Returns the active key, preferring an injected scanner > static key >
  /// resolver. `null` means "no key, use on-device".
  Future<String?> _resolveKey() async {
    if (_gemini != null) return _gemini!.apiKey;
    if (geminiApiKey != null && geminiApiKey!.isNotEmpty) {
      return geminiApiKey;
    }
    if (geminiKeyResolver != null) {
      final key = await geminiKeyResolver!.call();
      if (key != null && key.isNotEmpty) return key;
    }
    return null;
  }

  /// Asks the user for a photo (camera or gallery), runs the scan, then
  /// returns the parsed items + totals. Returns `null` if the user cancels.
  Future<ScanOutcome?> scan(ReceiptSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source == ReceiptSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (file == null) return null;
    return scanFile(File(file.path));
  }

  /// Lower-level entry point — operates on an existing file. Useful for
  /// tests that bundle a fixture image.
  ///
  /// Tries Apple's on-device pipeline first (when available), then Gemini,
  /// then the ML Kit heuristic parser. A failure at any tier transparently
  /// drops to the next so the user always gets *something* back.
  Future<ScanOutcome> scanFile(File file) async {
    String? lastError;

    // Tier 1: Apple Foundation Models (iOS 26+, Apple Silicon devices).
    if (await _apple.isAvailable()) {
      try {
        final result = await _apple.scanFile(file);
        return ScanOutcome(
          result: result,
          engine: ScanEngine.appleIntelligence,
        );
      } catch (e, st) {
        debugPrint('Apple Intelligence scan failed, trying next tier: $e\n$st');
        lastError = e.toString();
      }
    }

    // Tier 2: Gemini cloud, when a key is configured.
    final key = await _resolveKey();
    if (key != null) {
      try {
        _gemini ??= GeminiReceiptScanner(apiKey: key);
        final result = await _gemini!.scanFile(file);
        return ScanOutcome(
          result: result,
          engine: ScanEngine.gemini,
          fallbackReason: lastError,
        );
      } catch (e, st) {
        debugPrint('Gemini scan failed, falling back to on-device: $e\n$st');
        lastError = e.toString();
      }
    }

    // Tier 3: ML Kit + heuristic parser. Always available.
    final result = await _scanOnDevice(file);
    return ScanOutcome(
      result: result,
      engine: ScanEngine.onDevice,
      fallbackReason: lastError,
    );
  }

  Future<ScanResult> _scanOnDevice(File file) async {
    final input = InputImage.fromFile(file);
    final recognized = await _recognizer.processImage(input);
    return parseRecognizedText(recognized.text);
  }

  /// Releases the underlying recognizers / HTTP client. Call from a service
  /// owner's `dispose` once we're done scanning for the session.
  Future<void> dispose() async {
    _gemini?.dispose();
    await _recognizer.close();
  }

  /// Visible for testing — applies our heuristics to a raw OCR string.
  static ScanResult parseRecognizedText(String text) =>
      _ReceiptParser(text).parse();
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

/// Heuristic receipt parser. Receipts vary wildly so we err on the side of
/// "import what we're confident about, leave the rest to the human review
/// step". The general approach:
///
/// 1. Split OCR text into trimmed lines.
/// 2. Find a trailing money token (e.g. "12.50", "$12.50", "12,50") on each
///    line. Lines without one are descriptions / noise.
/// 3. If the leading portion of the line matches a known totals keyword
///    (subtotal, tax, tip, total, …) we route the value into [ScannedTotals]
///    and skip the line as an item.
/// 4. Otherwise, treat the line as `name + price` and append to items.
/// 5. Recognise an inline `Nx` quantity prefix (e.g. "2 x Burger 24.00") so
///    the right `Item.quantity` lands on the bill.
class _ReceiptParser {
  _ReceiptParser(this.raw);
  final String raw;

  // Money-at-end-of-line. Accepts $/€/£/₹ prefixes, comma or dot as decimal
  // separator, optional thousands separator, and a trailing minus sign for
  // refunds (we just take the magnitude).
  static final _trailingMoney = RegExp(
    r'([\$€£¥₹]?\s*-?\s*\d{1,3}(?:[ ,\u00A0]\d{3})*[\.,]\d{2})\s*-?\s*$',
  );

  // Leading "2 x", "x2", or "(2)" quantity hints.
  static final _qtyPrefix = RegExp(r'^\s*(\d{1,2})\s*[x×@]\s*', caseSensitive: false);
  static final _qtySuffix = RegExp(r'\s*[x×]\s*(\d{1,2})\s*$', caseSensitive: false);

  static const _subtotalWords = ['subtotal', 'sub total', 'sub-total', 'sub:'];
  static const _taxWords = ['tax', 'gst', 'hst', 'vat', 'sales tax'];
  static const _tipWords = ['tip', 'gratuity', 'service charge', 'service'];
  static const _totalWords = ['grand total', 'total due', 'amount due', 'total'];
  static const _skipWords = [
    'change',
    'cash',
    'card',
    'visa',
    'mastercard',
    'amex',
    'tendered',
    'balance',
    'payment',
    'auth',
    'approval',
    'thank you',
    'thanks',
    'merci',
    'have a',
    'come again',
    'discount',
    'coupon',
    'savings',
  ];

  ScanResult parse() {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final items = <ScannedItem>[];
    final totals = ScannedTotals();

    for (final line in lines) {
      final match = _trailingMoney.firstMatch(line);
      if (match == null) continue;

      final priceText = match.group(1)!;
      final priceCents = _moneyToCents(priceText);
      if (priceCents == null || priceCents <= 0) continue;

      // The label is everything before the matched price, stripped of
      // dotted-leader runs ("Burger ........... 12.50").
      var label = line
          .substring(0, match.start)
          .replaceAll(RegExp(r'[\.…·]{2,}'), ' ')
          .trim();
      if (label.isEmpty) continue;

      final lower = label.toLowerCase();

      // Pull out quantity hints like "2 x Burger" or "Burger x2".
      var quantity = 1;
      final pre = _qtyPrefix.firstMatch(label);
      if (pre != null) {
        quantity = int.tryParse(pre.group(1)!) ?? 1;
        label = label.substring(pre.end).trim();
      } else {
        final suf = _qtySuffix.firstMatch(label);
        if (suf != null) {
          quantity = int.tryParse(suf.group(1)!) ?? 1;
          label = label.substring(0, suf.start).trim();
        }
      }

      if (_matchesAny(lower, _skipWords)) continue;
      if (_matchesAny(lower, _subtotalWords)) {
        totals.subtotalCents ??= priceCents;
        continue;
      }
      if (_matchesAny(lower, _taxWords)) {
        totals.taxCents = (totals.taxCents ?? 0) + priceCents;
        continue;
      }
      if (_matchesAny(lower, _tipWords)) {
        totals.tipCents = (totals.tipCents ?? 0) + priceCents;
        continue;
      }
      if (_matchesAny(lower, _totalWords)) {
        // Take the largest "total"-looking line as the grand total.
        if (totals.totalCents == null || priceCents > totals.totalCents!) {
          totals.totalCents = priceCents;
        }
        continue;
      }

      if (label.isEmpty) continue;
      items.add(ScannedItem(
        name: _titleize(label),
        priceCents: priceCents,
        quantity: quantity.clamp(1, 99),
      ));
    }

    // Fallback: if no subtotal was found but we did extract items, use their
    // sum so the UI can still pre-fill the subtotal field.
    if (totals.subtotalCents == null && items.isNotEmpty) {
      totals.subtotalCents =
          items.fold<int>(0, (acc, it) => acc + it.priceCents * it.quantity);
    }

    final merchant = _guessMerchant(lines);
    return ScanResult(items: items, totals: totals, merchant: merchant);
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }

  static int? _moneyToCents(String s) {
    var cleaned = s
        .replaceAll(RegExp(r'[\$€£¥₹\s\u00A0]'), '')
        .replaceAll('-', '');
    // If the number uses comma-as-decimal ("12,50") swap to dot. Receipts
    // never mix both for a single value, so this heuristic is safe.
    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');
    if (lastComma > lastDot) {
      cleaned = cleaned.replaceAll('.', '').replaceFirst(',', '.');
    } else {
      cleaned = cleaned.replaceAll(',', '');
    }
    final v = double.tryParse(cleaned);
    if (v == null) return null;
    return (v * 100).round();
  }

  static String _titleize(String s) {
    final cleaned = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return cleaned;
    // Receipts are usually ALL CAPS; convert to Title Case for readability.
    if (cleaned == cleaned.toUpperCase()) {
      return cleaned
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return cleaned;
  }

  /// First non-numeric, reasonably long line at the top of the receipt is
  /// almost always the store/restaurant name.
  static String? _guessMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (_trailingMoney.hasMatch(line)) continue;
      final clean = line.trim();
      if (clean.length < 3 || clean.length > 40) continue;
      if (RegExp(r'^[\d\W_]+$').hasMatch(clean)) continue;
      return _titleize(clean);
    }
    return null;
  }
}
