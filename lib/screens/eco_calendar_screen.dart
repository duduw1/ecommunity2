import 'package:ecommunity/models/event_model.dart';
import 'package:ecommunity/repositories/calendar_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EcoCalendarScreen extends StatefulWidget {
  const EcoCalendarScreen({super.key});

  @override
  State<EcoCalendarScreen> createState() => _EcoCalendarScreenState();
}

class _EcoCalendarScreenState extends State<EcoCalendarScreen> {
  final CalendarRepository _repository = CalendarRepository();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para adicionar novo evento
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Função para formatar a exibição da data no card
  String _getMonth(DateTime date) {
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    return months[date.month - 1];
  }

  void _showAddEventDialog() {
    _titleController.clear();
    _descController.clear();
    _locationController.clear();
    _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Novo Evento Ecológico'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator: (val) => val!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Local'),
                        validator: (val) => val!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text("Data: "),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você precisa estar logado.')));
                        return;
                      }

                      final newEvent = Event(
                        id: '',
                        title: _titleController.text,
                        description: _descController.text,
                        location: _locationController.text,
                        date: _selectedDate,
                        createdBy: user.uid,
                        attendees: [],
                      );

                      try {
                        await _repository.addEvent(newEvent);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento criado com sucesso!')));
                        }
                      } catch (e) {
                         // Erro tratado no repo
                      }
                    }
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Evento"),
        content: Text("Tem certeza que deseja excluir '${event.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Não")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.deleteEvent(event.id);
            },
            child: const Text("Sim, excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Calendário Ecológico")),
      body: StreamBuilder<List<Event>>(
        stream: _repository.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum evento futuro encontrado."));
          }

          final events = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isCreator = currentUser?.uid == event.createdBy;
              final isAttending = currentUser != null && event.attendees.contains(currentUser.uid);
              final attendeesCount = event.attendees.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Data Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  event.date.day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                                Text(
                                  _getMonth(event.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isCreator)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _confirmDelete(event),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(event.location, style: const TextStyle(color: Colors.grey))),
                                  ],
                                ),
                                if (event.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      // Ações de Presença
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, size: 18, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text("$attendeesCount confirmados", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          
                          if (currentUser != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                _repository.toggleAttendance(event.id, currentUser.uid);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAttending ? Colors.red[100] : Colors.green[100],
                                foregroundColor: isAttending ? Colors.red[900] : Colors.green[900],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              icon: Icon(isAttending ? Icons.close : Icons.check, size: 18),
                              label: Text(isAttending ? "Não vou" : "Eu vou"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        tooltip: 'Adicionar Evento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
