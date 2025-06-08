import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_planejamentos_viagens/screens/travel_screen.dart';
import 'package:app_planejamentos_viagens/screens/profile_screen.dart';
import 'package:app_planejamentos_viagens/screens/placeholder_screen.dart';
import 'package:app_planejamentos_viagens/screens/search_results_screen.dart';

// --- TELA PRINCIPAL (HOME) ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final screens = [
    const SimpleHomeContent(),
    TravelScreen(),
    const ProfileScreen(), // Usando a nova ProfileScreen
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
            label: 'Home',
            backgroundColor: Color(0xFF4A90E2),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight),
            label: 'Travel',
            backgroundColor: Color(0xFFF77764),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            // Usando a nova cor verde-azulado mais suave
            backgroundColor: Color(0xFF4DB6AC),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DE CONTEÚDO DA HOME ---
// Este é o "recheio" da sua aba Home, com todas as funcionalidades.

class SimpleHomeContent extends StatefulWidget {
  const SimpleHomeContent({super.key});

  @override
  State<SimpleHomeContent> createState() => _SimpleHomeContentState();
}

class _SimpleHomeContentState extends State<SimpleHomeContent> {
  final _searchController = TextEditingController();
  final List<String> _tips = [
    'Sempre salve uma cópia digital do seu passaporte na nuvem.',
    'Leve um carregador portátil para não ficar sem bateria.',
    'Aprenda algumas palavras básicas do idioma local. Isso abre portas!',
    'Experimente a comida de rua para uma autêntica experiência cultural.',
    'Use sapatos confortáveis. Você vai andar mais do que imagina!',
  ];

  late String _randomTip;

  @override
  void initState() {
    super.initState();
    _randomTip = _tips[Random().nextInt(_tips.length)];
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            const SizedBox(height: 30),
            _buildCategoryButtons(context),
            const SizedBox(height: 30),
            _buildTipOfTheDayCard(),
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
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  // Esta ação agora deve estar na tela de Perfil,
                  // mas mantemos aqui caso você queira ter em ambos os lugares.
                  // A forma mais segura de sair é pela tela de Perfil.
                  Navigator.of(context).pop();
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

  Widget _buildCategoryButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategoryItem(context, icon: Icons.flight_takeoff, label: 'Voos'),
        _buildCategoryItem(context, icon: Icons.hotel, label: 'Hotéis'),
        _buildCategoryItem(context, icon: Icons.local_offer, label: 'Ofertas'),
        _buildCategoryItem(context, icon: Icons.directions_car, label: 'Carros'),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context,
      {required IconData icon, required String label}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlaceholderScreen(title: label)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4A90E2), size: 36),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTipOfTheDayCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dica do Dia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline,
                  color: Colors.blue, size: 30),
              title: const Text(
                'Dica de Viagem',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_randomTip),
            ),
          ),
        ],
      ),
    );
  }
}