import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../database/database_helper.dart';
import '../utils/session_manager.dart'; // <<< NOVO IMPORT

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
  int? _currentUserId; // <<< NOVO CAMPO: Para armazenar o ID do usuário logado

  @override
  void initState() {
    super.initState();
    _loadUserIdAndAllMapData(); // Inicia o carregamento do userId e dos dados do mapa
  }

  // Novo método para carregar o userId e depois todos os dados do mapa
  Future<void> _loadUserIdAndAllMapData() async {
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (!mounted) return;

    if (_currentUserId != null) {
      // Se há um userId, proceed to load map data
      await _carregarTudo();
    } else {
      // Caso não haja userId logado, exibe uma mensagem e para o carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado para ver o mapa de viagens.'),
        ),
      );
      setState(() {
        _carregando = false;
      });
      // Opcional: Redirecionar para a tela de login
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => const LoginScreen()),
      //   (Route<dynamic> route) => false,
      // );
    }
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _carregando = true;
    });

    try {
      await _obterLocalizacaoAtual();
      await _adicionarMarcadoresDasViagens(); // Este método agora usará _currentUserId
      if (_mapController != null) {
        _centralizarMapa();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar o mapa: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _obterLocalizacaoAtual() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço de localização desativado.')),
        );
      }
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada.')),
        );
        return;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada permanentemente.'),
          ),
        );
      }
      return;
    }

    try {
      final posicao = await Geolocator.getCurrentPosition();
      final localAtual = LatLng(posicao.latitude, posicao.longitude);

      if (mounted) {
        setState(() {
          _posicaoInicial = localAtual;
          _marcadorLocalAtual = Marker(
            markerId: const MarkerId("local_atual"),
            position: localAtual,
            infoWindow: const InfoWindow(title: "Você está aqui"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização atual: $e')),
        );
      }
    }
  }

  Future<void> _adicionarMarcadoresDasViagens() async {
    // Garante que temos um userId antes de tentar listar as viagens
    if (_currentUserId == null) return;

    // AQUI ESTÁ A MUDANÇA PRINCIPAL: Passa _currentUserId para listarViagens
    final viagens = await dbHelper.listarViagens(
      _currentUserId!,
    ); // <<< CORREÇÃO AQUI
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

  void _centralizarMapa() {
    final allMarkers = <Marker>{};
    if (_marcadorLocalAtual != null) {
      allMarkers.add(_marcadorLocalAtual!);
    }
    allMarkers.addAll(_marcadoresViagens);

    if (allMarkers.isEmpty) return; // Nenhuma marcação para centralizar

    // Calcular os limites para incluir todos os marcadores
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

    // Adiciona um pequeno padding para que os marcadores não fiquem na borda
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  void _aoCriarMapa(GoogleMapController controller) {
    _mapController = controller;
    // Tenta centralizar o mapa uma vez que ele está pronto e os dados já podem ter sido carregados
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
          // Exibe o indicador de carregamento
          if (_carregando) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
