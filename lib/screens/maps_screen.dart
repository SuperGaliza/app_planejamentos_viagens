import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart'; // <<< REMOVER ESTE IMPORT
import 'package:geocoding/geocoding.dart'
    as geocoding; // <<< MANTER E ALIAS PARA EVITAR CONFLITO
import '../database/database_helper.dart';
import '../utils/session_manager.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  // Coordenadas de Teresina, PI
  static const LatLng _teresinaLatLng = LatLng(
    -5.093557,
    -42.825866,
  ); // Teresina, PI

  // Define Teresina como posição inicial padrão para o mapa
  LatLng _posicaoInicial = _teresinaLatLng;
  Set<Marker> _marcadoresViagens = {};
  Marker?
  _marcadorLocalAtual; // O marcador da localização "atual" (Teresina mockada)
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
    if (!mounted) return;

    if (_currentUserId != null) {
      // Chama o método para definir a localização fixa de Teresina
      _definirLocalizacaoMockadaETeresina();
      // Em seguida, adiciona os marcadores das viagens
      await _adicionarMarcadoresDasViagens();
      if (_mapController != null) {
        _centralizarMapa();
      }
    } else {
      // Caso não haja userId logado, exibe uma mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado para ver o mapa de viagens.'),
        ),
      );
    }
    setState(() {
      _carregando = false;
    });
  }

  // NOVO MÉTODO: Define a localização atual como Teresina, PI e cria o marcador
  void _definirLocalizacaoMockadaETeresina() {
    setState(() {
      _posicaoInicial =
          _teresinaLatLng; // Garante que o mapa inicializa em Teresina
      _marcadorLocalAtual = Marker(
        markerId: const MarkerId("local_atual"),
        position: _teresinaLatLng,
        infoWindow: const InfoWindow(title: "Você está aqui (Teresina, PI)"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  // Este método adiciona os marcadores das viagens do usuário
  Future<void> _adicionarMarcadoresDasViagens() async {
    if (_currentUserId == null) return;

    final viagens = await dbHelper.listarViagens(_currentUserId!);
    final Set<Marker> novosMarcadores = {};

    for (var viagem in viagens) {
      try {
        // Usa geocoding.locationFromAddress para converter o destino (string) em coordenadas
        List<geocoding.Location> locais = await geocoding.locationFromAddress(
          viagem.destino,
        );
        if (locais.isNotEmpty) {
          final coordenada = LatLng(locais[0].latitude, locais[0].longitude);
          novosMarcadores.add(
            Marker(
              markerId: MarkerId(viagem.titulo),
              position: coordenada,
              infoWindow: InfoWindow(
                title: viagem.titulo,
                snippet:
                    '${viagem.destino} - R\$${viagem.orcamento.toStringAsFixed(2)}',
              ),
              // Opcional: Usar a cor da viagem para o marcador
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getColorHue(viagem.corHex),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Erro ao geocodificar "${viagem.destino}": $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Não foi possível localizar no mapa: ${viagem.destino}',
              ),
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

  // Função auxiliar para tentar mapear a cor da viagem para o HUE do marcador
  double _getColorHue(String? corHex) {
    if (corHex != null && corHex.isNotEmpty) {
      try {
        final int colorValue = int.parse(corHex);
        final Color color = Color(colorValue);

        // Mapeamento simplificado de cores para HUEs conhecidos do Google Maps
        if (color.red > 200 && color.green < 100 && color.blue < 100)
          return BitmapDescriptor.hueRed;
        if (color.green > 200 && color.red < 100 && color.blue < 100)
          return BitmapDescriptor.hueGreen;
        if (color.blue > 200 && color.red < 100 && color.green < 100)
          return BitmapDescriptor.hueBlue;
        if (color.red > 200 && color.green > 200 && color.blue < 100)
          return BitmapDescriptor.hueYellow;
        if (color.red < 100 && color.blue > 200 && color.green < 100)
          return BitmapDescriptor.hueViolet;
        if (color.red > 200 && color.blue > 200 && color.green < 100)
          return BitmapDescriptor.hueMagenta; // Ou violet

        // Fallback para um padrão se a cor não for "pura" ou não mapeada
        return BitmapDescriptor.hueOrange;
      } catch (e) {
        return BitmapDescriptor
            .hueOrange; // Fallback em caso de erro de parsing
      }
    }
    return BitmapDescriptor.hueOrange; // Padrão se corHex for nulo/vazio
  }

  void _centralizarMapa() {
    final allMarkers = <Marker>{};
    if (_marcadorLocalAtual != null) {
      allMarkers.add(_marcadorLocalAtual!);
    }
    allMarkers.addAll(_marcadoresViagens);

    // Se não há outros marcadores, apenas centralize em Teresina com um zoom razoável
    if (allMarkers.isEmpty) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_teresinaLatLng, 12),
      );
      return;
    }

    double minLat = allMarkers.first.position.latitude;
    double maxLat = allMarkers.first.position.latitude;
    double minLng = allMarkers.first.position.longitude;
    double maxLng = allMarkers.first.position.longitude;

    for (var marker in allMarkers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
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
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _posicaoInicial, // Mapa inicializa em Teresina
              zoom: 10,
            ),
            myLocationEnabled:
                false, // Desabilita o ponto azul da localização real
            myLocationButtonEnabled:
                false, // Desabilita o botão de centralizar na localização real
            onMapCreated: _aoCriarMapa,
            markers: {
              if (_marcadorLocalAtual != null) _marcadorLocalAtual!,
              ..._marcadoresViagens,
            },
          ),
          // Exibe o indicador de carregamento
          if (_carregando) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
