import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../database/database_helper.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng _posicaoInicial = const LatLng(-23.55052, -46.633308); // São Paulo
  Set<Marker> _marcadoresViagens = {};
  Marker? _marcadorLocalAtual;
  final dbHelper = DatabaseHelper();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _carregando = true;
    });

    try {
      await _obterLocalizacaoAtual();
      await _adicionarMarcadoresDasViagens();
      if (_mapController != null) {
        _centralizarMapa();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar o mapa: $e')));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _obterLocalizacaoAtual() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço de localização desativado.')),
      );
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) return;
    }

    if (permissao == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de localização negada permanentemente.'),
        ),
      );
      return;
    }

    final posicao = await Geolocator.getCurrentPosition();
    final localAtual = LatLng(posicao.latitude, posicao.longitude);

    setState(() {
      _posicaoInicial = localAtual;
      _marcadorLocalAtual = Marker(
        markerId: const MarkerId("local_atual"),
        position: localAtual,
        infoWindow: const InfoWindow(title: "Você está aqui"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  Future<void> _adicionarMarcadoresDasViagens() async {
    final viagens = await dbHelper.listarViagens();
    final Set<Marker> novosMarcadores = {};

    for (var viagem in viagens) {
      try {
        List<Location> locais = await locationFromAddress(viagem.destino);
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
            ),
          );
        }
      } catch (e) {
        debugPrint('Erro ao geocodificar "${viagem.destino}": $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível localizar: ${viagem.destino}'),
          ),
        );
      }
    }

    setState(() {
      _marcadoresViagens = novosMarcadores;
    });
  }

  void _centralizarMapa() {
    if (_marcadorLocalAtual == null && _marcadoresViagens.isEmpty) return;

    final todosMarcadores = <Marker>{};
    if (_marcadorLocalAtual != null) todosMarcadores.add(_marcadorLocalAtual!);
    todosMarcadores.addAll(_marcadoresViagens);

    double minLat = todosMarcadores.first.position.latitude;
    double maxLat = todosMarcadores.first.position.latitude;
    double minLng = todosMarcadores.first.position.longitude;
    double maxLng = todosMarcadores.first.position.longitude;

    for (var marker in todosMarcadores) {
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
              target: _posicaoInicial,
              zoom: 10,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
