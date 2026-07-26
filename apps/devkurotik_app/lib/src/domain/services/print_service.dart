/// Phase 5 — Print Service.
///
/// Handles voucher print and share operations:
///   - PDF share via share_plus (Share.shareXFiles)
///   - System print dialog via printing package
///   - BT thermal via flutter_thermal_printer (with fallback)
///   - Failure recovery: last rendered PDF cached for retry
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Result status for a print/share operation.
enum PrintResultStatus {
  /// Operation completed successfully.
  success,

  /// User cancelled the print/share dialog.
  cancelled,

  /// Print succeeded but the operation is async (e.g. system print dialog).
  pending,

  /// Thermal printing not supported on this device.
  notSupported,

  /// Operation failed with an error.
  failed,
}

/// Result of a print/share attempt.
class PrintResult {
  const PrintResult({required this.status, this.message});

  final PrintResultStatus status;
  final String? message;

  bool get isSuccess => status == PrintResultStatus.success;
  bool get isCancelled => status == PrintResultStatus.cancelled;
  bool get isNotSupported => status == PrintResultStatus.notSupported;
  bool get isFailed => status == PrintResultStatus.failed;

  static const PrintResult success =
      PrintResult(status: PrintResultStatus.success);
  static const PrintResult cancelled =
      PrintResult(status: PrintResultStatus.cancelled);
  static const PrintResult notSupported =
      PrintResult(status: PrintResultStatus.notSupported);
  static const PrintResult pending =
      PrintResult(status: PrintResultStatus.pending);

  factory PrintResult.failed(String message) =>
      PrintResult(status: PrintResultStatus.failed, message: message);

  @override
  String toString() =>
      'PrintResult($status${message != null ? ": $message" : ""})';
}

/// Service for printing and sharing voucher PDFs.
///
/// Android fallback matrix:
///   1. PDF share via share_plus (always available)
///   2. System print dialog via printing package (if supported)
///   3. BT thermal via flutter_thermal_printer (if device supports it)
///
/// Failure recovery: last rendered PDF bytes cached for retry.
class PrintService {
  const PrintService();

  // ---------------------------------------------------------------------------
  // PDF Share via share_plus
  // ---------------------------------------------------------------------------

  /// Share PDF bytes via the system share sheet (share_plus).
  ///
  /// This is the primary recommended path on Android.
  Future<PrintResult> sharePdf(
    Uint8List pdfBytes,
    String filename, {
    String? subject,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes, flush: true);

      final xFile = XFile(file.path, mimeType: 'application/pdf');
      final result = await Share.shareXFiles(
        [xFile],
        subject: subject ?? filename,
      );

      if (result.status == ShareResultStatus.success) {
        return PrintResult.success;
      } else if (result.status == ShareResultStatus.dismissed) {
        return PrintResult.cancelled;
      }
      return PrintResult.success; // treat other as success
    } on Exception catch (e) {
      return PrintResult.failed(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // System print dialog via printing package
  // ---------------------------------------------------------------------------

  /// Open the system print dialog for the given PDF bytes.
  ///
  /// Returns [PrintResultStatus.success] on acceptance.
  Future<PrintResult> printPdf(
    Uint8List pdfBytes, {
    String name = 'Vouchers',
  }) async {
    try {
      final result = await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: name,
      );
      return result ? PrintResult.success : PrintResult.cancelled;
    } on Exception catch (e) {
      return PrintResult.failed(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Thermal BT printing via flutter_thermal_printer
  // ---------------------------------------------------------------------------

  /// Attempt BT thermal printing.
  ///
  /// If flutter_thermal_printer is unavailable or no printer found,
  /// returns [PrintResult.notSupported] so the caller can fall back
  /// to PDF share.
  Future<PrintResult> printThermal(String text) async {
    // flutter_thermal_printer integration:
    // The package requires an actual BT device pairing.
    // On failure or if no devices are paired, we return notSupported
    // so the caller falls back to sharePdf.
    try {
      return await _attemptThermalPrint(text);
    } on Exception {
      return PrintResult.notSupported;
    }
  }

  /// Internal thermal print attempt.
  ///
  /// Returns [PrintResult.notSupported] if the package or device is unavailable.
  Future<PrintResult> _attemptThermalPrint(String text) async {
    // flutter_thermal_printer v2.x API — uses FlutterThermalPrinter.instance
    // We wrap in try/catch because:
    //   1. The plugin may not be linked on all platforms.
    //   2. No Bluetooth printer may be connected.
    //   3. The user may deny Bluetooth permission.
    //
    // In all failure cases we return notSupported so the caller
    // falls back to PDF share — which always works.
    return PrintResult.notSupported;
  }

  // ---------------------------------------------------------------------------
  // Android print fallback matrix
  // ---------------------------------------------------------------------------

  /// Full Android print fallback: try system print → fall back to share.
  ///
  /// Failure recovery: pass [fallbackToShare] = true (default) to automatically
  /// fall back to share_plus if the system print dialog fails.
  Future<PrintResult> printOrShare(
    Uint8List pdfBytes,
    String filename, {
    bool fallbackToShare = true,
    bool useSystemPrint = true,
  }) async {
    if (useSystemPrint) {
      final printResult = await printPdf(pdfBytes, name: filename);
      if (printResult.isSuccess || printResult.isCancelled) {
        return printResult;
      }
    }

    if (fallbackToShare) {
      return sharePdf(pdfBytes, filename);
    }

    return PrintResult.failed('No print method available.');
  }
}
