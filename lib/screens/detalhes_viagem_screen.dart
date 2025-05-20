import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/viagem.dart';

class DetalhesViagemScreen extends StatefulWidget {
  final Viagem viagem;

  const DetalhesViagemScreen({super.key, required this.viagem});

  @override
  State<DetalhesViagemScreen> createState() => _DetalhesViagemScreenState();
}

class _DetalhesViagemScreenState extends State<DetalhesViagemScreen> {
  final List<String> checklist = [
    'Passagens',
    'Documentos',
    'Roupas',
    'Protetor solar',
    'Carregadores',
  ];

  final Map<String, bool> checklistEstado = {};
  final List<String> galeria = [
    'https://picsum.photos/200?1',
    'https://picsum.photos/200?2',
    'https://picsum.photos/200?3',
  ];

  @override
  void initState() {
    super.initState();
    for (var item in checklist) {
      checklistEstado[item] = false;
    }
  }

  void _abrirMapa() {
    // Aqui você pode navegar para a tela com Google Maps se quiser
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Mapa do destino'),
            content: SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-5.0892, -42.8016), // Exemplo: Teresina
                  zoom: 12,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('destino'),
                    position: const LatLng(-5.0892, -42.8016),
                    infoWindow: InfoWindow(title: widget.viagem.destino),
                  ),
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _editarViagem() {
    // Lógica para ir para a tela de edição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição aqui')),
    );
  }

  void _agendarLembrete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lembrete agendado (simulado)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viagem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Viagem'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editarViagem),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: v.id?.toString() ?? v.hashCode.toString(),
              child: Material(
                color: Colors.transparent,
                child: Text(
                  v.titulo,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Destino: ${v.destino}', style: const TextStyle(fontSize: 18)),
            Text(
              'Orçamento: R\$ ${v.orcamento.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Período: ${v.dataIda.day}/${v.dataIda.month}/${v.dataIda.year} → '
              '${v.dataChegada.day}/${v.dataChegada.month}/${v.dataChegada.year}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Ver no mapa'),
              onPressed: _abrirMapa,
            ),

            const SizedBox(height: 24),
            const Text(
              'Observações:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Levar roupas leves, conferir previsão do tempo, lembrar de passaporte.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),
            const Text(
              'Galeria de Fotos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: galeria.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder:
                    (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        galeria[i],
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Checklist de Itens:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...checklist.map((item) {
              return CheckboxListTile(
                title: Text(item),
                value: checklistEstado[item],
                onChanged: (val) {
                  setState(() {
                    checklistEstado[item] = val ?? false;
                  });
                },
              );
            }),

            const SizedBox(height: 24),
            const Text(
              'Gastos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Hotel: R\$ 500,00\n• Alimentação: R\$ 300,00\n• Passeios: R\$ 200,00',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _agendarLembrete,
                icon: const Icon(Icons.notifications),
                label: const Text('Agendar lembrete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
