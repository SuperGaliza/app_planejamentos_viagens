import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_planejamentos_viagens/screens/travel_screen.dart';
import 'package:app_planejamentos_viagens/screens/profile_screen.dart';
import 'package:app_planejamentos_viagens/Authentication/login_screen.dart';
import 'package:app_planejamentos_viagens/utils/session_manager.dart';
import 'package:app_planejamentos_viagens/database/database_helper.dart'; 
import 'package:app_planejamentos_viagens/JsonModels/viagem.dart';     
import 'package:app_planejamentos_viagens/screens/detalhes_viagem_screen.dart'; 

// --- ESTRUTURA PRINCIPAL COM NAVEGAÇÃO ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final screens = [
    const SimpleHomeContent(),
    const TravelScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
            backgroundColor: Color(0xFF4A90E2),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight),
            label: 'Viagens',
            backgroundColor: Color(0xFFF77764),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
            backgroundColor: Color(0xFF4DB6AC),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DE CONTEÚDO DA HOME ---

class SimpleHomeContent extends StatefulWidget {
  const SimpleHomeContent({super.key});

  @override
  State<SimpleHomeContent> createState() => _SimpleHomeContentState();
}

class _SimpleHomeContentState extends State<SimpleHomeContent> {
  // Variáveis de estado para a nova funcionalidade
  Viagem? _nextTrip;
  bool _isLoading = true;
  final dbHelper = DatabaseHelper();

  // Dados para a dica e carrossel
  final List<String> _tips = [
    'Sempre salve uma cópia digital do seu passaporte na nuvem.',
    'Leve um carregador portátil para não ficar sem bateria.',
    'Aprenda algumas palavras básicas do idioma local. Isso abre portas!',
  ];
  late String _randomTip;

  // --- DADOS DO CARROSSEL COM BRASIL E NORUEGA DE VOLTA ---
  final List<Map<String, String>> _inspirationData = [
    {
      "image": "lib/assets/inspiration_japan.png",
      "text": "Explore a cultura do Japão"
    },
    {
      "image": "lib/assets/inspiration_italy.png",
      "text": "Descubra a beleza da Itália"
    },
    {
      "image": "lib/assets/inspiration_egypt.png",
      "text": "Desvende os mistérios do Egito"
    },
    {
      "image": "lib/assets/inspiration_brazil.png",
      "text": "Aventure-se pelas paisagens do Brasil"
    },
    {
      "image": "lib/assets/inspiration_norway.png",
      "text": "Contemple a aurora boreal na Noruega"
    },
  ];

  // Controllers
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData(); // Carrega todos os dados necessários

    _randomTip = _tips[Random().nextInt(_tips.length)];
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage = (_currentPage + 1) % _inspirationData.length;
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _loadData() async {
    final userId = await SessionManager.getLoggedInUserId();
    if (userId != null) {
      final trip = await dbHelper.getNextTrip(userId);
      if (mounted) {
        setState(() {
          _nextTrip = trip;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildTipOfTheDayCard(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Inspire-se para sua próxima viagem',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333)),
                ),
              ),
              const SizedBox(height: 16),
              _buildInspirationCarousel(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF4A90E2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bem-vindo!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                onPressed: () async {
                  await SessionManager.clearSession();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ))
              : _nextTrip != null
                  ? _buildNextTripCard(_nextTrip!)
                  : _buildNoTripCard(),
        ],
      ),
    );
  }

  // --- WIDGET PARA QUANDO HÁ UMA PRÓXIMA VIAGEM (AGORA CLICÁVEL) ---
  Widget _buildNextTripCard(Viagem trip) {
    // Lógica da contagem de dias corrigida
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDate = DateTime(trip.dataIda.year, trip.dataIda.month, trip.dataIda.day);
    final daysLeft = tripDate.difference(today).inDays;
    
    String countdownText;
    if (daysLeft > 1) {
      countdownText = 'Faltam $daysLeft dias!';
    } else if (daysLeft == 1) {
      countdownText = 'Falta 1 dia!';
    } else if (daysLeft == 0) {
      countdownText = 'É hoje! Boa viagem!';
    } else {
      countdownText = 'Viagem em andamento';
    }

    // --- MUDANÇA AQUI: Adicionando o InkWell para tornar o card clicável ---
    return InkWell(
      onTap: () {
        // Ação de navegar para a tela de detalhes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalhesViagemScreen(viagem: trip),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    countdownText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTripCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_road, color: Colors.white, size: 30),
          SizedBox(width: 16),
          Text(
            'Planeje sua próxima aventura!',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTipOfTheDayCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        color: Colors.blue.shade50,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: const Icon(Icons.lightbulb_outline,
              color: Colors.blue, size: 30),
          title: const Text('Dica de Viagem',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(_randomTip),
        ),
      ),
    );
  }

  Widget _buildInspirationCarousel() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _inspirationData.length,
        itemBuilder: (context, index) {
          final item = _inspirationData[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(item['image']!, fit: BoxFit.cover, 
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey.shade600));
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      item['text']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}