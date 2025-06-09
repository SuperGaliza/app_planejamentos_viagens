import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // <<< IMPORT CORRETO DO GOOGLE MAPS
import 'package:geocoding/geocoding.dart'
    as geocoding; // IMPORT DO GEOCÓDIGO COM ALIAS
import '../JsonModels/viagem.dart';
import 'add_viagem_screen.dart'; // Para navegar para a tela de edição
import '../database/database_helper.dart'; // Para atualizar a viagem

class DetalhesViagemScreen extends StatefulWidget {
  final Viagem viagem;

  const DetalhesViagemScreen({super.key, required this.viagem});

  @override
  State<DetalhesViagemScreen> createState() => _DetalhesViagemScreenState();
}

class _DetalhesViagemScreenState extends State<DetalhesViagemScreen> {
  // A lista de checklist agora será dinâmica, carregada da Viagem
  final List<Map<String, dynamic>> _dynamicChecklist = [];
  final TextEditingController _newChecklistItemController =
      TextEditingController(); // Controlador para adicionar novo item
  final dbHelper =
      DatabaseHelper(); // Instância do DatabaseHelper para salvar alterações

  // Itens padrão para checklist, usados se a viagem não tiver checklist salva
  static const List<String> _defaultChecklistItems = [
    'Passagens',
    'Documentos',
    'Roupas',
    'Protetor solar',
    'Carregadores',
    'Hospedagem',
    'Seguro Viagem',
    'Dinheiro/Cartões',
    'Medicamentos',
    'Adaptador de tomada',
  ];

  // Variáveis para a galeria
  final List<String> galeria = [
    'https://picsum.photos/200?1',
    'https://picsum.photos/200?2',
    'https://picsum.photos/200?3',
  ];

  LatLng? _destinoLatLng; // Para armazenar a LatLng do destino da viagem
  bool _isLoadingMap =
      true; // Para indicar que estamos buscando a LatLng do destino

  @override
  void initState() {
    super.initState();
    _loadChecklist(); // Carrega a checklist da viagem ou a padrão
    _geocodeDestination(); // Inicia a busca das coordenadas do destino
  }

  @override
  void dispose() {
    _newChecklistItemController.dispose();
    super.dispose();
  }

  // Carrega a checklist da viagem ou usa a padrão
  void _loadChecklist() {
    if (widget.viagem.checklistJson != null &&
        widget.viagem.checklistJson!.isNotEmpty) {
      try {
        _dynamicChecklist.addAll(widget.viagem.getChecklistAsMapList());
      } catch (e) {
        print("Erro ao carregar checklist JSON da viagem: $e");
        _initializeDefaultChecklist(); // Fallback para padrão em caso de erro
      }
    } else {
      _initializeDefaultChecklist();
    }
  }

  // Inicializa a checklist com itens padrão
  void _initializeDefaultChecklist() {
    _dynamicChecklist.addAll(
      _defaultChecklistItems.map((item) {
        return {'item': item, 'checked': false};
      }).toList(),
    );
  }

  // Salva a checklist atualizada no banco de dados
  void _saveChecklist() async {
    widget.viagem.setChecklistFromJsonList(_dynamicChecklist);
    await dbHelper.atualizarViagem(
      widget.viagem,
    ); // Atualiza a viagem no banco de dados
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Checklist atualizada!')));
    }
  }

  // Adiciona um novo item à checklist
  void _addChecklistItem() {
    final newItemText = _newChecklistItemController.text.trim();
    if (newItemText.isNotEmpty) {
      setState(() {
        _dynamicChecklist.add({'item': newItemText, 'checked': false});
        _newChecklistItemController.clear();
      });
      _saveChecklist(); // Salva no banco de dados
    }
  }

  // Remove um item da checklist
  void _removeChecklistItem(int index) {
    setState(() {
      _dynamicChecklist.removeAt(index);
    });
    _saveChecklist(); // Salva no banco de dados
  }

  // Toggle do status de um item da checklist
  void _toggleChecklistItem(int index, bool? value) {
    setState(() {
      _dynamicChecklist[index]['checked'] = value ?? false;
    });
    _saveChecklist(); // Salva no banco de dados
  }

  Future<void> _geocodeDestination() async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(
        widget.viagem.destino,
      );
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _destinoLatLng = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _isLoadingMap = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingMap = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível encontrar o destino no mapa.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao geocodificar "${widget.viagem.destino}": $e');
      if (mounted) {
        setState(() {
          _isLoadingMap = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar o mapa do destino: $e')),
        );
      }
    }
  }

  void _abrirMapaDoDestino() {
    if (_destinoLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localização do destino não disponível.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Mapa de ${widget.viagem.destino}'),
            content: SizedBox(
              height: 250,
              width: MediaQuery.of(context).size.width * 0.8,
              child:
                  _isLoadingMap
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _destinoLatLng!,
                          zoom: 12,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('destino'),
                            position: _destinoLatLng!,
                            infoWindow: InfoWindow(
                              title: widget.viagem.destino,
                            ),
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

  void _editarViagem(BuildContext context) async {
    final updatedViagem = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddViagemScreen(
              viagemExistente: widget.viagem,
              viagensExistentes: [],
              userId: widget.viagem.userId,
            ),
      ),
    );

    if (updatedViagem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem editada. Recarregando detalhes...'),
        ),
      );
    }
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editarViagem(context),
          ),
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
              'Período: ${v.dataIda.day}/${v.dataIda.month}/${v.dataIda.year} → '
              '${v.dataChegada.day}/${v.dataChegada.month}/${v.dataChegada.year}',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 16),
            const Text(
              'Orçamento Detalhado:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Total: R\$ ${v.orcamento.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '• Hospedagem: R\$ ${v.hospedagem.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '• Transporte: R\$ ${v.transporte.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '• Alimentação: R\$ ${v.alimentacao.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '• Despesas Diversas: R\$ ${v.despesasDiversas.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '• Passeios: R\$ ${v.passeios.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Ver no mapa do destino'),
              onPressed: _abrirMapaDoDestino,
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dynamicChecklist.length,
              itemBuilder: (context, index) {
                final item = _dynamicChecklist[index];
                return Dismissible(
                  key: Key(item['item'].toString() + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _removeChecklistItem(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item['item']} removido da checklist'),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: CheckboxListTile(
                    title: Text(item['item']),
                    value: item['checked'],
                    onChanged: (val) => _toggleChecklistItem(index, val),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newChecklistItemController,
                      decoration: const InputDecoration(
                        labelText: 'Novo item da checklist',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addChecklistItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addChecklistItem,
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
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
