import Flutter
import UIKit
import Vision
#if canImport(FoundationModels)
import FoundationModels
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    ReceiptIntelligenceChannel.register(with: engineBridge.pluginRegistry)
  }
}

// MARK: - Receipt intelligence (Vision OCR + Foundation Models)
//
// Bridges Apple's on-device Foundation Models LLM to the Flutter side so we can
// parse receipts without a network round-trip. Pipeline:
//
//   1. Vision (`VNRecognizeTextRequest`) extracts text + word boxes from the
//      photo at `imagePath`. Available since iOS 13, so it doubles as a
//      higher-quality OCR fallback when Foundation Models isn't.
//   2. The lines are sorted into reading order and handed to a
//      `LanguageModelSession` with a `@Generable` `ParsedReceipt` schema. The
//      framework enforces the typed output for us — no JSON repair, no regex.
//   3. We re-emit the parsed receipt as JSON the Dart side already knows how
//      to decode (mirrors the Gemini scanner's shape).
//
// Everything LLM-related is gated on iOS 26 (Foundation Models is new there)
// and a `canImport` check so the project still builds on older Xcode SDKs.
enum ReceiptIntelligenceChannel {
  static let channelName = "divido/receipt_intelligence"
  static let pluginName = "ReceiptIntelligence"

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: pluginName) else { return }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        result(isFoundationModelsAvailable())
      case "scanReceipt":
        guard let args = call.arguments as? [String: Any],
              let path = args["imagePath"] as? String else {
          result(FlutterError(
            code: "bad_args",
            message: "scanReceipt requires {imagePath: String}",
            details: nil
          ))
          return
        }
        Task {
          do {
            let json = try await scanReceipt(imagePath: path)
            result(json)
          } catch let err as ReceiptScanError {
            result(FlutterError(code: err.code, message: err.message, details: nil))
          } catch {
            result(FlutterError(
              code: "scan_failed",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// `true` only when the device can actually run Foundation Models *now* —
  /// we deliberately conflate "OS too old", "device not eligible", "Apple
  /// Intelligence disabled", and "model still downloading" so the Dart side
  /// just has to make a single yes/no decision before each scan.
  static func isFoundationModelsAvailable() -> Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      switch SystemLanguageModel.default.availability {
      case .available:
        return true
      default:
        return false
      }
    }
    #endif
    return false
  }

  /// Runs OCR + structured parsing and returns a JSON string shaped like:
  ///   {"merchant": String?, "currency": String?,
  ///    "items": [{"name": String, "quantity": Int, "priceCents": Int}],
  ///    "subtotalCents"|"taxCents"|"tipCents"|"totalCents": Int?}
  /// Throws `ReceiptScanError` for any failure the Dart side should handle.
  static func scanReceipt(imagePath: String) async throws -> String {
    let cgImage = try loadCGImage(from: imagePath)
    let ocrText = try recognizeText(in: cgImage)

    if ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw ReceiptScanError(code: "empty_ocr", message: "No text detected in image")
    }

    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      let parsed = try await parseWithFoundationModels(ocrText: ocrText)
      return try encodeJSON(parsed)
    }
    #endif
    throw ReceiptScanError(
      code: "unavailable",
      message: "Foundation Models not available on this device"
    )
  }

  // MARK: Vision OCR

  /// Loads any UIKit-readable image (jpeg/png/heic) into a `CGImage`. We
  /// accept either `file://` URIs or raw filesystem paths because Flutter's
  /// `image_picker` returns the latter on iOS.
  private static func loadCGImage(from path: String) throws -> CGImage {
    let url: URL = path.hasPrefix("file://")
      ? URL(string: path)!
      : URL(fileURLWithPath: path)
    guard let data = try? Data(contentsOf: url),
          let uiImage = UIImage(data: data),
          let cgImage = uiImage.cgImage else {
      throw ReceiptScanError(code: "bad_image", message: "Could not load image at \(path)")
    }
    return cgImage
  }

  /// Returns the recognised text in approximate reading order (top-to-bottom,
  /// left-to-right). We disable language correction because price tokens like
  /// `12.50` and `$3.49` get mangled by the autocorrect heuristics.
  private static func recognizeText(in image: CGImage) throws -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([request])

    let observations = request.results ?? []
    // Vision uses a bottom-left normalized coordinate system, so a higher Y
    // means closer to the top. Bucket observations into rough rows by Y, then
    // sort each row left-to-right, so a two-column "ITEM ............ 12.50"
    // layout doesn't get scrambled.
    let withTexts: [(VNRecognizedTextObservation, String)] = observations.compactMap { obs in
      guard let text = obs.topCandidates(1).first?.string, !text.isEmpty else { return nil }
      return (obs, text)
    }
    let sorted = withTexts.sorted { lhs, rhs in
      let dy = lhs.0.boundingBox.midY - rhs.0.boundingBox.midY
      if abs(dy) > 0.012 { return dy > 0 }
      return lhs.0.boundingBox.minX < rhs.0.boundingBox.minX
    }
    return sorted.map { $0.1 }.joined(separator: "\n")
  }

  // MARK: Foundation Models

  /// Encodes whatever `parseWithFoundationModels` returns. Kept generic so the
  /// `@available` shape doesn't leak into the rest of the file.
  private static func encodeJSON<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    let data = try encoder.encode(value)
    return String(data: data, encoding: .utf8) ?? "{}"
  }
}

// MARK: - Generable schema (iOS 26+)

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct ParsedItem: Codable {
  @Guide(description: "The item or dish name as printed on the receipt")
  let name: String

  @Guide(description: "Quantity sold; default to 1 when no '2 x' / 'x3' marker is present")
  let quantity: Int

  @Guide(description: "Per-unit price in integer cents (printed amount × 100). Never the line total.")
  let priceCents: Int
}

@available(iOS 26.0, *)
@Generable
struct ParsedReceipt: Codable {
  @Guide(description: "Store or restaurant name printed at the top of the receipt; null if unclear")
  let merchant: String?

  @Guide(description: "ISO-4217 currency code (USD, EUR, GBP, INR…) when visible; null otherwise")
  let currency: String?

  @Guide(description: "Each purchased line item. Exclude payment, change, loyalty, discount, tax and tip lines.")
  let items: [ParsedItem]

  @Guide(description: "Pre-tax subtotal in integer cents; null if not printed")
  let subtotalCents: Int?

  @Guide(description: "Sum of every tax-like line (sales tax, GST, VAT, HST) in integer cents; null if none")
  let taxCents: Int?

  @Guide(description: "Tip, gratuity, or service charge in integer cents; null if none")
  let tipCents: Int?

  @Guide(description: "Final printed grand total in integer cents; null if not printed")
  let totalCents: Int?
}

@available(iOS 26.0, *)
private func parseWithFoundationModels(ocrText: String) async throws -> ParsedReceipt {
  let session = LanguageModelSession(instructions: """
    You extract structured data from a single photograph of a restaurant or \
    retail receipt. The image was OCR-ed and the raw text is provided below in \
    approximate top-to-bottom, left-to-right reading order. Some characters \
    may be misread.

    Rules:
    - Convert every printed monetary amount into integer cents (multiply by \
      100 and round to the nearest integer).
    - When a line shows a quantity like "2 x Burger 24.00" or "Burger x3", \
      put the quantity in `quantity` and the per-unit price (NOT the line \
      total) in `priceCents`.
    - Skip payment, tendered, change, loyalty, discount and coupon lines.
    - `merchant` is the store / restaurant name from the top of the receipt, \
      not its address.
    - `taxCents` is the sum of every tax-like line (sales tax, GST, VAT, HST).
    - `tipCents` covers tip, gratuity, or service charge lines.
    - `subtotalCents` is the pre-tax/tip subtotal printed on the receipt; \
      leave null if it isn't shown.
    - `totalCents` is the final printed grand total; leave null if it isn't \
      shown.
    - If the receipt is unreadable, return empty `items` and null totals. \
      Never invent values that aren't on the receipt.
    """)

  let response = try await session.respond(
    to: "Receipt OCR text:\n\(ocrText)",
    generating: ParsedReceipt.self
  )
  return response.content
}
#endif

// MARK: - Errors

private struct ReceiptScanError: Error {
  let code: String
  let message: String
}
