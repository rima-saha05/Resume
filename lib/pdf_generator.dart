import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFGenerator {
  static Future<void> generateAndDownloadResume(String resumeContent) async {
    try {
      final pdf = pw.Document();

      // Split content into lines for better formatting
      final lines = resumeContent.split('\n');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _buildResumeContent(lines),
            );
          },
        ),
      );

      // Save to file
      final output = await getApplicationDocumentsDirectory();
      final file = File(
        '${output.path}/Resume_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Open print dialog
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Resume_${DateTime.now().toString().split(' ')[0]}.pdf',
      );

      print('✅ PDF saved to: ${file.path}');
    } catch (e) {
      print('❌ Error generating PDF: $e');
      rethrow;
    }
  }

  static List<pw.Widget> _buildResumeContent(List<String> lines) {
    final widgets = <pw.Widget>[];

    for (String line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) continue;

      // Detect main title (lines with equals)
      if (trimmedLine.contains('====')) {
        continue;
      }

      // Detect section headers (lines with dashes)
      if (trimmedLine.contains('---')) {
        continue;
      }

      // Section titles
      if (_isSectionTitle(trimmedLine)) {
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(
          pw.Text(
            trimmedLine,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // Contact info lines (with emojis or special chars)
      if (trimmedLine.startsWith('📍') ||
          trimmedLine.startsWith('📞') ||
          trimmedLine.startsWith('📧')) {
        widgets.add(
          pw.Text(_removeEmoji(trimmedLine), style: pw.TextStyle(fontSize: 10)),
        );
        continue;
      }

      // Bullet points
      if (trimmedLine.startsWith('•')) {
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(left: 12, top: 2, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontSize: 11)),
                pw.Expanded(
                  child: pw.Text(
                    trimmedLine.substring(1).trim(),
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular text lines
      if (trimmedLine.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 2, bottom: 2),
            child: pw.Text(trimmedLine, style: pw.TextStyle(fontSize: 11)),
          ),
        );
      }
    }

    return widgets;
  }

  static bool _isSectionTitle(String text) {
    final sectionKeywords = [
      'PROFESSIONAL SUMMARY',
      'EXPERIENCE',
      'EDUCATION',
      'TECHNICAL SKILLS',
      'SOFT SKILLS',
      'LANGUAGE',
    ];
    return sectionKeywords.any((keyword) => text.contains(keyword));
  }

  static String _removeEmoji(String text) {
    // Simple emoji removal by replacing common emoji characters
    String result = text;

    // Remove common emojis used in resume
    result = result.replaceAll('📍', '');
    result = result.replaceAll('📞', '');
    result = result.replaceAll('📧', '');
    result = result.replaceAll('•', '');
    result = result.replaceAll('⏳', '');
    result = result.replaceAll('✅', '');
    result = result.replaceAll('❌', '');

    // Remove any other emoji-like characters using a simpler pattern
    result = result.replaceAll(RegExp(r'[^\x20-\x7E\n\r]'), '');

    return result.trim();
  }
}
