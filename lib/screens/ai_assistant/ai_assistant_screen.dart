import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    _messages.add(_Message(
      text: "Olá! Eu sou o EcoMestre. Pergunte-me sobre reciclagem!",
      isUser: false
    ));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

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

      final String responseText = result.data['text'] ?? "Sem resposta.";

      if (mounted) {
        setState(() {
          _messages.add(_Message(text: responseText, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = "Erro ao conectar.";
        if (e is FirebaseFunctionsException) {
          errorMsg = "Erro do Assistente: ${e.message}";
        } else {
           errorMsg = "Erro: $e";
        }
        
        _messages.add(_Message(
          text: errorMsg,
          isUser: false,
          isError: true
        ));
        _isTyping = false;
      }
    }
    _scrollToBottom();
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
    final theme = Theme.of(context);

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
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "EcoMestre está digitando...", 
                        style: TextStyle(fontStyle: FontStyle.italic, color: theme.textTheme.bodySmall?.color)
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final Color bubbleColor;
                final Color textColor;

                if (msg.isError) {
                  bubbleColor = theme.colorScheme.errorContainer;
                  textColor = theme.colorScheme.onErrorContainer;
                } else if (msg.isUser) {
                  bubbleColor = theme.colorScheme.primary;
                  textColor = theme.colorScheme.onPrimary;
                } else {
                  bubbleColor = theme.colorScheme.surfaceVariant;
                  textColor = theme.colorScheme.onSurfaceVariant;
                }

                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copiado!')),
                      );
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isTyping,
                    decoration: InputDecoration(
                      hintText: _isTyping ? 'Aguarde...' : 'Digite sua dúvida...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      filled: true,
                      // A cor do input também deve ser do tema
                      fillColor: theme.colorScheme.surfaceVariant,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isTyping 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send),
                  onPressed: _sendMessage,
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
