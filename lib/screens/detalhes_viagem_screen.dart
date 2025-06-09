// lib/screens/detalhes_viagem_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../JsonModels/viagem.dart';
import 'add_viagem_screen.dart';
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
  
  // Controllers
  final _newChecklistItemController = TextEditingController();
  final _notesController = TextEditingController();

  // Estado
  LatLng? _destinoLatLng;
  bool _isLoadingMap = true;
  bool _isEditingNotes = false;
  bool _isPickingImage = false;

  static const List<String> _defaultChecklistItems = [
    'Passagens', 'Documentos', 'Roupas', 'Protetor solar', 'Carregadores',
    'Hospedagem', 'Seguro Viagem', 'Dinheiro/Cartões', 'Medicamentos', 'Adaptador de tomada'
  ];

  @override
  void initState() {
    super.initState();
    _currentViagem = widget.viagem;
    _notesController.text = _currentViagem.notes ?? '';
    _loadChecklist();
    _geocodeDestination();
  }

  @override
  void dispose() {
    _newChecklistItemController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadChecklist() {
    if (_currentViagem.checklistJson == null || _currentViagem.checklistJson!.isEmpty) {
      final defaultChecklist = _defaultChecklistItems.map((item) => {'item': item, 'checked': false}).toList();
      _currentViagem.setChecklistFromJsonList(defaultChecklist);
    }
  }

  Future<void> _updateViagem() async {
    await dbHelper.atualizarViagem(_currentViagem);
  }

  Future<void> _geocodeDestination() async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(_currentViagem.destino);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _destinoLatLng = LatLng(locations.first.latitude, locations.first.longitude);
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  void _addChecklistItem() {
    final text = _newChecklistItemController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        final checklist = _currentViagem.getChecklistAsMapList();
        checklist.add({'item': text, 'checked': false});
        _currentViagem.setChecklistFromJsonList(checklist);
      });
      _newChecklistItemController.clear();
      _updateViagem();
    }
  }

  void _toggleChecklistItem(int index, bool selected) {
    setState(() {
      final checklist = _currentViagem.getChecklistAsMapList();
      checklist[index]['checked'] = selected;
      _currentViagem.setChecklistFromJsonList(checklist);
    });
    _updateViagem();
  }

  Future<void> _pickImage() async {
    // Se a função já estiver rodando, não faz nada.
    if (_isPickingImage) return;

    try {
      // "Levanta a trava" para bloquear novas chamadas
      setState(() => _isPickingImage = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (image != null && mounted) {
        setState(() {
          final gallery = _currentViagem.getGalleryImagePaths();
          gallery.add(image.path);
          _currentViagem.setGalleryImagePaths(gallery);
        });
        _updateViagem();
      }
    } finally {
      // "Abaixa a trava" ao final, não importa se deu certo ou errado
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final gallery = _currentViagem.getGalleryImagePaths();
      gallery.removeAt(index);
      _currentViagem.setGalleryImagePaths(gallery);
    });
    _updateViagem();
  }
  
  void _saveNotes() {
    setState(() {
      _currentViagem.notes = _notesController.text;
      _isEditingNotes = false;
    });
    _updateViagem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoSection(),
                const SizedBox(height: 24),
                _buildBudgetSection(),
                const SizedBox(height: 24),
                _buildNotesSection(),
                const SizedBox(height: 24),
                _buildGallerySection(),
                const SizedBox(height: 24),
                _buildChecklistSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final color = Color(_currentViagem.corHex != null ? int.parse(_currentViagem.corHex!) : Theme.of(context).primaryColor.value);
    final gallery = _currentViagem.getGalleryImagePaths();
    
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      stretch: true,
      backgroundColor: color,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(_currentViagem.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10)])),
        background: gallery.isNotEmpty
            ? Image.file(File(gallery.first), fit: BoxFit.cover, color: Colors.black.withOpacity(0.3), colorBlendMode: BlendMode.darken)
            : Container(color: color),
      ),
    );
  }

  Widget _buildInfoSection() {
    final formatadorData = DateFormat('dd/MM/yyyy');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [Icon(Icons.location_on_outlined, color: Colors.grey[600]), const SizedBox(width: 8), Text(_currentViagem.destino, style: const TextStyle(fontSize: 16))]),
            const SizedBox(height: 12),
            Row(children: [Icon(Icons.calendar_today_outlined, color: Colors.grey[600]), const SizedBox(width: 8), Text('${formatadorData.format(_currentViagem.dataIda)} → ${formatadorData.format(_currentViagem.dataChegada)}', style: const TextStyle(fontSize: 16))]),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return _buildSectionCard(
      icon: Icons.wallet_outlined,
      title: 'Orçamento',
      child: Column(
        children: [
          _budgetItem('Total', _currentViagem.orcamento, isTotal: true),
          const Divider(),
          _budgetItem('Hospedagem', _currentViagem.hospedagem),
          _budgetItem('Transporte', _currentViagem.transporte),
          _budgetItem('Alimentação', _currentViagem.alimentacao),
          _budgetItem('Passeios', _currentViagem.passeios),
          _budgetItem('Despesas Diversas', _currentViagem.despesasDiversas),
        ],
      )
    );
  }

  Widget _budgetItem(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text('R\$ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
  
  Widget _buildNotesSection() {
    return _buildSectionCard(
      icon: Icons.edit_note_outlined,
      title: 'Observações',
      child: Column(
        children: [
          _isEditingNotes
              ? TextField(
                  controller: _notesController,
                  maxLines: 5,
                  autofocus: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Digite suas anotações...'),
                )
              : Text(_notesController.text.isEmpty ? 'Nenhuma observação adicionada.' : _notesController.text),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (_isEditingNotes) {
                  _saveNotes();
                } else {
                  setState(() => _isEditingNotes = true);
                }
              },
              child: Text(_isEditingNotes ? 'Salvar' : 'Editar'),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildGallerySection() {
    final gallery = _currentViagem.getGalleryImagePaths();
    return _buildSectionCard(
      icon: Icons.photo_camera_back_outlined,
      title: 'Galeria de Fotos',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: gallery.length + 1,
        itemBuilder: (context, index) {
          if (index == gallery.length) {
            return InkWell(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(gallery[index]), fit: BoxFit.cover),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    child: const CircleAvatar(backgroundColor: Colors.black54, radius: 12, child: Icon(Icons.close, color: Colors.white, size: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChecklistSection() {
    final checklist = _currentViagem.getChecklistAsMapList();
    return _buildSectionCard(
      icon: Icons.check_circle_outline,
      title: 'Checklist de Itens',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checklist.isEmpty) const Text('Nenhum item na checklist.'),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: List<Widget>.generate(checklist.length, (index) {
              final item = checklist[index];
              return FilterChip(
                label: Text(item['item']),
                selected: item['checked'],
                onSelected: (selected) => _toggleChecklistItem(index, selected),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newChecklistItemController,
                  decoration: const InputDecoration(hintText: 'Novo item...', border: InputBorder.none, contentPadding: EdgeInsets.all(8)),
                  onSubmitted: (_) => _addChecklistItem(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                onPressed: _addChecklistItem,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}