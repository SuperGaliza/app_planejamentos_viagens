import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../database/database_helper.dart';
import '../utils/session_manager.dart';
import '../JsonModels/viagem.dart'; 

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  static const LatLng _teresinaLatLng = LatLng(-5.093557, -42.825866);
  LatLng _posicaoInicial = _teresinaLatLng;
  Set<Marker> _marcadoresViagens = {};
  Marker? _marcadorLocalAtual;
  final dbHelper = DatabaseHelper();
  bool _carregando = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndAllMapData();
  }

  Future<void> _loadUserIdAndAllMapData() async {
    setState(() {
      _carregando = true;
    });

    _currentUserId = await SessionManager.getLoggedInUserId();
    
    // CORREÇÃO: Garante que o widget ainda existe após operações demoradas
    if (!mounted) return;

    if (_currentUserId != null) {
      _definirLocalizacaoMockadaETeresina();
      await _adicionarMarcadoresDasViagens();
      
      if (!mounted) return;

      if (_mapController != null) {
        _centralizarMapa();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado para ver o mapa de viagens.'),
        ),
      );
    }
    
    // CORREÇÃO: A verificação mais importante antes do setState final.
    if (mounted) {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _definirLocalizacaoMockadaETeresina() {
    setState(() {
      _posicaoInicial = _teresinaLatLng;
      _marcadorLocalAtual = Marker(
        markerId: const MarkerId("local_atual"),
        position: _teresinaLatLng,
        infoWindow: const InfoWindow(title: "Você está aqui (Teresina, PI)"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  Future<void> _adicionarMarcadoresDasViagens() async {
    if (_currentUserId == null) return;

    final viagens = await dbHelper.listarViagens(_currentUserId!);
    
    if (!mounted) return;

    final Set<Marker> novosMarcadores = {};

    for (var viagem in viagens) {
      try {
        List<geocoding.Location> locais = await geocoding.locationFromAddress(viagem.destino);
        
        if (!mounted) return;

        if (locais.isNotEmpty) {
          final coordenada = LatLng(locais[0].latitude, locais[0].longitude);
          novosMarcadores.add(
            Marker(
              markerId: MarkerId(viagem.titulo),
              position: coordenada,
              infoWindow: InfoWindow(
                title: viagem.titulo,
                snippet: '${viagem.destino} - R\$${viagem.orcamento.toStringAsFixed(2)}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(_getColorHue(viagem.corHex)),
            ),
          );
        }
      } catch (e) {
        debugPrint('Erro ao geocodificar "${viagem.destino}": $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível localizar no mapa: ${viagem.destino}'),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _marcadoresViagens = novosMarcadores;
      });
    }
  }

  double _getColorHue(String? corHex) {
    if (corHex == null || corHex.isEmpty) return BitmapDescriptor.hueOrange;
    try {
      final Color color = Color(int.parse(corHex));
      if (color.red > 200 && color.green < 100 && color.blue < 100) return BitmapDescriptor.hueRed;
      if (color.green > 200 && color.red < 100 && color.blue < 100) return BitmapDescriptor.hueGreen;
      if (color.blue > 200 && color.red < 100 && color.green < 100) return BitmapDescriptor.hueBlue;
      if (color.red > 200 && color.green > 200 && color.blue < 100) return BitmapDescriptor.hueYellow;
      if (color.red > 200 && color.blue > 200 && color.green < 100) return BitmapDescriptor.hueMagenta;
      return BitmapDescriptor.hueOrange;
    } catch (e) {
      return BitmapDescriptor.hueOrange;
    }
  }

  void _centralizarMapa() {
    final allMarkers = <Marker>{
      if (_marcadorLocalAtual != null) _marcadorLocalAtual!,
      ..._marcadoresViagens
    };

    if (allMarkers.isEmpty) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_teresinaLatLng, 12));
      return;
    }

    double minLat = allMarkers.first.position.latitude;
    double maxLat = allMarkers.first.position.latitude;
    double minLng = allMarkers.first.position.longitude;
    double maxLng = allMarkers.first.position.longitude;

    for (var marker in allMarkers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70,
      ),
    );
  }

  void _aoCriarMapa(GoogleMapController controller) {
    _mapController = controller;
    if (!_carregando) {
      _centralizarMapa();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: O AppBar foi removido aqui pois ele já existe na navegação principal da TravelScreen
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _posicaoInicial, zoom: 10),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: _aoCriarMapa,
            markers: {
              if (_marcadorLocalAtual != null) _marcadorLocalAtual!,
              ..._marcadoresViagens,
            },
          ),
          if (_carregando) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}