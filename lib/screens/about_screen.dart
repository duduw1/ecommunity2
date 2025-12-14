import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Ecommunity',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
            ),
            const SizedBox(height: 32),
            const Text(
              'O Ecommunity é um aplicativo focado na sustentabilidade e no fortalecimento da comunidade. Nosso objetivo é facilitar a doação e o reaproveitamento de itens, ajudando a diminuir o desperdício e promovendo uma economia circular.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Conecte-se com vizinhos, doe o que não usa mais e encontre tesouros que precisam de um novo lar. Juntos, podemos fazer a diferença!',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Desenvolvedores',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Ordem Alfabética: Edgard, Lucas, Robson
            _buildDeveloperCard(context, 'Edgard de Paiva'),
            _buildDeveloperCard(context, 'Lucas Dias'),
            _buildDeveloperCard(context, 'Robson Duarte'),
            const SizedBox(height: 40),
            Text(
              'Versão 1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context, String name) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.code, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
