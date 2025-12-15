import 'package:flutter/material.dart';

class EcoCalendarScreen extends StatelessWidget {
  const EcoCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados simulados de eventos
    final List<Map<String, String>> events = [
      {
        'date': '15',
        'month': 'OUT',
        'title': 'Feira de Trocas Comunitária',
        'location': 'Praça Central',
        'time': '10:00 - 16:00'
      },
      {
        'date': '22',
        'month': 'OUT',
        'title': 'Mutirão de Limpeza da Praia',
        'location': 'Praia do Sol',
        'time': '08:00 - 12:00'
      },
      {
        'date': '05',
        'month': 'NOV',
        'title': 'Workshop de Compostagem',
        'location': 'Centro Cultural',
        'time': '14:00 - 17:00'
      },
      {
        'date': '12',
        'month': 'NOV',
        'title': 'Coleta de Lixo Eletrônico',
        'location': 'Escola Municipal',
        'time': '09:00 - 15:00'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Calendário Ecológico")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Data
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          event['date']!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          event['month']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Detalhes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title']!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(event['location']!, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(event['time']!, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidade de adicionar evento em breve!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
