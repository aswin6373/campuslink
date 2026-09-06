import 'package:flutter/material.dart';
import 'package:campuslink/app_theme.dart';
import 'package:campuslink/services/api_client.dart';

class ChatbotManagementScreen extends StatefulWidget {
  final String adminId;

  const ChatbotManagementScreen({
    super.key,
    required this.adminId,
  });

  @override
  _ChatbotManagementScreenState createState() => _ChatbotManagementScreenState();
}

class _ChatbotManagementScreenState extends State<ChatbotManagementScreen> {
  List<PredefinedQuestion> predefinedQuestions = [];
  List<AdminAnswer> adminAnswers = [];
  bool _isLoading = false;
  String institution = '';

  @override
  void initState() {
    super.initState();
    fetchPredefinedQuestions();
    fetchAdminAnswers();
  }

  Future<void> fetchPredefinedQuestions() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiClient.get('/api/chatbot/questions');
      final List<dynamic> list = data is List ? data : [];
      if (!mounted) return;
      setState(() {
        predefinedQuestions =
            list.map((json) => PredefinedQuestion.fromJson(json)).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load predefined questions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

void fetchAdminAnswers() async {
  try {
    final data = await ApiClient.get('/api/chatbot/answers');
    final List<dynamic> list = data is List ? data : [];
    if (!mounted) return;
    setState(() {
      adminAnswers = list.map((json) => AdminAnswer.fromJson(json)).toList();
    });
  } catch (e) {
    _showErrorSnackBar('Failed to load admin answers: $e');
  }
}



Future<void> saveAdminAnswer(AdminAnswer answer) async {
  try {
    await ApiClient.post('/api/chatbot/save', body: {
      'question_id': answer.questionId,
      'answer': answer.answer,
      'active': answer.active,
    });
    fetchAdminAnswers();
    _showSuccessSnackBar('Answer saved successfully');
  } catch (e) {
    _showErrorSnackBar('Error saving answer: $e');
  }
}

  void _showAnswerDialog(PredefinedQuestion question) {
    final existingAnswer = adminAnswers.firstWhere(
      (answer) => answer.questionId == question.id,
      orElse: () => AdminAnswer(
        id: '',
        questionId: question.id,
        answer: '',
        active: true,
      ),
    );

    final answerController = TextEditingController(text: existingAnswer.answer);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Answer Question',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                question.questionText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Your Answer',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Please enter an answer' : null,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final updatedAnswer = AdminAnswer(
                          id: existingAnswer.id,
                          questionId: question.id,
                          answer: answerController.text,
                          active: true,
                        );
                        saveAdminAnswer(updatedAnswer);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chatbot Management',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: () {
              fetchPredefinedQuestions();
              fetchAdminAnswers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: predefinedQuestions.length,
              itemBuilder: (context, index) {
                final question = predefinedQuestions[index];
                final answer = adminAnswers.firstWhere(
                  (a) => a.questionId == question.id,
                  orElse: () => AdminAnswer(
                    id: '',
                    questionId: question.id,
                    answer: '',
                    active: false,
                  ),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.questionText,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                question.category,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (answer.answer.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              answer.answer,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Active',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: answer.active,
                                  onChanged: (value) {
                                    final updatedAnswer = AdminAnswer(
                                      id: answer.id,
                                      questionId: question.id,
                                      answer: answer.answer,
                                      active: value,
                                    );
                                    saveAdminAnswer(updatedAnswer);
                                  },
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAnswerDialog(question),
                              label: Text(
                                answer.answer.isEmpty ? 'Add Answer' : 'Edit',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Add this Floating Action Button in the build method's Scaffold
floatingActionButton: FloatingActionButton(
  onPressed: _showAddQuestionDialog,
  tooltip: 'Add Predefined Question',
  child: Icon(Icons.add),
),
    );
  }
  // Add this inside ChatbotManagementScreen class

// Function to show the dialog for adding a predefined question
void _showAddQuestionDialog() {
  final categoryController = TextEditingController();
  final questionController = TextEditingController();
  final keywordsController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Predefined Question', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) => value!.isEmpty ? 'Enter a category' : null,
                  ),
                  TextFormField(
                    controller: questionController,
                    decoration: const InputDecoration(labelText: 'Question Text'),
                    validator: (value) => value!.isEmpty ? 'Enter a question' : null,
                  ),
                  TextFormField(
                    controller: keywordsController,
                    decoration: const InputDecoration(labelText: 'Keywords (comma-separated)'),
                    validator: (value) => value!.isEmpty ? 'Enter keywords' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _savePredefinedQuestion(
                        categoryController.text,
                        questionController.text,
                        keywordsController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Function to call the API and save the question
Future<void> _savePredefinedQuestion(String category, String questionText, String keywords) async {
  try {
    await ApiClient.post('/api/chatbot/questions', body: {
      'category': category,
      'question_text': questionText,
      'keywords': keywords,
    });
    fetchPredefinedQuestions(); // Refresh the list
    _showSuccessSnackBar('Question added successfully');
  } catch (e) {
    _showErrorSnackBar('Error: $e');
  }
}


  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

class PredefinedQuestion {
  final String id;
  final String category;
  final String questionText;
  final List<String> keywords;

  PredefinedQuestion({
    required this.id,
    required this.category,
    required this.questionText,
    required this.keywords,
  });

  factory PredefinedQuestion.fromJson(Map<String, dynamic> json) {
  return PredefinedQuestion(
    id: json['id']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    questionText: json['question_text']?.toString() ?? '',
    keywords: json['keywords'] is String
        ? (json['keywords'] as String).split(',')
        : List<String>.from((json['keywords'] ?? []).map((e) => e.toString())),
  );
}

}

class AdminAnswer {
  final String id;
  final String questionId;
  final String answer;
  final bool active;

  AdminAnswer({
    required this.id,
    required this.questionId,
    required this.answer,
    required this.active,
  });

  factory AdminAnswer.fromJson(Map<String, dynamic> json) {
    return AdminAnswer(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      active: json['active'] == 1 || json['active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'answer': answer,
      'active': active ? 1 : 0,
    };
  }
}