import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'ocr_service.dart';

class DocumentService {
  final OcrService _ocr = OcrService();
  static const _fileChannel = MethodChannel('com.zentex.charted/files');

  Future<String> recognizeText(File image) => _ocr.recognize(image);

  Future<String> createPdf(String text) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Charted document'),
          pw.Paragraph(text: text.trim().isEmpty ? 'No text detected.' : text),
        ],
      ),
    );
    final bytes = await document.save();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'charted-$timestamp.pdf';
    final directory = await getApplicationDocumentsDirectory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (Platform.isAndroid) {
      try {
        await _fileChannel.invokeMethod('saveToDownloads', {
          'bytes': Uint8List.fromList(bytes),
          'fileName': fileName,
        });
      } catch (_) {}
    }

    return file.path;
  }
}
