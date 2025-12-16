import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String GEMINI_API_KEY = 'AIzaSyDhaZYVPXJ5UYkTdKaugS0GR_P4tzcxI3Q';
const String MODEL_NAME = 'gemini-2.5-flash';

// Função para chamar o Gemini API diretamente
Future<String> getGeminiResponse(String prompt) async {
  // O endpoint da API para gerar conteúdo
  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$MODEL_NAME:generateContent?key=$GEMINI_API_KEY'
  );

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt} // O texto da sua mensagem
        ]
      }
    ],
    // Opcional: Adicione configurações como 'temperature' ou 'maxOutputTokens'
    // "config": { "temperature": 0.7 }
  });

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      // Extrai o texto da resposta do JSON
      // O caminho é: response -> candidates[0] -> content -> parts[0] -> text
      final String aiText = decoded['candidates'][0]['content']['parts'][0]['text'];
      return aiText;
    } else {
      // Log de erro da API
      print('Gemini API Error - Status: ${response.statusCode}');
      print('Body: ${response.body}');
      return 'Erro na API: Falha ao obter resposta (Status: ${response.statusCode})';
    }
  } catch (e) {
    print('Erro de Rede/Parsing: $e');
    return 'Erro de rede: Não foi possível conectar ao servidor.';
  }
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState(); // criar o estado
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController(); // controlador para o campo de texto
  final List<_Message> _messages = []; // lista de mensagens

  // Modifique seu método _sendMessage na classe _AiAssistantScreenState
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();

    // 1. Adicionando UI (Mensagem do Usuário)
    setState(() {
      _messages.add(_Message(id: now.millisecondsSinceEpoch, text: text, isUser: true, timestamp: now));
    });
    _controller.clear();

    // 2. Chamando a API (Mensagem da AI)
    try {
      // ⚠️ Adicione aqui um indicador de carregamento (loading state) na UI antes de chamar a API
      final aiResponseText = await getGeminiResponse(text); // Chama sua nova função

      // 3. Adicionando UI (Resposta da AI)
      setState(() {
        _messages.add(_Message(id: DateTime.now().millisecondsSinceEpoch, text: aiResponseText, isUser: false, timestamp: DateTime.now()));
      });
      // ⚠️ Remova o indicador de carregamento (loading state) na UI
    } catch (e) {
      // Tratar erro
      print('Falha no processamento da mensagem: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return GestureDetector(
                  onTap: () => _editMessage(msg),
                  onLongPress: () => _deleteMessage(msg),
                  child: Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? Color.fromARGB(200,1,84,152)
                            : Color.fromARGB(200,0,110,17),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.text),
                          const SizedBox(height: 4),
                          Text(
                            '${msg.timestamp.day.toString().padLeft(2, '0')}/'
                                '${msg.timestamp.month.toString().padLeft(2, '0')} '
                                '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
                                '${msg.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Pergunte ao AI Assistant...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }
  void _editMessage(_Message msg) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: msg.text);
        return AlertDialog(
          title: const Text('Editar mensagem'),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Salvar')),
          ],
        );
      },
    );

    if (newText != null && newText.trim().isNotEmpty) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == msg.id);
        if (index != -1) {
          _messages[index] = _Message(
            id: msg.id,
            text: newText.trim(),
            isUser: msg.isUser,
            timestamp: msg.timestamp,
          );
        }
      });
    }
  }

  void _deleteMessage(_Message msg) {
    setState(() {
      _messages.removeWhere((m) => m.id == msg.id);
    });
  }
}

class _Message {
  final int id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp});
}
