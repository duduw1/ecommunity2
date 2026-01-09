import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:url_launcher/url_launcher.dart';

class RecyclingMapScreen extends StatefulWidget {
  const RecyclingMapScreen({super.key});

  @override
  State<RecyclingMapScreen> createState() => _RecyclingMapScreenState();
}

class _RecyclingMapScreenState extends State<RecyclingMapScreen> {
  GoogleMapController? mapController;
  LatLng? _currentPosition;

  final Set<Marker> _markers = {};
  final _firestore = FirebaseFirestore.instance;
  final _geo = GeoFlutterFire();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    // ... código de permissão
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serviço de localização desativado.')));
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de localização negada.')));
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão negada permanentemente.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _animateToUserLocation();
      _queryNearbyPoints();
    } catch (e) {
      setState(() => _isLoading = false);
      print("Erro ao obter localização: $e");
    }
  }

  void _queryNearbyPoints() {
    if (_currentPosition == null) return;

    GeoFirePoint center = _geo.point(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude);
    var collectionRef = _firestore.collection('collection_points');

    double radius = 15;
    String field = 'position';

    Stream<List<DocumentSnapshot>> stream = _geo.collection(collectionRef: collectionRef).within(center: center, radius: radius, field: field);

    stream.listen((List<DocumentSnapshot> documentList) {
      _updateMarkers(documentList);
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    final tempMarkers = <Marker>{};
    for (var doc in documentList) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint point = data['position']['geopoint'];

        tempMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(point.latitude, point.longitude),
            infoWindow: InfoWindow(
              title: data['name'],
              snippet: 'Toque aqui para traçar rota', // Snippet atualizado
              onTap: () => _launchMapsUrl(point.latitude, point.longitude), // Ação de toque
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      } catch (e) {
        print("Erro ao processar o ponto ${doc.id}: $e");
      }
    }
    setState(() {
      _markers.clear();
      _markers.addAll(tempMarkers);
    });
  }
  
  // Função para abrir o Google Maps
  void _launchMapsUrl(double lat, double lng) async {
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback para abrir no navegador se o app não estiver instalado
      final Uri webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
       if (await canLaunchUrl(webUrl)) {
         await launchUrl(webUrl);
       } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o mapa.')));
       }
    }
  }

  void _animateToUserLocation() {
     if (mapController != null && _currentPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 14.0),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _animateToUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pontos de Coleta Próximos")),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(-19.9213, -43.9386),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
        ],
      ),
    );
  }
}
