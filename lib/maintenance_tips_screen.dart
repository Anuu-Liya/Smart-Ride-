import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MaintenanceTipsScreen extends StatefulWidget {
  final String vehicleType;

  const MaintenanceTipsScreen({super.key, required this.vehicleType});

  @override
  State<MaintenanceTipsScreen> createState() => _MaintenanceTipsScreenState();
}

class _MaintenanceTipsScreenState extends State<MaintenanceTipsScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // වැදගත්: පහත ඇති Key එක වෙනුවට Google AI Studio එකෙන් ලැබුණු සම්පූර්ණ Key එක දමන්න
  final String _apiKey = "AIzaSyC-381JyEJgQXpTSzYcTT7HGgs9D8P0hts";

  List<Map<String, String>> chatMessages = [
    {
      "bot": "Hello! I'm your Smart Ride AI Assistant. Ask me any technical issue about your car."
    }
  ];

  Future<void> _getAIResponse(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      chatMessages.add({"user": query});
      _isLoading = true;
    });

    try {
      // Gemini Model එක නිවැරදිව Initialize කිරීම
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = "You are an expert car mechanic. The user has a ${widget.vehicleType} vehicle. "
          "Provide a very helpful, short, and technical advice for this issue: $query. "
          "If it's dangerous, warn them to stop the car immediately.";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        if (response.text != null) {
          chatMessages.add({"bot": response.text!});
        } else {
          chatMessages.add({"bot": "I'm sorry, I couldn't generate a response. Please try again."});
        }
        _isLoading = false;
      });

      _scrollToBottom();

    } catch (e) {
      debugPrint("AI Error: $e"); // Error එක debug console එකේ බැලීමට
      setState(() {
        chatMessages.add({
          "bot": "Error: Connection failed. Please check your API key or internet connection."
        });
        _isLoading = false;
      });
    }
    _chatController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Maintenance & AI Help",
            style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.green),
                const SizedBox(width: 10),
                Text("Optimized for: ${widget.vehicleType}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                bool isUser = chatMessages[index].containsKey("user");
                return _buildChatBubble(
                  chatMessages[index][isUser ? "user" : "bot"]!,
                  isUser,
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask about engine, fuel, or noise...",
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (val) => _getAIResponse(val),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _getAIResponse(_chatController.text),
                  child: const CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 25,
                    child: Icon(Icons.bolt, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.black : Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}