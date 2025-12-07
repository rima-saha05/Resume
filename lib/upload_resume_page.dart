import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_generator.dart';

class UploadResumePage extends StatefulWidget {
  const UploadResumePage({super.key});

  @override
  State<UploadResumePage> createState() => _UploadResumePageState();
}

class _UploadResumePageState extends State<UploadResumePage> {
  bool _isProcessing = false;
  String? _fileName;
  String? _enhancedResume;
  String? _errorMessage;

  Future<void> _pickAndProcessFile() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _enhancedResume = null;
        _fileName = null;
      });

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final filePath = result.files.single.path!;
      _fileName = result.files.single.name;

      // Extract text from file
      String extractedText = await _extractTextFromFile(filePath);

      if (extractedText.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Could not extract text from the file. Please ensure the file contains readable text.';
        });
        return;
      }

      // Enhance resume using AI
      String enhancedResume = await _enhanceResumeWithAI(extractedText);

      setState(() {
        _isProcessing = false;
        _enhancedResume = enhancedResume;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing file: $e';
      });
    }
  }

  Future<String> _extractTextFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final extension = filePath.split('.').last.toLowerCase();

      if (extension == 'pdf') {
        // Extract text from PDF
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        String text = '';

        for (int i = 0; i < document.pages.count; i++) {
          text += PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
          text += '\n';
        }

        document.dispose();
        return text.trim();
      } else if (extension == 'txt') {
        // Read text file directly
        return await file.readAsString();
      } else if (extension == 'doc' || extension == 'docx') {
        // For DOC/DOCX files, we'll show an error message suggesting PDF
        throw Exception('DOC/DOCX files are not supported yet. Please convert to PDF or TXT format.');
      } else {
        throw Exception('Unsupported file format: $extension');
      }
    } catch (e) {
      print('Error extracting text: $e');
      rethrow;
    }
  }

  Future<String> _enhanceResumeWithAI(String originalText) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('API key not found in .env file');
    }

    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final prompt = """
You are a professional resume writer and enhancer. Analyze the following resume and create an enhanced, polished, modern, ATS-friendly version.

ORIGINAL RESUME CONTENT:
$originalText

Your task:
1. Extract all key information (name, contact, experience, education, skills, etc.)
2. Enhance the content with better wording, stronger action verbs, and professional language
3. Improve formatting and structure
4. Add missing sections if they would strengthen the resume
5. Ensure ATS (Applicant Tracking System) compatibility
6. Maintain all factual information - do NOT add false information

Your output MUST follow this exact structure:

============================
FULL NAME (Large & Bold)

📍 City, State/Country
📞 Phone Number
📧 Email Address

----------------------------
PROFESSIONAL SUMMARY
Write a compelling 3–4 line summary that highlights key strengths and experience.

----------------------------
EXPERIENCE
Job Title — Company Name (Start Date - End Date or Present)
• Enhanced bullet point 1 with strong action verbs and quantifiable achievements
• Enhanced bullet point 2 with specific accomplishments
• Enhanced bullet point 3-5 highlighting impact and results

[Repeat for each position]

----------------------------
EDUCATION
Degree Name — University/School Name (Graduation Year)
Major/Concentration: [if applicable]
Relevant Coursework or Honors: [if applicable]

[Repeat for each degree]

----------------------------
TECHNICAL SKILLS
• Skill 1, Skill 2, Skill 3, etc. (grouped logically)

----------------------------
SOFT SKILLS
• Soft skill 1, Soft skill 2, etc.

----------------------------
LANGUAGES
• Language 1 (Proficiency level)
• Language 2 (Proficiency level)

[Add other relevant sections like Certifications, Projects, Awards if present in original]
============================

Rules:
- Use clean, consistent formatting
- Use bullet points (•) for lists
- Enhance language but keep all facts accurate
- Use strong action verbs (Led, Developed, Implemented, etc.)
- Add quantifiable metrics where possible
- Make it professional and ATS-friendly
- Do NOT hallucinate information not present in the original
- If information is missing, note it but don't make it up
""";

    try {
      print('📤 Sending resume enhancement request to Google Gemini...');

      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('❌ API request timeout after 60 seconds');
              throw Exception('API request timed out after 60 seconds');
            },
          );

      print('📥 API Response received: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      print('✅ Response parsed successfully');

      if (data['candidates'] == null ||
          data['candidates'].isEmpty ||
          data['candidates'][0]['content'] == null ||
          data['candidates'][0]['content']['parts'] == null ||
          data['candidates'][0]['content']['parts'].isEmpty) {
        print('❌ No content in API response');
        throw Exception('No response from Gemini API');
      }

      final enhancedContent =
          data["candidates"][0]["content"]["parts"][0]["text"] ??
          'Error generating enhanced resume';
      print('📄 Enhanced resume generated: ${enhancedContent.length} characters');
      return enhancedContent;
    } catch (e) {
      print('❌ Exception in _enhanceResumeWithAI: $e');
      throw Exception('Failed to enhance resume: $e');
    }
  }

  Future<void> _downloadEnhancedResume() async {
    if (_enhancedResume == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Generating PDF...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      await PDFGenerator.generateAndDownloadResume(_enhancedResume!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF downloaded successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _enhancedResume = null;
      _fileName = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Resume', style: GoogleFonts.playfairDisplay()),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing your resume...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  if (_fileName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'File: $_fileName',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : _enhancedResume != null
              ? _buildEnhancedResumeView()
              : _buildUploadView(),
    );
  }

  Widget _buildUploadView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Upload Your Resume',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload your existing resume (PDF, TXT) and we\'ll enhance it with AI to make it more professional and ATS-friendly.',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: PDF, TXT',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickAndProcessFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedResumeView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF10B981),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resume Enhanced Successfully!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _reset,
                tooltip: 'Upload Another',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _enhancedResume!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Upload Another'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _downloadEnhancedResume,
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
