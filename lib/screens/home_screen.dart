import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_planejamentos_viagens/screens/travel_screen.dart';
import 'package:app_planejamentos_viagens/screens/profile_screen.dart';
import 'package:app_planejamentos_viagens/screens/search_results_screen.dart';
import 'package:app_planejamentos_viagens/Authentication/login_screen.dart';
import 'package:app_planejamentos_viagens/utils/session_manager.dart';

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
    const TravelScreen(), // Mantendo comentário da outra versão
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

// --- WIDGET DE CONTEÚDO DA HOME (COM AS SUAS ALTERAÇÕES) ---
class SimpleHomeContent extends StatefulWidget {
  const SimpleHomeContent({super.key});

  @override
  State<SimpleHomeContent> createState() => _SimpleHomeContentState();
}

class _SimpleHomeContentState extends State<SimpleHomeContent> {
  final _searchController = TextEditingController();

  // --- DADOS PARA A DICA DO DIA ---
  final List<String> _tips = [
    'Sempre salve uma cópia digital do seu passaporte na nuvem.',
    'Leve um carregador portátil para não ficar sem bateria.',
    'Aprenda algumas palavras básicas do idioma local. Isso abre portas!',
    'Experimente a comida de rua para uma autêntica experiência cultural.',
    'Use sapatos confortáveis. Você vai andar mais do que imagina!',
  ];
  late String _randomTip;

  // --- DADOS PARA O CARROSSEL DE IMAGENS ---
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

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _randomTip = _tips[Random().nextInt(_tips.length)];
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _inspirationData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
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
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInspirationCarousel(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                onPressed: () async {
                  await SessionManager.clearSession();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SearchResultsScreen(searchQuery: value),
                    ),
                  );
                }
              },
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Para onde vamos?',
                border: InputBorder.none,
              ),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.lightbulb_outline,
            color: Colors.blue,
            size: 30,
          ),
          title: const Text(
            'Dica de Viagem',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  Image.asset(
                    item['image']!,
                    fit: BoxFit.cover,
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