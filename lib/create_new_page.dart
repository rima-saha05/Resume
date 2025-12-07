import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'pdf_generator.dart';

// Data models for sections/steps
class ResumeSection {
  final String name;
  final List<ResumeStep> steps;
  ResumeSection({required this.name, required this.steps});
}

class ResumeStep {
  final String id;
  final String label;
  final String type; // text | textarea | email | tel
  final String placeholder;
  final bool required;

  ResumeStep({
    required this.id,
    required this.label,
    this.type = 'text',
    this.placeholder = '',
    this.required = false,
  });
}

class ResumeBuilderPage extends StatefulWidget {
  const ResumeBuilderPage({super.key});

  @override
  State<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends State<ResumeBuilderPage> {
  final List<ResumeSection> sections = [
    ResumeSection(
      name: 'Personal Info',
      steps: [
        ResumeStep(
          id: 'firstName',
          label: 'What\'s your first name?',
          placeholder: 'John',
          required: true,
        ),
        ResumeStep(
          id: 'lastName',
          label: 'And your last name?',
          placeholder: 'Doe',
          required: true,
        ),
        ResumeStep(
          id: 'email',
          label: 'Your email address?',
          type: 'email',
          placeholder: 'john.doe@example.com',
          required: true,
        ),
        ResumeStep(
          id: 'phone',
          label: 'Phone number?',
          type: 'tel',
          placeholder: '+1 (555) 123-4567',
          required: true,
        ),
        ResumeStep(
          id: 'city',
          label: 'Which city are you in?',
          placeholder: 'New York',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Education',
      steps: [
        ResumeStep(
          id: 'degree',
          label: 'What\'s your degree?',
          placeholder: 'Bachelor of Science',
          required: true,
        ),
        ResumeStep(
          id: 'school',
          label: 'Which school?',
          placeholder: 'University of California',
          required: true,
        ),
        ResumeStep(
          id: 'graduationYear',
          label: 'Graduation year?',
          placeholder: '2020',
          required: true,
        ),
        ResumeStep(
          id: 'major',
          label: 'Your major?',
          placeholder: 'Ex:Computer Science',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Experience',
      steps: [
        ResumeStep(
          id: 'jobTitle',
          label: 'Most recent job title?',
          placeholder: 'Software Engineer',
          required: true,
        ),
        ResumeStep(
          id: 'company',
          label: 'Company name?',
          placeholder: 'Tech Corp',
          required: true,
        ),
        ResumeStep(
          id: 'duration',
          label: 'How long? (e.g., 2 years)',
          placeholder: '2 years',
          required: true,
        ),
        ResumeStep(
          id: 'responsibilities',
          label: 'Key responsibilities?',
          type: 'textarea',
          placeholder: 'Led development...',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Skills',
      steps: [
        ResumeStep(
          id: 'technicalSkills',
          label: 'Technical skills?',
          placeholder: 'Python, JavaScript, React',
          required: true,
        ),
        ResumeStep(
          id: 'softSkills',
          label: 'Soft skills?',
          placeholder: 'Communication, Leadership',
          required: false,
        ),
        ResumeStep(
          id: 'languages',
          label: 'Languages you speak?',
          placeholder: 'English, Spanish',
          required: false,
        ),
      ],
    ),
  ];

  int currentSection = 0;
  int currentStep = 0;
  final Map<String, String> formData = {};

  ResumeSection get sectionData => sections[currentSection];
  ResumeStep get stepData => sectionData.steps[currentStep];

  bool _isCurrentSectionComplete() {
    // Check if all required fields in current section are filled
    for (var step in sectionData.steps) {
      if (step.required &&
          (formData[step.id] == null || formData[step.id]!.trim().isEmpty)) {
        return false;
      }
    }
    return true;
  }

  void nextStep() {
    if (stepData.required &&
        (formData[stepData.id] == null ||
            formData[stepData.id]!.trim().isEmpty)) {
      return;
    }
    setState(() {
      if (currentStep < sectionData.steps.length - 1) {
        currentStep++;
      } else if (currentSection < sections.length - 1) {
        currentSection++;
        currentStep = 0;
      } else {
        // Completed
        showCompletionDialog();
      }
    });
  }

  void prevStep() {
    setState(() {
      if (currentStep > 0) {
        currentStep--;
      } else if (currentSection > 0) {
        currentSection--;
        currentStep = sections[currentSection].steps.length - 1;
      }
    });
  }

  Future<String> generateAIResumeContent() async {
    final apiKey = dotenv.env['API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('API key not found in .env file');
    }

    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final prompt =
        """
You are a professional resume writer. Create a polished, modern, ATS-friendly résumé using the user's information below.

USER DATA:
$formData

Your output MUST follow this exact structure:

============================
FULL NAME (Large & Bold)

📍 City
📞 Phone
📧 Email

----------------------------
PROFESSIONAL SUMMARY
Write a 3–4 line summary based on experience and skills.

----------------------------
EXPERIENCE
Job Title — Company (Duration)
• 3–5 bullet points highlighting achievements using strong action verbs.

----------------------------
EDUCATION
Degree — School (Graduation Year)
Major: (if provided)

----------------------------
TECHNICAL SKILLS
• List skills separated by comma

----------------------------
SOFT SKILLS
• List soft skills in bullet format

----------------------------
LANGUAGES
• List languages user speaks
============================

Rules:
- Use clean, consistent formatting
- Use bullet points wherever needed
- Do NOT add filler information
- Do NOT hallucinate; use only provided data
- Make it look like a real professional CV
""";

    try {
      print('📤 Sending API request to Google Gemini...');
      print('🔑 API Key present: ${apiKey.isNotEmpty}');
      print('🎯 Using model: gemini-2.5-flash');

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
            const Duration(seconds: 30),
            onTimeout: () {
              print('❌ API request timeout after 30 seconds');
              throw Exception('API request timed out after 30 seconds');
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

      final resumeContent =
          data["candidates"][0]["content"]["parts"][0]["text"] ??
          'Error generating resume';
      print('📄 Resume generated: ${resumeContent.length} characters');
      return resumeContent;
    } catch (e) {
      print('❌ Exception in generateAIResumeContent: $e');
      throw Exception('Failed to generate resume: $e');
    }
  }

  void showCompletionDialog() async {
    if (!mounted) return;

    // Show temporary loading screen
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: Text(
                            '⏳',
                            style: GoogleFonts.inter(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Generating your resume...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get AI generated resume content
      print('⏳ Starting resume generation...');
      String aiResume = await generateAIResumeContent();

      if (!mounted) {
        print('⚠️ Widget unmounted, aborting dialog display');
        return;
      }

      print('✅ Resume generated, closing loading dialog');
      Navigator.pop(context); // Remove loading dialog

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resume Ready!',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            height: 400,
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                aiResume,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.pop(context); // Close dialog

                  // Show downloading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📥 Generating PDF...'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Generate and download PDF
                  await PDFGenerator.generateAndDownloadResume(aiResume);

                  // Show success
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
              },
              child: const Text("Download PDF"),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error in showCompletionDialog: $e');

      if (!mounted) {
        print('⚠️ Widget unmounted, aborting error dialog display');
        return;
      }

      try {
        Navigator.pop(context); // Remove loading dialog
      } catch (navError) {
        print('⚠️ Could not pop loading dialog: $navError');
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Color(0xFFEF4444)),
              const SizedBox(width: 12),
              const Text('Error'),
            ],
          ),
          content: Text(
            'Failed to generate resume: $e',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  double get overallProgress {
    int totalSteps = 0;
    for (var section in sections) {
      totalSteps += section.steps.length;
    }
    int completedSteps =
        (currentSection * sections[0].steps.length) + currentStep;
    return completedSteps / totalSteps;
  }

  double get sectionProgress => ((currentStep + 1) / sectionData.steps.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resume Builder', style: GoogleFonts.playfairDisplay()),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section progress card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionData.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: sectionProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Question ${currentStep + 1} of ${sectionData.steps.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Question card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepData.label,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (stepData.type == 'textarea')
                      TextFormField(
                        key: ValueKey('${currentSection}-${currentStep}'),
                        minLines: 4,
                        maxLines: 6,
                        initialValue: formData[stepData.id] ?? '',
                        onChanged: (v) => formData[stepData.id] = v,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                          hintText: stepData.placeholder,
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      )
                    else
                      TextFormField(
                        key: ValueKey('${currentSection}-${currentStep}'),
                        initialValue: formData[stepData.id] ?? '',
                        onChanged: (v) => formData[stepData.id] = v,
                        keyboardType: stepData.type == 'email'
                            ? TextInputType.emailAddress
                            : (stepData.type == 'tel'
                                  ? TextInputType.phone
                                  : TextInputType.text),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                          hintText: stepData.placeholder,
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: prevStep,
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            label: const Text(
                              'Back',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (stepData.required &&
                                  (formData[stepData.id] == null ||
                                      formData[stepData.id]!.trim().isEmpty)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Please fill this required field',
                                    ),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }
                              nextStep();
                            },
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            label: Text(
                              (currentSection == sections.length - 1 &&
                                      currentStep ==
                                          sectionData.steps.length - 1)
                                  ? 'Complete'
                                  : 'Continue',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section overview
              Text(
                'Sections',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(sections.length, (i) {
                  final s = sections[i];
                  final completed = i < currentSection;
                  final isActive = i == currentSection;

                  return FilterChip(
                    label: Text(s.name),
                    selected: isActive,
                    onSelected: (v) {
                      // Only allow navigation to completed sections or next section
                      if (i < currentSection || i == currentSection) {
                        setState(() {
                          currentSection = i;
                          currentStep = 0;
                        });
                      } else if (i == currentSection + 1 &&
                          _isCurrentSectionComplete()) {
                        // Allow moving to next section only if current is complete
                        setState(() {
                          currentSection = i;
                          currentStep = 0;
                        });
                      } else {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Please complete all required fields in current section first',
                            ),
                            backgroundColor: Colors.orange[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    backgroundColor: completed
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : Colors.grey[200],
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                    avatar: completed
                        ? const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF10B981),
                          )
                        : null,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
