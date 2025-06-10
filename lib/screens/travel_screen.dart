import 'package:flutter/material.dart';
import '../JsonModels/viagem.dart';
import '../database/database_helper.dart';
import '../utils/session_manager.dart';
import '../Authentication/login_screen.dart'; // Para redirecionar se não houver usuário logado
import 'add_viagem_screen.dart'; // Para adicionar/editar viagens
import 'calendario_screen.dart'; // Tela do calendário
import 'maps_screen.dart'; // Tela do mapa
import 'detalhes_viagem_screen.dart'; // Para abrir detalhes da viagem

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper();
  List<Viagem> _viagens = [];
  String _filtro = '';
  String _ordenacao = 'Data';
  int? _currentUserId;
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserIdAndViagens();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndViagens() async {
    setState(() => _isLoading = true);
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (!mounted) return;

    if (_currentUserId != null) {
      await _fetchViagens();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchViagens() async {
    if (_currentUserId == null) {
      _viagens = [];
      return;
    }
    final fetchedViagens = await dbHelper.listarViagens(_currentUserId!);
    if (!mounted) return;
    setState(() => _viagens = fetchedViagens);
  }

  void _adicionarViagem() async {
    if (_currentUserId == null) return;
    final result = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddViagemScreen(
          viagensExistentes: _viagens,
          userId: _currentUserId,
        ),
      ),
    );
    if (result != null) {
      await dbHelper.inserirViagem(result);
      await _fetchViagens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viagem adicionada com sucesso!')),
        );
      }
    }
  }

  void _editarViagem(Viagem viagem) async {
    if (_currentUserId == null) return;
    final result = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddViagemScreen(
          viagemExistente: viagem,
          viagensExistentes: _viagens,
          userId: _currentUserId,
        ),
      ),
    );
    if (result != null) {
      await dbHelper.atualizarViagem(result);
      await _fetchViagens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viagem atualizada com sucesso!')),
        );
      }
    }
  }

  void _abrirDetalhes(Viagem viagem) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalhesViagemScreen(viagem: viagem)),
    );
  }

  void _mostrarOpcoesLongPress(Viagem viagem) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _editarViagem(viagem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Excluir'),
              onTap: () async {
                Navigator.pop(context);
                _confirmarExclusao(viagem);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(Viagem viagem) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir "${viagem.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm == true && viagem.id != null && _currentUserId != null) {
      await dbHelper.deletarViagem(viagem.id!, _currentUserId!);
      await _fetchViagens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viagem "${viagem.titulo}" removida'),
            action: SnackBarAction(label: 'Desfazer', onPressed: () => _desfazerExclusao(viagem)),
          ),
        );
      }
    }
  }

  void _desfazerExclusao(Viagem viagem) async {
    await dbHelper.inserirViagem(viagem);
    await _fetchViagens();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viagem restaurada!')));
    }
  }

  List<Viagem> get _viagensFiltradasOrdenadas {
    final filtradas = _viagens.where((v) =>
      v.titulo.toLowerCase().contains(_filtro.toLowerCase()) ||
      v.destino.toLowerCase().contains(_filtro.toLowerCase())).toList();
    
    filtradas.sort((a, b) => _ordenacao == 'Orçamento' ? a.orcamento.compareTo(b.orcamento) : a.dataIda.compareTo(b.dataIda));
    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading ? const Center(child: CircularProgressIndicator()) : _buildMyTripsTabContent(),
                MapsScreen(), // Aba do Mapa (sem a lista de viagens, pois já é carregada internamente)
                CalendarioScreen(viagens: _viagens),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _adicionarViagem,
              backgroundColor: const Color(0xFFF77764),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF77764),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Minhas Viagens',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Viagens', icon: Icon(Icons.flight_takeoff)),
              Tab(text: 'Mapa', icon: Icon(Icons.map)),
              Tab(text: 'Calendário', icon: Icon(Icons.calendar_today)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyTripsTabContent() {
    final viagensExibidas = _viagensFiltradasOrdenadas;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Filtrar por título ou destino...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  onChanged: (valor) => setState(() => _filtro = valor),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _ordenacao,
                underline: const SizedBox(),
                icon: const Icon(Icons.sort, color: Colors.grey),
                items: const [
                  DropdownMenuItem(value: 'Data', child: Text('Data')),
                  DropdownMenuItem(value: 'Orçamento', child: Text('Orçamento')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _ordenacao = val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: viagensExibidas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma viagem encontrada.\nClique no + para adicionar a sua primeira!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: viagensExibidas.length,
                  itemBuilder: (context, index) {
                    final viagem = viagensExibidas[index];
                    return _buildTripCard(viagem);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTripCard(Viagem viagem) {
    final dataIda = '${viagem.dataIda.day}/${viagem.dataIda.month}';
    final dataVolta = '${viagem.dataChegada.day}/${viagem.dataChegada.month}';
    final cor = Color(int.tryParse(viagem.corHex ?? '') ?? Theme.of(context).primaryColor.value);

    return GestureDetector(
      onTap: () => _abrirDetalhes(viagem),
      onLongPress: () => _mostrarOpcoesLongPress(viagem),
      child: Hero(
        tag: viagem.id?.toString() ?? viagem.hashCode.toString(),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cor,
              child: const Icon(Icons.flight_takeoff, color: Colors.white),
            ),
            title: Text(viagem.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${viagem.destino} • $dataIda → $dataVolta'),
            trailing: Text(
              'R\$ ${viagem.orcamento.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
          ),
        ),
      ),
    );
  }
}