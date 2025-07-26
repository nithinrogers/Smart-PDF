import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart PDF Q&A',
      debugShowCheckedModeBanner: false,
      home: PDFQuestionPage(),
    );
  }
}

class PDFQuestionPage extends StatefulWidget {
  @override
  _PDFQuestionPageState createState() => _PDFQuestionPageState();
}

class _PDFQuestionPageState extends State<PDFQuestionPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  String _answer = "";
  List<String> _urls = [];

  Future<void> askQuestion() async {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:5000/ask"), // Replace with your Flask backend URL
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "question": _questionController.text,
        "page": int.tryParse(_pageController.text) ?? 1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _answer = data["answer"] ?? "No answer available";
        _urls = List<String>.from(data["urls"] ?? []);
      });
    } else {
      setState(() {
        _answer = "Error: ${response.statusCode}";
        _urls = [];
      });
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $url")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      appBar: AppBar(
        title: Text("Ask PDF"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _pageController,
                decoration: InputDecoration(labelText: "Page Number"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(labelText: "Ask your question"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: askQuestion,
                child: Text("Ask"),
              ),
              SizedBox(height: 20),
              Text(
                "Answer: $_answer",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              if (_urls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "More Info:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._urls.map((url) => GestureDetector(
                      onTap: () => _launchURL(url),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          url,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
