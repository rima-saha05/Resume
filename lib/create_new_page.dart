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
  final bool allowMultiple;
  ResumeSection({
    required this.name,
    required this.steps,
    this.allowMultiple = false,
  });
}

class ResumeStep {
  final String id;
  final String label;
  final String type; // text | textarea | email | tel | url | date
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
          placeholder: '',
          required: true,
        ),
        ResumeStep(
          id: 'lastName',
          label: 'And your last name?',
          placeholder: '',
          required: true,
        ),
        ResumeStep(
          id: 'email',
          label: 'Your email address?',
          type: 'email',
          placeholder: 'Example: john.doe@email.com or jane.smith@company.com',
          required: true,
        ),
        ResumeStep(
          id: 'phone',
          label: 'Phone number?',
          type: 'tel',
          placeholder: 'Example: +1 (555) 123-4567 or +44 20 7946 0959',
          required: true,
        ),
        ResumeStep(
          id: 'city',
          label: 'City? (Optional)',
          placeholder: 'Example: New York, London, Toronto',
          required: false,
        ),
        ResumeStep(
          id: 'linkedin',
          label: 'LinkedIn profile URL? (Optional)',
          type: 'url',
          placeholder: 'Example: https://linkedin.com/in/johndoe',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Professional Summary',
      steps: [
        ResumeStep(
          id: 'summary',
          label: 'Write a brief professional summary (or leave blank for AI to generate)',
          type: 'textarea',
          placeholder: 'Example: Experienced software engineer with 5+ years of expertise in full-stack development. Proven track record of building scalable applications, leading technical teams, and delivering high-quality solutions. Specialized in React, Node.js, and cloud technologies. Passionate about clean code, agile methodologies, and continuous learning.',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Experience',
      allowMultiple: true,
      steps: [
        ResumeStep(
          id: 'jobTitle',
          label: 'Job title?',
          placeholder: 'Example: Software Engineer, Senior Developer, Product Manager, Data Scientist',
          required: true,
        ),
        ResumeStep(
          id: 'company',
          label: 'Company name?',
          placeholder: 'Example: Google, Microsoft, Tech Corp, Startup Inc.',
          required: true,
        ),
        ResumeStep(
          id: 'startDate',
          label: 'Start date? (MM/YYYY)',
          type: 'date',
          placeholder: 'Example: 01/2020 or 06/2018 or 09/2022',
          required: true,
        ),
        ResumeStep(
          id: 'endDate',
          label: 'End date? (MM/YYYY or "Present")',
          type: 'date',
          placeholder: 'Example: 12/2023 or Present or 03/2024',
          required: true,
        ),
        ResumeStep(
          id: 'responsibilities',
          label: 'Key achievements and responsibilities?',
          type: 'textarea',
          placeholder: 'Example:\n• Led development of scalable web applications serving 10,000+ users\n• Increased application performance by 40% through optimization\n• Collaborated with cross-functional teams to deliver 5+ major features\n• Mentored 3 junior developers and improved team productivity by 25%',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Education',
      allowMultiple: true,
      steps: [
        ResumeStep(
          id: 'degree',
          label: 'Degree?',
          placeholder: 'Example: Bachelor of Science, Master of Arts, PhD in Computer Science, Associate Degree',
          required: true,
        ),
        ResumeStep(
          id: 'school',
          label: 'School/University?',
          placeholder: 'Example: University of California, MIT, Harvard University, Stanford University',
          required: true,
        ),
        ResumeStep(
          id: 'graduationYear',
          label: 'Graduation year?',
          placeholder: 'Example: 2020 or 2024 or 2018',
          required: true,
        ),
        ResumeStep(
          id: 'gpa',
          label: 'CGPA/GPA? (Optional)',
          placeholder: 'Example: 3.8/4.0 or 4.0/4.0 or 3.5/4.0',
          required: false,
        ),
      ],
    ),
    ResumeSection(
      name: 'Skills',
      steps: [
        ResumeStep(
          id: 'technicalSkills',
          label: 'Technical skills? (comma-separated)',
          placeholder: 'Example: Python, JavaScript, React, Node.js, SQL, Docker, AWS, Git, MongoDB, PostgreSQL',
          required: true,
        ),
      ],
    ),
    ResumeSection(
      name: 'Certifications',
      allowMultiple: true,
      steps: [
        ResumeStep(
          id: 'certName',
          label: 'Certification name?',
          placeholder: 'Example: AWS Certified Solutions Architect, Google Cloud Professional, PMP Certification',
          required: true,
        ),
      ],
    ),
    ResumeSection(
      name: 'Projects',
      allowMultiple: true,
      steps: [
        ResumeStep(
          id: 'projectName',
          label: 'Project name?',
          placeholder: 'Example: E-Commerce Platform, Mobile Banking App, AI Chatbot, Data Analytics Dashboard',
          required: true,
        ),
        ResumeStep(
          id: 'projectDescription',
          label: 'Project description?',
          type: 'textarea',
          placeholder: 'Example: Built a full-stack e-commerce platform with React frontend and Node.js backend. Implemented payment processing, user authentication, and inventory management. Deployed on AWS with CI/CD pipeline. Resulted in 50% increase in online sales and improved user experience.',
          required: false,
        ),
      ],
    ),
  ];

  int currentSection = 0;
  int currentStep = 0;
  final Map<String, dynamic> formData = {};
  
  // Track current entry index for multiple-entry sections
  final Map<String, int> currentEntryIndex = {};

  ResumeSection get sectionData => sections[currentSection];
  ResumeStep get stepData => sectionData.steps[currentStep];
  
  String get currentEntryKey => _getCurrentEntryKey();
  
  String _getCurrentEntryKey() {
    if (sectionData.allowMultiple) {
      final sectionKey = sectionData.name.toLowerCase().replaceAll(' ', '_');
      final entryIndex = currentEntryIndex[sectionKey] ?? 0;
      return '${stepData.id}_${entryIndex}';
    }
    return stepData.id;
  }

  int _getCurrentEntryCount(String sectionName) {
    final sectionKey = sectionName.toLowerCase().replaceAll(' ', '_');
    int count = 0;
    final prefix = _getFirstStepId(sectionName);
    while (formData.containsKey('${prefix}_$count')) {
      count++;
    }
    return count == 0 ? 1 : count; // At least 1 entry
  }
  
  String _getFirstStepId(String sectionName) {
    final section = sections.firstWhere((s) => s.name == sectionName);
    return section.steps.first.id;
  }

  bool _isCurrentSectionComplete() {
    if (sectionData.allowMultiple) {
      final sectionKey = sectionData.name.toLowerCase().replaceAll(' ', '_');
      final entryIndex = currentEntryIndex[sectionKey] ?? 0;
      
      for (var step in sectionData.steps) {
        final key = '${step.id}_$entryIndex';
        if (step.required && (formData[key] == null || formData[key].toString().trim().isEmpty)) {
          return false;
        }
      }
      return true;
    } else {
      for (var step in sectionData.steps) {
        if (step.required && (formData[step.id] == null || formData[step.id].toString().trim().isEmpty)) {
          return false;
        }
      }
      return true;
    }
  }

  void nextStep() {
    // Validation is now handled in the button's onPressed
    setState(() {
      if (currentStep < sectionData.steps.length - 1) {
        currentStep++;
      } else if (currentSection < sections.length - 1) {
        currentSection++;
        currentStep = 0;
        // Reset entry index for new section
        final sectionKey = sections[currentSection].name.toLowerCase().replaceAll(' ', '_');
        if (!currentEntryIndex.containsKey(sectionKey)) {
          currentEntryIndex[sectionKey] = 0;
        }
      } else {
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

  void _addAnotherEntry() {
    setState(() {
      final sectionKey = sectionData.name.toLowerCase().replaceAll(' ', '_');
      final newIndex = _getCurrentEntryCount(sectionData.name);
      currentEntryIndex[sectionKey] = newIndex;
      currentStep = 0;
    });
  }

  void _removeCurrentEntry() {
    if (_getCurrentEntryCount(sectionData.name) <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one entry'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      final sectionKey = sectionData.name.toLowerCase().replaceAll(' ', '_');
      final entryIndex = currentEntryIndex[sectionKey] ?? 0;
      
      // Remove all fields for this entry
      for (var step in sectionData.steps) {
        formData.remove('${step.id}_$entryIndex');
      }
      
      // Move to previous entry or first entry
      if (entryIndex > 0) {
        currentEntryIndex[sectionKey] = entryIndex - 1;
      } else {
        currentEntryIndex[sectionKey] = 0;
      }
      currentStep = 0;
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

    // Format data for AI
    String formattedData = _formatDataForAI();

    final prompt = """
You are a professional resume writer. Create a polished, modern, ATS-friendly résumé using the user's information below.

USER DATA:
$formattedData

Your output MUST follow this exact structure:

============================
FULL NAME (Large & Bold)

📍 City (if provided)
📞 Phone
📧 Email
🔗 LinkedIn: [if provided]

----------------------------
PROFESSIONAL SUMMARY
${formData['summary'] != null && formData['summary'].toString().trim().isNotEmpty 
  ? 'Use the provided summary and enhance it professionally.' 
  : 'Write a compelling 3–4 line summary based on experience and skills.'}

----------------------------
EXPERIENCE
[For each experience entry, format as:]
Job Title — Company Name
Start Date - End Date
• Enhanced bullet point 1 with strong action verbs and quantifiable achievements
• Enhanced bullet point 2 with specific accomplishments
• Enhanced bullet point 3-5 highlighting impact and results

[Order experiences from most recent to oldest]

----------------------------
EDUCATION
[For each education entry, format as:]
Degree Name — University/School Name
Graduation Year | GPA: [if provided]

[Order from most recent to oldest]

----------------------------
TECHNICAL SKILLS
• Skill 1, Skill 2, Skill 3, etc. (grouped logically by category if applicable)

----------------------------
CERTIFICATIONS
[If provided, format as:]
Certification Name

----------------------------
PROJECTS
[If provided, format as:]
Project Name
• Description with key achievements or impact

============================

Rules:
- Use clean, consistent formatting
- Use bullet points (•) for lists
- Enhance language but keep all facts accurate
- Use strong action verbs (Led, Developed, Implemented, Optimized, etc.)
- Add quantifiable metrics where possible
- Make it professional and ATS-friendly
- Do NOT hallucinate information not present in the original
- If information is missing, note it but don't make it up
- Order experiences and education chronologically (most recent first)
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

  String _formatDataForAI() {
    final buffer = StringBuffer();
    
    // Personal Info
    buffer.writeln('PERSONAL INFORMATION:');
    if (formData['firstName'] != null) buffer.writeln('First Name: ${formData['firstName']}');
    if (formData['lastName'] != null) buffer.writeln('Last Name: ${formData['lastName']}');
    if (formData['email'] != null) buffer.writeln('Email: ${formData['email']}');
    if (formData['phone'] != null) buffer.writeln('Phone: ${formData['phone']}');
    if (formData['city'] != null) buffer.writeln('City: ${formData['city']}');
    if (formData['linkedin'] != null) buffer.writeln('LinkedIn: ${formData['linkedin']}');
    buffer.writeln('');
    
    // Summary
    if (formData['summary'] != null && formData['summary'].toString().trim().isNotEmpty) {
      buffer.writeln('PROFESSIONAL SUMMARY:');
      buffer.writeln(formData['summary']);
      buffer.writeln('');
    }
    
    // Experiences
    final expCount = _getCurrentEntryCount('Experience');
    if (expCount > 0) {
      buffer.writeln('EXPERIENCE:');
      for (int i = 0; i < expCount; i++) {
        if (formData['jobTitle_$i'] != null) {
          buffer.writeln('Entry ${i + 1}:');
          if (formData['jobTitle_$i'] != null) buffer.writeln('  Job Title: ${formData['jobTitle_$i']}');
          if (formData['company_$i'] != null) buffer.writeln('  Company: ${formData['company_$i']}');
          if (formData['startDate_$i'] != null) buffer.writeln('  Start Date: ${formData['startDate_$i']}');
          if (formData['endDate_$i'] != null) buffer.writeln('  End Date: ${formData['endDate_$i']}');
          if (formData['responsibilities_$i'] != null) buffer.writeln('  Responsibilities: ${formData['responsibilities_$i']}');
          buffer.writeln('');
        }
      }
    }
    
    // Education
    final eduCount = _getCurrentEntryCount('Education');
    if (eduCount > 0) {
      buffer.writeln('EDUCATION:');
      for (int i = 0; i < eduCount; i++) {
        if (formData['degree_$i'] != null) {
          buffer.writeln('Entry ${i + 1}:');
          if (formData['degree_$i'] != null) buffer.writeln('  Degree: ${formData['degree_$i']}');
          if (formData['school_$i'] != null) buffer.writeln('  School: ${formData['school_$i']}');
          if (formData['graduationYear_$i'] != null) buffer.writeln('  Graduation Year: ${formData['graduationYear_$i']}');
          if (formData['gpa_$i'] != null) buffer.writeln('  GPA: ${formData['gpa_$i']}');
          buffer.writeln('');
        }
      }
    }
    
    // Skills
    buffer.writeln('SKILLS:');
    if (formData['technicalSkills'] != null) buffer.writeln('Technical: ${formData['technicalSkills']}');
    buffer.writeln('');
    
    // Certifications
    final certCount = _getCurrentEntryCount('Certifications');
    if (certCount > 0) {
      buffer.writeln('CERTIFICATIONS:');
      for (int i = 0; i < certCount; i++) {
        if (formData['certName_$i'] != null) {
          buffer.writeln('Entry ${i + 1}:');
          if (formData['certName_$i'] != null) buffer.writeln('  Name: ${formData['certName_$i']}');
          buffer.writeln('');
        }
      }
    }
    
    // Projects
    final projCount = _getCurrentEntryCount('Projects');
    if (projCount > 0) {
      buffer.writeln('PROJECTS:');
      for (int i = 0; i < projCount; i++) {
        if (formData['projectName_$i'] != null) {
          buffer.writeln('Entry ${i + 1}:');
          if (formData['projectName_$i'] != null) buffer.writeln('  Name: ${formData['projectName_$i']}');
          if (formData['projectDescription_$i'] != null) buffer.writeln('  Description: ${formData['projectDescription_$i']}');
          buffer.writeln('');
        }
      }
    }
    
    return buffer.toString();
  }

  void showCompletionDialog() async {
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
      print('⏳ Starting resume generation...');
      String aiResume = await generateAIResumeContent();

      if (!mounted) {
        print('⚠️ Widget unmounted, aborting dialog display');
        return;
      }

      print('✅ Resume generated, closing loading dialog');
      Navigator.pop(context);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumePreviewPage(resumeContent: aiResume),
        ),
      );
    } catch (e) {
      print('❌ Error in showCompletionDialog: $e');

      if (!mounted) {
        print('⚠️ Widget unmounted, aborting error dialog display');
        return;
      }

      try {
        Navigator.pop(context);
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
    int completedSteps = 0;
    for (int i = 0; i < currentSection; i++) {
      completedSteps += sections[i].steps.length;
    }
    completedSteps += currentStep;
    return totalSteps > 0 ? completedSteps / totalSteps : 0;
  }

  double get sectionProgress => ((currentStep + 1) / sectionData.steps.length);

  IconData _getSectionIcon(String sectionName) {
    switch (sectionName) {
      case 'Personal Info':
        return Icons.person_outline;
      case 'Professional Summary':
        return Icons.description_outlined;
      case 'Experience':
        return Icons.work_outline;
      case 'Education':
        return Icons.school_outlined;
      case 'Skills':
        return Icons.stars_outlined;
      case 'Certifications':
        return Icons.verified_outlined;
      case 'Projects':
        return Icons.folder_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = formData[currentEntryKey]?.toString() ?? '';
    final entryCount = sectionData.allowMultiple 
        ? _getCurrentEntryCount(sectionData.name) 
        : 1;
    final currentEntryNum = sectionData.allowMultiple
        ? (currentEntryIndex[sectionData.name.toLowerCase().replaceAll(' ', '_')] ?? 0) + 1
        : 1;

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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.15),
                      const Color(0xFF8B5CF6).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getSectionIcon(sectionData.name),
                                  color: const Color(0xFF6366F1),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  sectionData.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sectionData.allowMultiple)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Entry $currentEntryNum of $entryCount',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: sectionProgress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentStep + 1} of ${sectionData.steps.length}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '${(sectionProgress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Question card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stepData.required)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Text(
                              '*',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.red[400],
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            stepData.label,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (stepData.type == 'textarea')
                      TextFormField(
                        key: ValueKey('${currentSection}-${currentStep}-$currentEntryKey'),
                        minLines: 4,
                        maxLines: 8,
                        initialValue: currentValue,
                        onChanged: (v) {
                          setState(() {
                            formData[currentEntryKey] = v;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: stepData.required && currentValue.isEmpty
                                  ? Colors.red[300]!
                                  : Colors.grey[500]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: stepData.required && currentValue.isEmpty
                                  ? Colors.red[200]!
                                  : Colors.grey[400]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: stepData.required && currentValue.isEmpty
                                  ? Colors.red[400]!
                                  : const Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[500]!, width: 2),
                          ),
                          hintText: stepData.placeholder,
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          hintMaxLines: stepData.type == 'textarea' ? 5 : 1,
                          filled: true,
                          fillColor: stepData.required && currentValue.isEmpty
                              ? Colors.red[50]
                              : Colors.white,
                          suffixIcon: currentValue.isNotEmpty
                              ? Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF10B981),
                                  size: 20,
                                )
                              : null,
                        ),
                      )
                    else
                      TextFormField(
                        key: ValueKey('${currentSection}-${currentStep}-$currentEntryKey'),
                        initialValue: currentValue,
                        onChanged: (v) {
                          setState(() {
                            formData[currentEntryKey] = v;
                          });
                        },
                        keyboardType: stepData.type == 'email'
                            ? TextInputType.emailAddress
                            : (stepData.type == 'tel'
                                  ? TextInputType.phone
                                  : (stepData.type == 'url'
                                        ? TextInputType.url
                                        : TextInputType.text)),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: stepData.required && currentValue.isEmpty
                                  ? Colors.red[300]!
                                  : Colors.grey[500]!,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: stepData.required && currentValue.isEmpty
                                  ? Colors.red[200]!
                                  : Colors.grey[400]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: stepData.required && currentValue.isEmpty
                                  ? Colors.red[400]!
                                  : const Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[500]!, width: 2),
                          ),
                          hintText: stepData.placeholder,
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          hintMaxLines: stepData.type == 'textarea' ? 5 : 1,
                          filled: true,
                          fillColor: stepData.required && currentValue.isEmpty
                              ? Colors.red[50]
                              : Colors.white,
                          suffixIcon: currentValue.isNotEmpty
                              ? Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF10B981),
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (sectionData.allowMultiple && entryCount > 1 && currentEntryNum > 1)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                final sectionKey = sectionData.name.toLowerCase().replaceAll(' ', '_');
                                currentEntryIndex[sectionKey] = (currentEntryIndex[sectionKey] ?? 0) - 1;
                                currentStep = 0;
                              });
                            },
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Previous Entry'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                            ),
                          ),
                        if (sectionData.allowMultiple && currentEntryNum < entryCount)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                final sectionKey = sectionData.name.toLowerCase().replaceAll(' ', '_');
                                currentEntryIndex[sectionKey] = (currentEntryIndex[sectionKey] ?? 0) + 1;
                                currentStep = 0;
                              });
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('Next Entry'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                            ),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: prevStep,
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          label: const Text('Back'),
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
                            final value = formData[currentEntryKey]?.toString().trim() ?? '';
                            if (stepData.required && value.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('Please fill this required field'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }
                            nextStep();
                          },
                          icon: Icon(
                            (currentSection == sections.length - 1 &&
                                    currentStep == sectionData.steps.length - 1)
                                ? Icons.check_circle
                                : Icons.arrow_forward_ios,
                            size: 18,
                          ),
                          label: Text(
                            (currentSection == sections.length - 1 &&
                                    currentStep == sectionData.steps.length - 1)
                                ? 'Complete'
                                : 'Continue',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                    if (sectionData.allowMultiple) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _addAnotherEntry,
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                label: const Text('Add Another Entry'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            if (entryCount > 1) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _removeCurrentEntry,
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  label: const Text('Remove Entry'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[600],
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: Colors.red[300]!, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section overview
              Row(
                children: [
                  Icon(Icons.list_alt, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    'All Sections',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(sections.length, (i) {
                  final s = sections[i];
                  final completed = i < currentSection;
                  final isActive = i == currentSection;

                  return FilterChip(
                    avatar: completed
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          )
                        : (isActive
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _getSectionIcon(s.name),
                                size: 16,
                                color: Colors.grey[600],
                              )),
                    label: Text(
                      s.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    selected: isActive,
                    onSelected: (v) {
                      if (i < currentSection || i == currentSection) {
                        setState(() {
                          currentSection = i;
                          currentStep = 0;
                          final sectionKey = sections[i].name.toLowerCase().replaceAll(' ', '_');
                          if (!currentEntryIndex.containsKey(sectionKey)) {
                            currentEntryIndex[sectionKey] = 0;
                          }
                        });
                      } else if (i == currentSection + 1 && _isCurrentSectionComplete()) {
                        setState(() {
                          currentSection = i;
                          currentStep = 0;
                          final sectionKey = sections[i].name.toLowerCase().replaceAll(' ', '_');
                          if (!currentEntryIndex.containsKey(sectionKey)) {
                            currentEntryIndex[sectionKey] = 0;
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Please complete all required fields in current section first',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.orange[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    backgroundColor: completed
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : (isActive
                            ? const Color(0xFF6366F1).withOpacity(0.15)
                            : Colors.grey[100]),
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.25),
                    checkmarkColor: const Color(0xFF6366F1),
                    side: BorderSide(
                      color: isActive
                          ? const Color(0xFF6366F1)
                          : (completed
                              ? const Color(0xFF10B981)
                              : Colors.grey[300]!),
                      width: isActive ? 2 : 1,
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

// Resume Preview Page
class ResumePreviewPage extends StatelessWidget {
  final String resumeContent;

  const ResumePreviewPage({super.key, required this.resumeContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Your Resume',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📥 Generating PDF...'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );

                await PDFGenerator.generateAndDownloadResume(resumeContent);

                if (context.mounted) {
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
                if (context.mounted) {
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
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📥 Generating PDF...'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        await PDFGenerator.generateAndDownloadResume(resumeContent);

                        if (context.mounted) {
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
                        if (context.mounted) {
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
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Resume content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  resumeContent,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.8,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
