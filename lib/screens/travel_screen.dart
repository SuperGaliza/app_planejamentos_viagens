// lib/screens/travel_screen.dart
import 'package:flutter/material.dart';
import '../JsonModels/viagem.dart';
import '../database/database_helper.dart';
import '../utils/session_manager.dart';
import '../Authentication/login_screen.dart'; // Para redirecionar se não houver usuário logado
import 'add_viagem_screen.dart'; // Para adicionar/editar viagens
import 'calendario_screen.dart'; // Tela do calendário
import 'maps_screen.dart'; // Tela do mapa
import 'profile_screen.dart'; // Tela do perfil (agora será uma aba)
import 'detalhes_viagem_screen.dart'; // Para abrir detalhes da viagem

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final dbHelper = DatabaseHelper();
  List<Viagem> _viagens = []; // Lista principal de viagens do usuário logado
  String _filtro = ''; // Filtro para a lista de viagens
  String _ordenacao = 'Data'; // Ordenação para a lista de viagens
  int? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndViagens(); // Carrega o userId e as viagens do usuário
  }

  // Carrega o ID do usuário logado e, em seguida, as viagens
  Future<void> _loadUserIdAndViagens() async {
    setState(() {
      _isLoading = true;
    });
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (!mounted) return;

    if (_currentUserId != null) {
      await _fetchViagens(); // Busca as viagens do usuário
    } else {
      // Caso não haja userId logado, redireciona para a tela de login
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

  // Método para buscar as viagens do banco de dados (chamado na inicialização e após operações CRUD)
  Future<void> _fetchViagens() async {
    if (_currentUserId == null) {
      _viagens = []; // Garante lista vazia se não houver usuário logado
      return;
    }
    final fetchedViagens = await dbHelper.listarViagens(_currentUserId!);
    if (!mounted) return;
    setState(() {
      _viagens = fetchedViagens;
    });
  }

  // Método para adicionar uma nova viagem
  void _adicionarViagem() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado para adicionar viagem.'),
        ),
      );
      return;
    }

    // Navega para a tela de adicionar/editar viagem
    final novaViagem = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddViagemScreen(
              viagensExistentes:
                  _viagens, // Passa todas as viagens para validação de conflito
              userId: _currentUserId, // Passa o ID do usuário logado
            ),
      ),
    );

    if (novaViagem != null) {
      await dbHelper.inserirViagem(novaViagem);
      await _fetchViagens(); // Recarrega as viagens após a adição
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viagem adicionada com sucesso!')),
        );
      }
    }
  }

  // Método para editar uma viagem existente
  void _editarViagem(Viagem viagemToEdit) async {
    if (_currentUserId == null || viagemToEdit.userId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para editar esta viagem.'),
        ),
      );
      return;
    }

    final viagemEditada = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddViagemScreen(
              viagemExistente: viagemToEdit,
              viagensExistentes: _viagens,
              userId: _currentUserId,
            ),
      ),
    );

    if (viagemEditada != null) {
      await dbHelper.atualizarViagem(viagemEditada);
      await _fetchViagens(); // Recarrega as viagens após a edição
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viagem atualizada com sucesso!')),
        );
      }
    }
  }

  // Método para abrir os detalhes de uma viagem
  void _abrirDetalhes(Viagem viagem) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalhesViagemScreen(viagem: viagem)),
    );
  }

  // Método para mostrar opções de editar/excluir ao segurar um item da lista
  void _mostrarOpcoesLongPress(Viagem viagem) {
    if (_currentUserId == null || viagem.userId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não tem permissão para esta ação.')),
      );
      return;
    }

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
                  _editarViagem(viagem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Excluir'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
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
                    if (viagem.id == null || _currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Erro: ID da viagem ou usuário não disponível.',
                          ),
                        ),
                      );
                      return;
                    }

                    await dbHelper.deletarViagem(viagem.id!, _currentUserId!);
                    await _fetchViagens(); // Recarrega as viagens após a exclusão
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viagem "${viagem.titulo}" removida'),
                          action: SnackBarAction(
                            label: 'Desfazer',
                            onPressed: () async {
                              final Viagem viagemDesfeita = Viagem(
                                id: viagem.id,
                                titulo: viagem.titulo,
                                destino: viagem.destino,
                                orcamento: viagem.orcamento,
                                dataIda: viagem.dataIda,
                                dataChegada: viagem.dataChegada,
                                corHex: viagem.corHex,
                                userId: viagem.userId,
                              );
                              await dbHelper.inserirViagem(viagemDesfeita);
                              await _fetchViagens(); // Recarrega as viagens após desfazer
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Viagem restaurada!'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Filtra e ordena a lista de viagens para exibição
  List<Viagem> _viagensFiltradasOrdenadas() {
    if (_viagens.isEmpty && !_isLoading) return [];
    final filtradas =
        _viagens
            .where(
              (v) =>
                  v.titulo.toLowerCase().contains(_filtro.toLowerCase()) ||
                  v.destino.toLowerCase().contains(_filtro.toLowerCase()),
            )
            .toList();

    if (_ordenacao == 'Orçamento') {
      filtradas.sort((a, b) => a.orcamento.compareTo(b.orcamento));
    } else {
      filtradas.sort((a, b) => a.dataIda.compareTo(b.dataIda));
    }
    return filtradas;
  }

  // --- Widget para a aba "Minhas Viagens" (lista de viagens, filtro, FAB) ---
  Widget _buildMyTripsTabContent() {
    final viagensExibidas = _viagensFiltradasOrdenadas();

    return Scaffold(
      // Usa um Scaffold interno para ter o FloatingActionButton
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Filtrar por título ou destino...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (valor) {
                      setState(() => _filtro = valor);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _ordenacao,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, color: Colors.grey),
                  items: const [
                    DropdownMenuItem(value: 'Data', child: Text('Data')),
                    DropdownMenuItem(
                      value: 'Orçamento',
                      child: Text('Orçamento'),
                    ),
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
          Expanded(
            child:
                _isLoading
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
                        final dataIda =
                            '${viagem.dataIda.day}/${viagem.dataIda.month}';
                        final dataVolta =
                            '${viagem.dataChegada.day}/${viagem.dataChegada.month}';
                        return GestureDetector(
                          onTap: () => _abrirDetalhes(viagem),
                          onLongPress:
                              () => _mostrarOpcoesLongPress(
                                viagem,
                              ), // Passa a viagem diretamente
                          child: Hero(
                            tag:
                                viagem.id?.toString() ??
                                viagem.hashCode.toString(),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(
                                    int.tryParse(
                                          viagem.corHex ?? '0xFF4A90E2',
                                        ) ??
                                        Theme.of(context).primaryColor.value,
                                  ),
                                  child: const Icon(
                                    Icons.flight_takeoff,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  viagem.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${viagem.destino} • $dataIda → $dataVolta',
                                ),
                                trailing: Text(
                                  'R\$ ${viagem.orcamento.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
        backgroundColor: const Color(
          0xFFF77764,
        ), // Cor consistente com a aba Travel
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Envolve todo o Scaffold com DefaultTabController
      length: 4, // 4 abas: Viagens, Mapa, Calendário, Perfil
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Travel Planner'), // Título geral do app
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Viagens', icon: Icon(Icons.flight_takeoff)),
              Tab(text: 'Mapa', icon: Icon(Icons.map)),
              Tab(text: 'Calendário', icon: Icon(Icons.calendar_today)),
              Tab(
                text: 'Perfil',
                icon: Icon(Icons.person),
              ), // Adiciona a aba de Perfil
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          // Conteúdo das abas
          children: [
            _isLoading // Mostra o loading na aba de Viagens se os dados estiverem carregando
                ? const Center(child: CircularProgressIndicator())
                : _buildMyTripsTabContent(), // Conteúdo da aba de Viagens
            const MapsScreen(), // Aba do Mapa
            CalendarioScreen(viagens: _viagens), // Aba do Calendário
            const ProfileScreen(), // Aba do Perfil
          ],
        ),
      ),
    );
  }
}
