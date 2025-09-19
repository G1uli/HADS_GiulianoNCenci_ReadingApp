import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:reading_app/services/pdf_service.dart';

class PdfConversionScreen extends StatefulWidget {
  const PdfConversionScreen({super.key});

  @override
  State<PdfConversionScreen> createState() => _PdfConversionScreenState();
}

class _PdfConversionScreenState extends State<PdfConversionScreen> {
  final PdfService _pdfService = PdfService();
  bool _isConverting = false;
  String _conversionStatus = '';
  List<File> _convertedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadConvertedFiles();
  }

  Future<void> _loadConvertedFiles() async {
    final files = await _pdfService.getConvertedTextFiles();
    if (mounted) {
      setState(() {
        _convertedFiles = files;
      });
    }
  }

  Future<void> _pickAndConvertPdf() async {
    // Request storage permission
    final hasPermission = await _pdfService.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission is required to convert PDF files',
            ),
          ),
        );
      }
      return;
    }

    // Pick PDF file using file_picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      setState(() {
        _isConverting = true;
        _conversionStatus = 'Converting PDF...';
      });

      File file = File(result.files.single.path!);
      String fileName = result.files.single.name.replaceAll('.pdf', '');

      // Convert PDF to text
      String? text = await _pdfService.convertPdfToText(file);

      if (text != null && mounted) {
        setState(() {
          _conversionStatus = 'Saving text file...';
        });

        // Save text to file
        File? textFile = await _pdfService.saveTextToFile(text, fileName);

        if (mounted) {
          setState(() {
            _isConverting = false;
          });
        }

        if (textFile != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'PDF converted successfully! Saved as ${textFile.path.split('/').last}',
                ),
              ),
            );
          }
          _loadConvertedFiles(); // Refresh file list
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save text file')),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isConverting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to convert PDF')),
          );
        }
      }
    }
  }

  Future<void> _viewTextFile(File file) async {
    final content = await file.readAsString();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(file.path.split('/').last),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: Text(content)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteTextFile(File file) async {
    final success = await _pdfService.deleteTextFile(file);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
        _loadConvertedFiles(); // Refresh file list
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF to Text Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isConverting ? null : _pickAndConvertPdf,
              child: const Text('Convert PDF to Text'),
            ),
            const SizedBox(height: 16),
            if (_isConverting)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_conversionStatus),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'Converted Files:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _convertedFiles.isEmpty
                  ? const Center(child: Text('No converted files yet'))
                  : ListView.builder(
                      itemCount: _convertedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _convertedFiles[index];
                        final fileName = file.path.split('/').last;

                        return Card(
                          child: ListTile(
                            title: Text(fileName),
                            subtitle: Text(
                              '${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _viewTextFile(file),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteTextFile(file),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
