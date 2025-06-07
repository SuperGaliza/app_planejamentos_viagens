import 'package:flutter/material.dart';

// Tela para exibir os resultados da busca
class SearchResultsScreen extends StatelessWidget {
  // Variável para receber o texto que foi pesquisado
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados da Busca'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Você buscou por:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '"$searchQuery"',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4A90E2)),
              ),
              const SizedBox(height: 40),
              Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'Nenhum resultado encontrado no momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }
}