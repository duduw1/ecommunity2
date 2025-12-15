import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecyclingMapScreen extends StatefulWidget {
  const RecyclingMapScreen({super.key});

  @override
  State<RecyclingMapScreen> createState() => _RecyclingMapScreenState();
}

class _RecyclingMapScreenState extends State<RecyclingMapScreen> {
  late GoogleMapController mapController;

  // Posição inicial (Ex: Centro de São Paulo - ajuste conforme necessário)
  final LatLng _center = const LatLng(-23.550520, -46.633308);

  // Marcadores dos pontos de coleta
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    // Dados simulados de pontos de coleta
    final List<Map<String, dynamic>> collectionPoints = [
      {
        'id': '1',
        'name': 'Ecoponto Central',
        'lat': -23.550520,
        'lng': -46.633308,
        'types': 'Vidro, Papel',
      },
      {
        'id': '2',
        'name': 'Cooperativa Recicla+',
        'lat': -23.555520,
        'lng': -46.638308,
        'types': 'Eletrônicos',
      },
      {
        'id': '3',
        'name': 'Ponto Verde',
        'lat': -23.545520,
        'lng': -46.628308,
        'types': 'Óleo, Pilhas',
      },
    ];

    for (var point in collectionPoints) {
      _markers.add(
        Marker(
          markerId: MarkerId(point['id']),
          position: LatLng(point['lat'], point['lng']),
          infoWindow: InfoWindow(
            title: point['name'],
            snippet: point['types'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Marcador verde
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pontos de Coleta")),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true, // Requer permissão de localização no AndroidManifest
            myLocationButtonEnabled: true,
          ),
          
          // Legenda flutuante
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Toque nos marcadores verdes para ver detalhes do ponto de coleta.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
