import 'package:flutter/material.dart';
import 'add_viagem_screen.dart';
import '../JsonModels/viagem.dart';
import '../database/database_helper.dart';
import 'calendario_screen.dart';
import 'maps_screen.dart';
import 'detalhes_viagem_screen.dart';
import '../utils/session_manager.dart';
import '../Authentication/login_screen.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  _TravelScreenState createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final dbHelper = DatabaseHelper();
  List<Viagem> _viagens = [];
  String _filtro = '';
  String _ordenacao = 'Data';
  int? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndViagens();
  }

  Future<void> _loadUserIdAndViagens() async {
    setState(() {
      _isLoading = true;
    });
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (!mounted) return;

    if (_currentUserId != null) {
      await _carregarViagens();
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
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _carregarViagens() async {
    if (_currentUserId == null) {
      _viagens = [];
      return;
    }
    final viagens = await dbHelper.listarViagens(_currentUserId!);
    if (!mounted) return;
    setState(() {
      _viagens = viagens;
    });
  }

  void _adicionarViagem() async {
    if (_currentUserId == null) return;
    final novaViagem = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddViagemScreen(
          viagensExistentes: _viagens,
          userId: _currentUserId,
        ),
      ),
    );

    if (novaViagem != null) {
      await dbHelper.inserirViagem(novaViagem);
      _carregarViagens();
    }
  }

  void _editarViagem(int index) async {
    if (_currentUserId == null) return;
    final viagemAEditar = _viagens[index];
    if (viagemAEditar.userId != _currentUserId) return;

    final viagemEditada = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddViagemScreen(
          viagemExistente: viagemAEditar,
          viagensExistentes: _viagens,
          userId: _currentUserId,
        ),
      ),
    );

    if (viagemEditada != null) {
      await dbHelper.atualizarViagem(viagemEditada);
      _carregarViagens();
    }
  }

  void _abrirCalendario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarioScreen(viagens: _viagens),
      ),
    );
  }

  void _abrirMapa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapsScreen()),
    );
  }

  void _abrirDetalhes(Viagem viagem) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalhesViagemScreen(viagem: viagem)),
    );
  }

  void _mostrarOpcoesLongPress(Viagem viagem, int index) {
    if (_currentUserId == null || viagem.userId != _currentUserId) return;
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _editarViagem(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Excluir'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirmar exclusão'),
                      content: Text('Deseja excluir "${viagem.titulo}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (viagem.id == null || _currentUserId == null) return;
                    await dbHelper.deletarViagem(viagem.id!, _currentUserId!);
                    _carregarViagens();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Viagem "${viagem.titulo}" removida'),
                        action: SnackBarAction(
                          label: 'Desfazer',
                          onPressed: () async {
                            await dbHelper.inserirViagem(viagem);
                            _carregarViagens();
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Viagem> _viagensFiltradasOrdenadas() {
    if (_viagens.isEmpty && !_isLoading) return [];
    final filtradas = _viagens
        .where((v) =>
            v.titulo.toLowerCase().contains(_filtro.toLowerCase()) ||
            v.destino.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    if (_ordenacao == 'Orçamento') {
      filtradas.sort((a, b) => a.orcamento.compareTo(b.orcamento));
    } else {
      filtradas.sort((a, b) => a.dataIda.compareTo(b.dataIda));
    }
    return filtradas;
  }

  // NOVO WIDGET: Constrói o cabeçalho no estilo da HomeScreen
  Widget _buildTravelHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF77764), // Cor da aba Travel para consistência
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e botões de ação (mapa, calendário)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minhas Viagens',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.white, size: 28),
                    tooltip: 'Ver Mapa',
                    onPressed: _abrirMapa,
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white, size: 26),
                    tooltip: 'Ver calendário',
                    onPressed: _abrirCalendario,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de Filtro e Ordenação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Filtrar viagens...',
                      border: InputBorder.none,
                    ),
                    onChanged: (valor) {
                      setState(() => _filtro = valor);
                    },
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                DropdownButton<String>(
                  value: _ordenacao,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, color: Colors.grey),
                  items: const [
                    DropdownMenuItem(value: 'Data', child: Text('Data')),
                    DropdownMenuItem(value: 'Orçamento', child: Text('Orçamento')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _ordenacao = val);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viagensExibidas = _viagensFiltradasOrdenadas();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ALTERAÇÃO: A AppBar foi removida
      body: Column(
        children: [
          // O novo cabeçalho customizado é chamado aqui
          _buildTravelHeader(),
          
          // O resto da tela continua dentro de um Expanded
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : viagensExibidas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma viagem encontrada.\nClique no + para adicionar sua primeira!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: viagensExibidas.length,
                        itemBuilder: (context, index) {
                          final viagem = viagensExibidas[index];
                          final dataIda = '${viagem.dataIda.day}/${viagem.dataIda.month}';
                          final dataVolta = '${viagem.dataChegada.day}/${viagem.dataChegada.month}';
                          return GestureDetector(
                            onTap: () => _abrirDetalhes(viagem),
                            onLongPress: () => _mostrarOpcoesLongPress(viagem, index),
                            child: Hero(
                              tag: viagem.id?.toString() ?? viagem.hashCode.toString(),
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color(int.tryParse(viagem.corHex ?? '0xFF4A90E2') ?? Theme.of(context).primaryColor.value),
                                    child: const Icon(Icons.flight_takeoff, color: Colors.white),
                                  ),
                                  title: Text(viagem.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${viagem.destino} • $dataIda → $dataVolta'),
                                  trailing: Text(
                                    'R\$ ${viagem.orcamento.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarViagem,
        backgroundColor: const Color(0xFFF77764),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}