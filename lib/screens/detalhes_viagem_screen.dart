import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../JsonModels/viagem.dart';
import '../database/database_helper.dart';

class DetalhesViagemScreen extends StatefulWidget {
  final Viagem viagem;

  const DetalhesViagemScreen({super.key, required this.viagem});

  @override
  State<DetalhesViagemScreen> createState() => _DetalhesViagemScreenState();
}

class _DetalhesViagemScreenState extends State<DetalhesViagemScreen> {
  late Viagem _currentViagem;
  final dbHelper = DatabaseHelper();
  final _newChecklistItemController = TextEditingController();

  // Uma lista de checklist padrão, mais focada em planejamento
  static const List<String> _defaultChecklistItems = [
    'Confirmar passagens',
    'Reservar hospedagem',
    'Verificar passaporte e vistos',
    'Comprar moeda estrangeira',
    'Fazer as malas',
    'Contratar seguro viagem',
    'Baixar mapas offline',
  ];

  @override
  void initState() {
    super.initState();
    _currentViagem = widget.viagem;
    _loadChecklist(); // Carrega o checklist da viagem ou o padrão
  }

  @override
  void dispose() {
    _newChecklistItemController.dispose();
    super.dispose();
  }

  // Se a viagem não tiver um checklist, cria um com os itens padrão
  void _loadChecklist() {
    if (_currentViagem.checklistJson == null || _currentViagem.checklistJson!.isEmpty) {
      final defaultChecklist = _defaultChecklistItems.map((item) => {'item': item, 'checked': false}).toList();
      _currentViagem.setChecklistFromJsonList(defaultChecklist);
      _updateViagemNoBanco(); // Salva o checklist inicial no banco
    }
  }

  // Função central para salvar qualquer alteração no banco de dados
  Future<void> _updateViagemNoBanco() async {
    await dbHelper.atualizarViagem(_currentViagem);
  }

  // Adiciona um novo item ao checklist
  void _addChecklistItem() {
    final text = _newChecklistItemController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        final checklist = _currentViagem.getChecklistAsMapList();
        checklist.add({'item': text, 'checked': false});
        _currentViagem.setChecklistFromJsonList(checklist);
      });
      _newChecklistItemController.clear();
      _updateViagemNoBanco(); // Salva a alteração
      FocusScope.of(context).unfocus(); // Esconde o teclado
    }
  }

  // Marca ou desmarca um item do checklist
  void _toggleChecklistItem(int index, bool? isChecked) {
    setState(() {
      final checklist = _currentViagem.getChecklistAsMapList();
      checklist[index]['checked'] = isChecked ?? false;
      _currentViagem.setChecklistFromJsonList(checklist);
    });
    _updateViagemNoBanco();
  }

  // **NOVO**: Remove um item do checklist
  void _removeChecklistItem(int index) {
    setState(() {
      final checklist = _currentViagem.getChecklistAsMapList();
      checklist.removeAt(index);
      _currentViagem.setChecklistFromJsonList(checklist);
    });
    _updateViagemNoBanco();
  }

  // Adiciona uma nova imagem à galeria
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null && mounted) {
      setState(() {
        final gallery = _currentViagem.getGalleryImagePaths();
        gallery.add(image.path);
        _currentViagem.setGalleryImagePaths(gallery);
      });
      _updateViagemNoBanco();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_currentViagem.corHex != null ? int.parse(_currentViagem.corHex!) : Theme.of(context).primaryColor.value);
    final gallery = _currentViagem.getGalleryImagePaths();
    final checklist = _currentViagem.getChecklistAsMapList();
    final formatadorData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_currentViagem.titulo),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      // Usamos um SingleChildScrollView para a tela poder rolar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Cabeçalho com imagem e informações ---
            if (gallery.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(gallery.first),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: Text(_currentViagem.destino),
                    ),
                    ListTile(
                      leading: const Icon(Icons.date_range, color: Colors.blue),
                      title: Text('${formatadorData.format(_currentViagem.dataIda)}  a  ${formatadorData.format(_currentViagem.dataChegada)}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Seção de Orçamento ---
            const Text('Orçamento Detalhado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _buildBudgetItem('Hospedagem', _currentViagem.hospedagem),
                  _buildBudgetItem('Transporte', _currentViagem.transporte),
                  _buildBudgetItem('Alimentação', _currentViagem.alimentacao),
                  _buildBudgetItem('Passeios', _currentViagem.passeios),
                  _buildBudgetItem('Despesas Diversas', _currentViagem.despesasDiversas),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.wallet, color: Colors.green, size: 28),
                    title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      'R\$ ${_currentViagem.orcamento.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Seção do Checklist ---
            const Text('Checklist da Viagem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // ListView.builder é mais eficiente para listas
                    ListView.builder(
                      shrinkWrap: true, // Necessário dentro de uma Column
                      physics: const NeverScrollableScrollPhysics(), // Desabilita o scroll da lista interna
                      itemCount: checklist.length,
                      itemBuilder: (context, index) {
                        final item = checklist[index];
                        return CheckboxListTile(
                          title: Text(item['item']),
                          value: item['checked'],
                          onChanged: (bool? value) {
                            _toggleChecklistItem(index, value);
                          },
                          // **NOVO**: Botão de exclusão para cada item
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              _removeChecklistItem(index);
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    // Campo para adicionar novo item
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newChecklistItemController,
                              decoration: const InputDecoration(
                                hintText: 'Adicionar novo item...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: _addChecklistItem,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Seção da Galeria ---
            const Text('Galeria de Fotos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 fotos por linha
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: gallery.length + 1, // +1 para o botão de adicionar
                  itemBuilder: (context, index) {
                    // O último item da grade é o botão de adicionar
                    if (index == gallery.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                        ),
                      );
                    }
                    // Os outros itens são as fotos da galeria
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(gallery[index]), fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar os itens da lista de orçamento
  Widget _buildBudgetItem(String label, double value) {
    return ListTile(
      title: Text(label),
      trailing: Text('R\$ ${value.toStringAsFixed(2)}'),
    );
  }
}