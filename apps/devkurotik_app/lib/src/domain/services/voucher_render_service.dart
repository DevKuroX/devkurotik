/// Phase 5 — Voucher Render Service.
///
/// Generates PDF bytes from voucher items using the pdf package.
/// QR codes are generated locally using qr_flutter — no external APIs called.
// ignore_for_file: prefer_const_constructors
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../models/voucher_models.dart';

/// Result of a PDF render operation.
class VoucherPdfResult {
  const VoucherPdfResult({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Service for rendering voucher PDF documents.
///
/// Uses the `pdf` package for PDF generation.
/// QR codes use `qr_flutter` locally — credentials are never sent externally.
class VoucherRenderService {
  const VoucherRenderService();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Render a single voucher item to PDF bytes.
  Future<VoucherPdfResult> renderSingleVoucher({
    required VoucherItem voucher,
    required String routerName,
    required String profileName,
    required String routerHost,
    String? validity,
    VoucherTemplate template = VoucherTemplate.default220,
    bool includeQr = true,
  }) async {
    final doc = pw.Document();
    final qrImage = includeQr ? await _buildQrImage(voucher, routerHost) : null;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          template.widthMm * PdfPageFormat.mm,
          _heightMm(template) * PdfPageFormat.mm,
        ),
        margin: const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
        build: (pw.Context ctx) => _buildVoucherWidget(
          voucher: voucher,
          routerName: routerName,
          profileName: profileName,
          validity: validity,
          template: template,
          qrImage: qrImage,
          now: DateTime.now(),
        ),
      ),
    );

    final bytes = await doc.save();
    return VoucherPdfResult(
      bytes: bytes,
      filename: 'voucher_${voucher.name}.pdf',
    );
  }

  /// Render a batch of vouchers to a single PDF.
  Future<VoucherPdfResult> renderBatch({
    required VoucherBatch batch,
    required String routerName,
    required String routerHost,
    String? validity,
    VoucherTemplate template = VoucherTemplate.default220,
    bool includeQr = true,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    // Build QR images for all vouchers if needed.
    final qrImages = <VoucherItem, pw.MemoryImage?>{};
    if (includeQr) {
      for (final v in batch.vouchers) {
        qrImages[v] = await _buildQrImage(v, routerHost);
      }
    }

    // Vouchers per row — 2 for default/thermal, 1 for small.
    final perRow = template == VoucherTemplate.small160 ? 1 : 2;
    final pageWidth = _pageWidthMm(template, perRow);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          pageWidth * PdfPageFormat.mm,
          297 * PdfPageFormat.mm,
        ),
        margin: const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
        build: (pw.Context ctx) {
          final rows = <pw.Widget>[];
          for (var i = 0; i < batch.vouchers.length; i += perRow) {
            final rowItems = batch.vouchers.skip(i).take(perRow).toList();
            rows.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: rowItems
                    .map(
                      (v) => pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(1 * PdfPageFormat.mm),
                          child: _buildVoucherWidget(
                            voucher: v,
                            routerName: routerName,
                            profileName: batch.profileName,
                            validity: validity,
                            template: template,
                            qrImage: qrImages[v],
                            now: now,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }
          return rows;
        },
      ),
    );

    final bytes = await doc.save();
    return VoucherPdfResult(
      bytes: bytes,
      filename: 'vouchers_${batch.batchCode}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Widget builders
  // ---------------------------------------------------------------------------

  pw.Widget _buildVoucherWidget({
    required VoucherItem voucher,
    required String routerName,
    required String profileName,
    String? validity,
    required VoucherTemplate template,
    pw.MemoryImage? qrImage,
    required DateTime now,
  }) {
    switch (template) {
      case VoucherTemplate.default220:
        return _buildDefault(
          voucher: voucher,
          routerName: routerName,
          profileName: profileName,
          validity: validity,
          qrImage: qrImage,
          now: now,
        );
      case VoucherTemplate.thermal180:
        return _buildThermal(
          voucher: voucher,
          routerName: routerName,
          profileName: profileName,
          validity: validity,
          qrImage: qrImage,
          now: now,
        );
      case VoucherTemplate.small160:
        return _buildSmall(
          voucher: voucher,
          profileName: profileName,
          validity: validity,
        );
    }
  }

  /// Default 220px layout.
  ///
  /// ┌──────────────────────────────┐
  /// │  [Router Name]  [Profile]    │
  /// │  Username: XXXXX             │
  /// │  Password: XXXXX             │
  /// │  Validity: 1H                │
  /// │  [QR Code if enabled]        │
  /// │  Generated: 2026-07-26       │
  /// └──────────────────────────────┘
  pw.Widget _buildDefault({
    required VoucherItem voucher,
    required String routerName,
    required String profileName,
    String? validity,
    pw.MemoryImage? qrImage,
    required DateTime now,
  }) {
    final dateStr = _formatDate(now);
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      padding: const pw.EdgeInsets.all(2 * PdfPageFormat.mm),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Header row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                routerName,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 7,
                ),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
              pw.Text(
                profileName,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 7,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Divider(thickness: 0.3),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          // Username
          pw.Row(
            children: [
              pw.Text('Username: ', style: pw.TextStyle(fontSize: 6.5)),
              pw.Text(
                voucher.name,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 6.5,
                ),
              ),
            ],
          ),
          // Password (only show if not voucher mode)
          if (!voucher.isVoucherMode) ...[
            pw.SizedBox(height: 0.5 * PdfPageFormat.mm),
            pw.Row(
              children: [
                pw.Text('Password: ', style: pw.TextStyle(fontSize: 6.5)),
                pw.Text(
                  voucher.password,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 6.5,
                  ),
                ),
              ],
            ),
          ],
          if (validity != null && validity.isNotEmpty) ...[
            pw.SizedBox(height: 0.5 * PdfPageFormat.mm),
            pw.Row(
              children: [
                pw.Text('Validity: ', style: pw.TextStyle(fontSize: 6)),
                pw.Text(validity, style: pw.TextStyle(fontSize: 6)),
              ],
            ),
          ],
          if (qrImage != null) ...[
            pw.SizedBox(height: 1 * PdfPageFormat.mm),
            pw.Center(
              child: pw.Image(qrImage, width: 20 * PdfPageFormat.mm),
            ),
          ],
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Text(
            'Generated: $dateStr',
            style: pw.TextStyle(fontSize: 5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Thermal 180px layout (compact with timestamp).
  pw.Widget _buildThermal({
    required VoucherItem voucher,
    required String routerName,
    required String profileName,
    String? validity,
    pw.MemoryImage? qrImage,
    required DateTime now,
  }) {
    final dateStr = _formatDateTime(now);
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.3),
      ),
      padding: const pw.EdgeInsets.all(1.5 * PdfPageFormat.mm),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$routerName | $profileName',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
            maxLines: 1,
          ),
          pw.Divider(thickness: 0.3),
          pw.Text(
            'User: ${voucher.name}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
          ),
          if (!voucher.isVoucherMode)
            pw.Text(
              'Pass: ${voucher.password}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
            ),
          pw.Text(
            '${validity != null ? "Valid: $validity  " : ""}$dateStr',
            style: pw.TextStyle(fontSize: 5),
          ),
          if (qrImage != null)
            pw.Center(
              child: pw.Image(qrImage, width: 15 * PdfPageFormat.mm),
            ),
        ],
      ),
    );
  }

  /// Small 160px ultra-compact layout.
  pw.Widget _buildSmall({
    required VoucherItem voucher,
    required String profileName,
    String? validity,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.3),
      ),
      padding: const pw.EdgeInsets.all(1 * PdfPageFormat.mm),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            profileName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5.5),
          ),
          pw.Text(
            'User:${voucher.name} Pass:${voucher.password}',
            style: pw.TextStyle(fontSize: 5.5),
          ),
          if (validity != null && validity.isNotEmpty)
            pw.Text(validity, style: pw.TextStyle(fontSize: 5)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QR generation (local only — qr_flutter)
  // ---------------------------------------------------------------------------

  /// Build a QR image for a voucher.
  ///
  /// Encodes the login URL: http://[routerHost]/login?user=X&password=Y
  /// This is done locally — no external APIs are called.
  Future<pw.MemoryImage?> _buildQrImage(
    VoucherItem voucher,
    String routerHost,
  ) async {
    try {
      final url =
          'http://$routerHost/login?user=${Uri.encodeComponent(voucher.name)}'
          '&password=${Uri.encodeComponent(voucher.password)}';

      final qrValidationResult = QrValidator.validate(
        data: url,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        return null;
      }

      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        // ignore: deprecated_member_use
        color: const ui.Color(0xFF000000),
        // ignore: deprecated_member_use
        emptyColor: const ui.Color(0xFFFFFFFF),
        gapless: true,
      );

      const size = 200.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, Size(size, size));
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return pw.MemoryImage(byteData.buffer.asUint8List());
    } on Exception {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _heightMm(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.default220:
        return 55.0;
      case VoucherTemplate.thermal180:
        return 40.0;
      case VoucherTemplate.small160:
        return 25.0;
    }
  }

  double _pageWidthMm(VoucherTemplate template, int perRow) {
    return template.widthMm * perRow + (perRow - 1) * 2 + 6;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
