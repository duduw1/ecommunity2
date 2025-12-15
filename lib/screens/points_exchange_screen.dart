import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PointsExchangeScreen extends StatelessWidget {
  const PointsExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Troca de Pontos")),
      body: user == null
          ? const Center(child: Text("Faça login para ver seus pontos."))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final points = userData?['points'] ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card de Saldo
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green[700]!, Colors.green[400]!]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            const Text("Seus Pontos", style: TextStyle(color: Colors.white, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              "$points",
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text("Continue doando para ganhar mais!", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      const Text("Recompensas Disponíveis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      _buildRewardItem(context, "Cupom de R\$ 10 em Loja Parceira", 500, points),
                      _buildRewardItem(context, "Kit de Sementes Orgânicas", 300, points),
                      _buildRewardItem(context, "Ecobag Personalizada", 200, points),
                      _buildRewardItem(context, "Certificado de Doador Ouro", 1000, points),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRewardItem(BuildContext context, String title, int cost, int userPoints) {
    final canAfford = userPoints >= cost;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: canAfford ? Colors.green[100] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.card_giftcard, color: canAfford ? Colors.green[800] : Colors.grey),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$cost pontos"),
        trailing: ElevatedButton(
          onPressed: canAfford ? () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Funcionalidade de resgate em breve!")));
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text("Resgatar"),
        ),
      ),
    );
  }
}
