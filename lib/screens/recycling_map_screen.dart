import 'package:flutter/material.dart';

class RecyclingMapScreen extends StatelessWidget {
  const RecyclingMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados simulados de pontos de coleta
    final List<Map<String, String>> collectionPoints = [
      {
        'name': 'Ecoponto Central',
        'address': 'Av. das Flores, 123',
        'types': 'Vidro, Papel, Plástico',
        'distance': '1.2 km'
      },
      {
        'name': 'Cooperativa Recicla+',
        'address': 'Rua da Sustentabilidade, 45',
        'types': 'Eletrônicos, Metal',
        'distance': '2.5 km'
      },
      {
        'name': 'Ponto Verde Supermercado',
        'address': 'Av. Brasil, 1000',
        'types': 'Óleo de Cozinha, Pilhas',
        'distance': '3.0 km'
      },
      {
        'name': 'Estação de Reciclagem Sul',
        'address': 'Rua do Porto, 88',
        'types': 'Móveis, Entulho',
        'distance': '5.4 km'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Pontos de Coleta")),
      body: Column(
        children: [
          // Simulação da Área do Mapa (Placeholder)
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[300],
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.map, size: 80, color: Colors.grey),
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Integração com Mapbox requer API Key",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: collectionPoints.length,
              itemBuilder: (context, index) {
                final point = collectionPoints[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.recycle, color: Colors.white),
                    ),
                    title: Text(point['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(point['address']!),
                        const SizedBox(height: 4),
                        Text(
                          point['types']!,
                          style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        Text(point['distance']!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navegar para: ${point['name']}')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Ação futura para abrir mapa externo
        },
        label: const Text("Abrir no GPS"),
        icon: const Icon(Icons.map_outlined),
      ),
    );
  }
}
