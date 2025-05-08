import 'dart:math';
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class EcoQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  EcoQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class QuestionOfTheDayPage extends StatefulWidget {
  @override
  _QuestionOfTheDayPageState createState() => _QuestionOfTheDayPageState();
}

class _QuestionOfTheDayPageState extends State<QuestionOfTheDayPage> {
  final List<EcoQuestion> ecoQuestions = [
    EcoQuestion(
      question:
          "What is the primary contributor to carbon footprint in households?",
      options: [
        "Electricity usage",
        "Recycling",
        "Air travel",
        "Water consumption",
      ],
      correctAnswer: "Air travel",
      explanation:
          "Air travel emits large amounts of CO₂ per trip, more than typical home energy use.",
    ),
    // Add more questions...
  ];

  EcoQuestion? questionOfTheDay;
  bool answered = false;
  bool alreadyCompleted = false;
  String userId = '';
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    String? userId = await PreferencesHelper.getUserID();
    if (userId != null && userId.isNotEmpty) {
      setState(() {
        this.userId = userId;
      });
    }
    await _checkIfAlreadyCompleted();
  }

  Future<void> _checkIfAlreadyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('qod_date');
    final savedIndex = prefs.getInt('qod_index');

    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/check_daily_status.php"),
      body: {"uid": userId, "date": today, "type": "daily_qod_done"},
    );

    if (response.statusCode == 200 &&
        jsonDecode(response.body)['completed'] == true) {
      setState(() => alreadyCompleted = true);
      return;
    }

    // Load question if not completed
    if (savedDate == today && savedIndex != null) {
      setState(() => questionOfTheDay = ecoQuestions[savedIndex]);
    } else {
      final randomIndex = Random().nextInt(ecoQuestions.length);
      prefs.setString('qod_date', today);
      prefs.setInt('qod_index', randomIndex);
      setState(() => questionOfTheDay = ecoQuestions[randomIndex]);
    }
  }

  void _handleAnswer(String userAnswer) async {
    setState(() => answered = true);
    final isCorrect = userAnswer == questionOfTheDay!.correctAnswer;

    if (isCorrect) {
      // ✅ Give water and mark daily
      await http.post(
        Uri.parse("https://ecoquest.ruputech.com/add_water.php"),
        body: {"uid": userId, "amount": "200", "type": "add"},
      );

      await http.post(
        Uri.parse("https://ecoquest.ruputech.com/complete_qod_task.php"),
        body: {"uid": userId, "type": "daily_qod_done", "date": today},
      );
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(isCorrect ? "✅ Correct!" : "❌ Incorrect"),
            content: Text(
              isCorrect
                  ? "You’ve earned 200 water drops!"
                  : "Correct answer: ${questionOfTheDay!.correctAnswer}\n\n${questionOfTheDay!.explanation}",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(
                      () => alreadyCompleted = true,
                    ); // ✅ Lock the screen after completion
                  }
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (alreadyCompleted) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(182, 140, 96, 1),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 32),
              Text(
                "Question of the Day",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Text(
            "You have completed the quiz of the day.\nCome again tomorrow!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButton: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pop(context); // Close the settings screen
            },
            child: Icon(Icons.cancel, size: 24, color: Colors.white),
            backgroundColor: Color.fromRGBO(
              182,
              140,
              96,
              1,
            ), // Back button color
          ),
        ),
      );
    }

    if (questionOfTheDay == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Question of the Day")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(182, 140, 96, 1),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 32),
            Text(
              "Question of the Day",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color.fromRGBO(139, 105, 70, 1)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 248, 230, 1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromRGBO(182, 140, 96, 1),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🌱 Question of the Day",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(101, 67, 33, 1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                questionOfTheDay!.question,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ...questionOfTheDay!.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(182, 140, 96, 1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: answered ? null : () => _handleAnswer(option),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Color.fromRGBO(182, 140, 96, 1),
        child: Icon(Icons.cancel, color: Colors.white),
      ),
    );
  }
}
