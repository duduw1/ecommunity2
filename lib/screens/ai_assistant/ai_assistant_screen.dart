import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necessário para copiar

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mensagem inicial de boas-vindas
    _messages.add(_Message(
      text: "Olá! Eu sou o EcoMestre, seu assistente de reciclagem. Como posso te ajudar hoje?",
      isUser: false
    ));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getGeminiResponse')
          .call({'text': text});

      final String responseText = result.data['text'] ?? "Desculpe, não entendi.";

      if (mounted) {
        setState(() {
          _messages.add(_Message(text: responseText, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message(
            text: "Erro ao conectar com a IA. Tente novamente mais tarde. ($e)",
            isUser: false,
            isError: true
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eco Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("EcoMestre está digitando...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                  );
                }

                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mensagem copiada!', textAlign: TextAlign.center),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          width: 200,
                        ),
                      );
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.isError 
                            ? Colors.red[100]
                            : (msg.isUser
                                ? Theme.of(context).primaryColor.withOpacity(0.9)
                                : Colors.grey[200]),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: msg.isUser ? const Radius.circular(12) : Radius.zero,
                          bottomRight: msg.isUser ? Radius.zero : const Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.isUser ? Colors.white : Colors.black87
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.05),
                )
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Pergunte sobre reciclagem...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
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

class _Message {
  final String text;
  final bool isUser;
  final bool isError;

  _Message({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
