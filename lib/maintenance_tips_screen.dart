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

  // ඔබේ API Key එක මෙතැනට ඇතුළත් කරන්න
  final String _apiKey = "YOUR_GEMINI_API_KEY_HERE";

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    // මුලින්ම වාහනයට අදාළ සාමාන්‍ය උපදෙස් ලබා ගැනීම
    _getInitialMaintenanceTips();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getInitialMaintenanceTips() async {
    setState(() => _isLoading = true);
    final prompt = "Give me 3 essential maintenance tips for a ${widget.vehicleType}. "
        "Keep them brief and professional.";
    await _callGemini(prompt, isInitial: true);
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _chatController.clear();
    _scrollToBottom();

    final prompt = "Vehicle: ${widget.vehicleType}. Question: $text. "
        "Act as an expert mechanic. Give a short, technical answer. "
        "If it's a safety risk, warn them strongly.";
    
    await _callGemini(prompt);
  }

  Future<void> _callGemini(String prompt, {bool isInitial = false}) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _messages.add({
          "role": "bot",
          "text": response.text ?? "සමාවන්න, මට පිළිතුරක් ලබා දීමට නොහැක."
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "සම්බන්ධතාවය බිඳ වැටුණි. නැවත උත්සාහ කරන්න."});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.vehicleType} Maintenance"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: !isUser ? Radius.zero : null,
                      ),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Ask about your ${widget.vehicleType}...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueGrey[900],
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
