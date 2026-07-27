import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/analysis_result.dart';
import '../models/analysis_status.dart';
import '../models/profile_data.dart';

/// Service for generating PDF reports from analysis results.
class PdfReportService {
  /// Generates a PDF report from the analysis result.
  ///
  /// Returns the PDF as bytes that can be uploaded or downloaded.
  static Future<Uint8List> generateReport({
    required AnalysisResult result,
    required ProfileData profile,
    required bool isEnglish,
  }) async {
    final pdf = pw.Document();

    // Colors based on status
    final statusColor = _getStatusColor(result.status);
    final statusText = _getStatusText(result.status, isEnglish);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isEnglish),
              pw.SizedBox(height: 20),

              // Patient info
              if (profile.babyName != null) ...[
                _buildSection(
                  title: isEnglish ? 'Patient Information' : 'Información del Paciente',
                  content: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(isEnglish ? 'Baby Name' : 'Nombre del bebé', profile.babyName!),
                      if (profile.ageInMonths != null)
                        _buildInfoRow(isEnglish ? 'Age' : 'Edad', '${profile.ageInMonths} ${isEnglish ? 'months' : 'meses'}'),
                      if (profile.currentWeightKg != null)
                        _buildInfoRow(isEnglish ? 'Weight' : 'Peso', '${profile.currentWeightKg} kg'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // Status indicator
              _buildStatusBadge(statusText, statusColor),
              pw.SizedBox(height: 20),

              // Observations
              _buildSection(
                title: isEnglish ? 'Observations' : 'Observaciones',
                content: pw.Text(
                  result.observations,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                ),
              ),
              pw.SizedBox(height: 16),

              // Recommendations
              _buildSection(
                title: isEnglish ? 'Recommendations' : 'Recomendaciones',
                content: pw.Text(
                  result.recommendations,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                ),
              ),

              // Cry analysis if available
              if (result.hasCryAnalysis) ...[
                pw.SizedBox(height: 16),
                _buildSection(
                  title: isEnglish ? 'Cry Analysis' : 'Análisis de Llanto',
                  content: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${isEnglish ? 'Category' : 'Categoría'}: ${result.cryDisplayLabel ?? result.cryCategory}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      if (result.cryConfidence != null)
                        pw.Text(
                          '${isEnglish ? 'Confidence' : 'Confianza'}: ${(result.cryConfidence! * 100).toInt()}%',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      if (result.cryRecommendation != null) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          result.cryRecommendation!,
                          style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Disclaimer
              _buildDisclaimer(isEnglish),

              // Footer with date
              pw.SizedBox(height: 16),
              _buildFooter(isEnglish),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(bool isEnglish) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#389BB0'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BabyHealth',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                isEnglish ? 'AI Analysis Report' : 'Reporte de Análisis IA',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              isEnglish ? 'Preliminary Guidance' : 'Orientación Preliminar',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#389BB0'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection({
    required String title,
    required pw.Widget content,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#2B2826'),
            ),
          ),
          pw.SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusBadge(String text, PdfColor color) {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(30),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildDisclaimer(bool isEnglish) {
    final text = isEnglish
        ? 'IMPORTANT: This report provides AI-based preliminary guidance and does NOT replace evaluation by a health professional. Consult a pediatrician with any concern about your baby\'s health.'
        : 'IMPORTANTE: Este reporte proporciona orientación preliminar basada en IA y NO reemplaza la evaluación de un profesional de la salud. Consulte a un pediatra ante cualquier preocupación sobre la salud de su bebé.';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF3CD'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#FFCA28')),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildFooter(bool isEnglish) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '${isEnglish ? 'Generated' : 'Generado'}: $dateStr',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          'BabyHealth - babyhealth.hmartinez.info',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static PdfColor _getStatusColor(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.normal:
        return PdfColor.fromHex('#4CAF50'); // Green
      case AnalysisStatus.requiereAtencion:
        return PdfColor.fromHex('#FF9800'); // Orange
      case AnalysisStatus.urgente:
        return PdfColor.fromHex('#F44336'); // Red
    }
  }

  static String _getStatusText(AnalysisStatus status, bool isEnglish) {
    switch (status) {
      case AnalysisStatus.normal:
        return isEnglish ? 'NORMAL' : 'NORMAL';
      case AnalysisStatus.requiereAtencion:
        return isEnglish ? 'NEEDS ATTENTION' : 'REQUIERE ATENCIÓN';
      case AnalysisStatus.urgente:
        return isEnglish ? 'URGENT' : 'URGENTE';
    }
  }
}
