import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';

class PdfService {
  // Generate PDF document from a note
  Future<pw.Document> generateNotePdf(Note note) async {
    final pdf = pw.Document();
    
    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();
    
    // Format dates
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');
    final createdDate = dateFormatter.format(note.createdAt);
    final modifiedDate = dateFormatter.format(note.modifiedAt);
    
    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                note.title.isEmpty ? 'Untitled Note' : note.title,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                ),
              ),
              
              pw.SizedBox(height: 4),
              
              // Date info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Created: $createdDate',
                    style: pw.TextStyle(
                      font: italicFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Modified: $modifiedDate',
                    style: pw.TextStyle(
                      font: italicFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              
              // Tags
              if (note.tags.isNotEmpty)
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.map((tag) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        '#$tag',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              
              pw.SizedBox(height: 16),
              
              // Divider
              pw.Divider(color: PdfColors.grey400),
              
              pw.SizedBox(height: 16),
              
              // Content
              pw.Text(
                note.content,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  // Generate PDF for multiple notes
  Future<pw.Document> generateMultipleNotesPdf(List<Note> notes) async {
    final pdf = pw.Document();
    
    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();
    final lightFont = await PdfGoogleFonts.robotoLight();
    
    // Format dates
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');
    
    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Notes Collection',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 28,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Exported on ${dateFormatter.format(DateTime.now())}',
                  style: pw.TextStyle(
                    font: italicFont,
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  '${notes.length} notes',
                  style: pw.TextStyle(
                    font: lightFont,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Add table of contents
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Table of Contents',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              
              // List of notes
              ...notes.asMap().entries.map((entry) {
                final index = entry.key;
                final note = entry.value;
                final title = note.title.isEmpty ? 'Untitled Note' : note.title;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        '${index + 1}. ',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 12,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          title,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Text(
                        dateFormatter.format(note.modifiedAt),
                        style: pw.TextStyle(
                          font: italicFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
    
    // Add each note as a page
    for (final note in notes) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                  ),
                ),
                
                pw.SizedBox(height: 4),
                
                // Date info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Created: ${dateFormatter.format(note.createdAt)}',
                      style: pw.TextStyle(
                        font: italicFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Modified: ${dateFormatter.format(note.modifiedAt)}',
                      style: pw.TextStyle(
                        font: italicFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                
                // Tags
                if (note.tags.isNotEmpty)
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags.map((tag) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          '#$tag',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.grey800,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                
                pw.SizedBox(height: 12),
                
                // Divider
                pw.Divider(color: PdfColors.grey400),
                
                pw.SizedBox(height: 12),
                
                // Content
                pw.Text(
                  note.content,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    
    return pdf;
  }

  // Save PDF to file and return the file path
  Future<String> savePdfToFile(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      
      // Save PDF to file
      await file.writeAsBytes(await pdf.save());
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  // Print PDF document
  Future<void> printPdf(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }

  // Share PDF document
  Future<void> sharePdf(pw.Document pdf, String fileName) async {
    try {
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }
}
