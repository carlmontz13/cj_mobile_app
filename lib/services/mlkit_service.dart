import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromImageFiles(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return '';
    
    final buffer = StringBuffer();
    
    try {
      for (final image in imageFiles) {
        if (!await image.exists()) {
          print('MLKit: Image file does not exist: ${image.path}');
          continue;
        }
        
        try {
          final inputImage = InputImage.fromFile(image);
          final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
          final text = recognizedText.text.trim();
          if (text.isNotEmpty) {
            buffer.writeln(text);
            buffer.writeln();
          }
        } catch (e) {
          print('MLKit: Error processing image ${image.path}: $e');
          // Continue with other images
        }
      }
    } catch (e) {
      print('MLKit: General error during text extraction: $e');
      return '';
    }
    
    return buffer.toString().trim();
  }

  void dispose() {
    try {
      _textRecognizer.close();
    } catch (e) {
      print('MLKit: Error disposing text recognizer: $e');
    }
  }
}


