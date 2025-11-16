import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('PdfService: $message');
    }
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Convert PDF file to text
  Future<String?> convertPdfToText(File pdfFile) async {
    try {
      _log('Converting PDF to text: ${pdfFile.path}');

      // Load the PDF document
      final PdfDocument document = PdfDocument(
        inputBytes: await pdfFile.readAsBytes(),
      );

      // Extract text from all pages
      String text = '';
      for (int i = 0; i < document.pages.count; i++) {
        text += PdfTextExtractor(
          document,
        ).extractText(startPageIndex: i, endPageIndex: i);
        text += '\n\n'; // Add spacing between pages
      }

      // Dispose the document
      document.dispose();

      _log('PDF conversion successful. Extracted ${text.length} characters');
      return text;
    } catch (e) {
      _log('Error converting PDF to text: $e');
      return null;
    }
  }

  // Save text to a file
  Future<File?> saveTextToFile(String text, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.txt');
      await file.writeAsString(text);

      _log('Text file saved: ${file.path}');
      return file;
    } catch (e) {
      _log('Error saving text file: $e');
      return null;
    }
  }

  // Get list of converted text files
  Future<List<File>> getConvertedTextFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final textFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.txt'))
          .toList();

      _log('Found ${textFiles.length} converted text files');
      return textFiles;
    } catch (e) {
      _log('Error getting text files: $e');
      return [];
    }
  }

  // Delete a text file
  Future<bool> deleteTextFile(File file) async {
    try {
      await file.delete();
      _log('Text file deleted: ${file.path}');
      return true;
    } catch (e) {
      _log('Error deleting file: $e');
      return false;
    }
  }
}
