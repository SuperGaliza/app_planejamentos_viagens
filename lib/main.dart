import 'package:app_planejamentos_viagens/Authentication/login_screen.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:app_planejamentos_viagens/screens/home_screen.dart'; // já existente

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planejador de Viagens',
      debugShowCheckedModeBanner: false, // Remove o banner DEBUG
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        //'/cadastro': (context) => const CadastroScreen(),
        '/home': (context) => const HomeScreen(), // já existente
      },
    );
  }
}
