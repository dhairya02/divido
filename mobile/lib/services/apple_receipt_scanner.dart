import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'receipt_scanner.dart';

/// Thrown when the Apple Foundation Models pipeline can't return a usable
/// receipt — typically because the device isn't Apple-Intelligence eligible
/// or because Vision OCR found no text. Callers (the [ReceiptScannerService])
/// catch this and fall back to Gemini / on-device heuristics so the user
/// still gets *something*.
class AppleScanException implements Exception {
  AppleScanException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() =>
      'AppleScanException(${code ?? '-'}): $message';
}

/// Talks to the iOS-only `divido/receipt_intelligence` method channel, which
/// runs Apple Vision OCR followed by an on-device Foundation Models pass with
/// guided generation against a typed [ParsedReceipt] schema.
///
/// All processing is on-device, free, and offline. No-op on non-iOS, on iOS
/// versions before 26, and on devices without Apple Intelligence — call
/// [isAvailable] to check before relying on it.
class AppleReceiptScanner {
  AppleReceiptScanner({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'divido/receipt_intelligence';

  final MethodChannel _channel;

  /// Memoised availability check. The native side does the real work; we just
  /// don't want to invoke a method-channel call before every single scan.
  bool? _availabilityCache;

  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    if (_availabilityCache != null) return _availabilityCache!;
    try {
      final res = await _channel.invokeMethod<bool>('isAvailable');
      _availabilityCache = res ?? false;
    } on MissingPluginException {
      // Older iOS builds shipped before this channel existed.
      _availabilityCache = false;
    } catch (e) {
      debugPrint('AppleReceiptScanner availability check failed: $e');
      _availabilityCache = false;
    }
    return _availabilityCache!;
  }

  Future<ScanResult> scanFile(File file) async {
    if (!Platform.isIOS) {
      throw AppleScanException('Only available on iOS', code: 'wrong_platform');
    }
    final String json;
    try {
      final raw = await _channel.invokeMethod<String>(
        'scanReceipt',
        <String, Object?>{'imagePath': file.path},
      );
      if (raw == null || raw.isEmpty) {
        throw AppleScanException('Empty response from native side');
      }
      json = raw;
    } on PlatformException catch (e) {
      throw AppleScanException(
        e.message ?? 'Native scan failed',
        code: e.code,
      );
    } on MissingPluginException {
      throw AppleScanException(
        'Receipt intelligence channel not registered',
        code: 'missing_plugin',
      );
    }

    final Map<String, Object?> decoded;
    try {
      decoded = jsonDecode(json) as Map<String, Object?>;
    } catch (e) {
      throw AppleScanException('Could not parse native JSON: $e');
    }
    return _toScanResult(decoded);
  }

  // ---------------------------------------------------------------------------
  // JSON → domain mapping
  //
  // Mirrors `GeminiReceiptScanner._toScanResult` so any improvement to one
  // path naturally lines up with the other (same field names on the wire).
  // ---------------------------------------------------------------------------

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

    // Same belt-and-braces as Gemini: if the model didn't give us a subtotal
    // but we did parse line items, sum them so the review sheet's footer
    // shows a sensible number.
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
}
