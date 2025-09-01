import 'dart:convert';
import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<({int grade, String feedback})> gradeSubmission({
    required String assignmentTitle,
    required String assignmentInstructions,
    required int totalPoints,
    required String submissionText,
  }) async {

   final modelFlash = GenerativeModel(
                        model: 'gemini-1.5-flash',
                        apiKey: apiKey,
                        generationConfig: GenerationConfig(temperature: 0.2),
                    );
    // Default model for grading
    final model = modelFlash;

    // Truncate the submission text to avoid hitting request limits
    const int maxChars = 8000; // small, safe upper bound
    final String truncatedSubmission = _truncate(submissionText, maxChars);

    final prompt = _buildPrompt(
      assignmentTitle: assignmentTitle,
      assignmentInstructions: assignmentInstructions,
      totalPoints: totalPoints,
      submissionText: truncatedSubmission,
    );

    // Small retry with exponential backoff for transient 429s/timeouts
    const int maxAttempts = 3;
    Duration delay = const Duration(seconds: 1);
    Object? lastError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();
        if (text == null || text.isEmpty) {
          throw Exception('Empty response from Gemini');
        }

        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start == -1 || end == -1 || end <= start) {
          throw Exception('Unexpected AI response format');
        }
        final jsonStr = text.substring(start, end + 1);
        final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;

        // Support either the simple schema or rubric schema if the prompt is updated elsewhere
        if (data.containsKey('grade') && data.containsKey('feedback')) {
          final grade = (data['grade'] as num).round();
          final feedback = (data['feedback'] as String).trim();
          return (grade: grade, feedback: feedback);
        }

        // Fallback: derive a single grade if only rubric-style scores are present
        if (data.containsKey('scores')) {
          final scores = (data['scores'] as Map).values
              .map((e) => (e as num).toDouble())
              .toList();
          final avg = scores.isNotEmpty
              ? scores.reduce((a, b) => a + b) / scores.length
              : 0.0;
          final scaledGrade = (avg * totalPoints / 100).round().clamp(0, totalPoints);
          final feedback = (data['observations']?.toString() ?? '');
          return (grade: scaledGrade, feedback: feedback);
        }

        throw Exception('AI response missing expected fields');
      } catch (e) {
        lastError = e;
        if (attempt == maxAttempts) break;
        // Simple backoff
        await Future.delayed(delay);
        delay *= 2;
      }
    }

    throw Exception('Gemini request failed after retries: $lastError');
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }

  String _buildPrompt({
    required String assignmentTitle,
    required String assignmentInstructions,
    required int totalPoints,
    required String submissionText,
  }) {
    return '''TASK: Evaluate a student's flowchart based on the given criteria.

                    STUDENT ACTIVITY: $assignmentTitle
                    
                    GRADING RUBRIC: $totalPoints
                    
                    STUDENT WORK (text extracted from flowchart image): $submissionText
                    
                    INSTRUCTIONS: Analyze the student's flowchart and provide scores based on the rubric criteria. Even if the extracted text is unclear or minimal, provide a constructive evaluation and reasonable scores.
                    
                    REQUIRED OUTPUT FORMAT (JSON only, no other text):
                    {
                      "scores": {
                            "Clarity": <integer 0-100>,
                            "Completeness": <integer 0-100>,
                            "Logical Flow": <integer 0-100>
                        },
                      "observations": "Brief evaluation focusing on strengths and areas for improvement based on the available information."
                    }
    ''';
    }

  Future<Map<String, String>> generateMaterialContent({
    required String topic,
    required String languageCode,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
    );

    final prompt = '''Generate three versions of this content at different reading levels in $languageCode.
              Format your response EXACTLY like this with these exact section headers:  

              SIMPLIFIED:
              [Write a basic version using simple words and short sentences in $languageCode]

              STANDARD:
              [Write an intermediate version with normal vocabulary in $languageCode]

              ADVANCED:
              [Write an advanced version using technical terms and complex sentences in $languageCode]

              Content to transform: $topic
              ''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini');
    }
    // Primary: strict JSON slice and parse
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      final jsonStr = text.substring(start, end + 1);
      try {
        final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
        return {
          'simplified': (data['simplified'] ?? '').toString(),
          'standard': (data['standard'] ?? '').toString(),
          'advanced': (data['advanced'] ?? '').toString(),
        };
      } catch (_) {
        // Fall through to heuristic parser
      }
    }
    // Fallback: heuristic extraction by headers
    final simplified = _extractSection(text, 'SIMPLIFIED', 'STANDARD');
    final standard = _extractSection(text, 'STANDARD', 'ADVANCED');
    final advanced = _extractSection(text, 'ADVANCED', null);
    if (simplified.isEmpty && standard.isEmpty && advanced.isEmpty) {
      throw Exception('Unexpected AI response format');
    }
    return {
      'simplified': simplified,
      'standard': standard,
      'advanced': advanced,
    };
  }

  String _extractSection(String input, String startHeader, String? endHeader) {
    try {
      final startRegex = RegExp('^\\s*' + RegExp.escape(startHeader) + '\\s*:?\\s*\$', multiLine: true);
      final startMatch = startRegex.firstMatch(input);
      if (startMatch == null) return '';
      final startIndex = startMatch.end;
      final tail = input.substring(startIndex);
      final endIndex = endHeader == null
          ? tail.length
          : (RegExp('^\\s*' + RegExp.escape(endHeader) + '\\s*:?\\s*\$', multiLine: true)
                  .firstMatch(tail)
                  ?.start ?? tail.length);
      final section = tail.substring(0, endIndex).trim();
      return section;
    } catch (_) {
      return '';
    }
  }
}


