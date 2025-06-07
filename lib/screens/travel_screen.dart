import 'package:flutter/material.dart';
import 'add_viagem_screen.dart';
import '../JsonModels/viagem.dart';
import '../database/database_helper.dart';
import 'calendario_screen.dart';
import 'maps_screen.dart';
import 'detalhes_viagem_screen.dart';
import '../utils/session_manager.dart'; // <<< NOVO IMPORT
import '../Authentication/login_screen.dart'; // Para redirecionar se não houver usuário logado

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
  int? _currentUserId; // <<< NOVO CAMPO: Para armazenar o ID do usuário logado
  bool _isLoading =
      true; // <<< NOVO CAMPO: Para indicar o estado de carregamento

  @override
  void initState() {
    super.initState();
    _loadUserIdAndViagens(); // Inicia o carregamento do userId e das viagens
  }

  // Novo método para carregar o userId e depois todas as viagens
  Future<void> _loadUserIdAndViagens() async {
    setState(() {
      _isLoading = true; // Começa o carregamento
    });
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (!mounted) return;

    if (_currentUserId != null) {
      await _carregarViagens(); // Se houver userId, carrega as viagens
    } else {
      // Se não houver userId logado, isso é um estado inválido para TravelScreen
      // Redirecionar para a tela de login.
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
      _isLoading = false; // Finaliza o carregamento
    });
  }

  Future<void> _carregarViagens() async {
    if (_currentUserId == null) {
      _viagens =
          []; // Limpa a lista se não houver usuário logado (estado de segurança)
      return;
    }
    final viagens = await dbHelper.listarViagens(
      _currentUserId!,
    ); // <<< CORREÇÃO AQUI: PASSA O USER ID
    if (!mounted) return;
    setState(() {
      _viagens = viagens;
    });
  }

  void _adicionarViagem() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado para adicionar viagem.'),
        ),
      );
      return;
    }

    final novaViagem = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddViagemScreen(
              viagensExistentes: _viagens,
              userId:
                  _currentUserId, // <<< PASSA O USER ID PARA AddViagemScreen
            ),
      ),
    );

    if (novaViagem != null) {
      // A novaViagem já deve vir com o userId atribuído pela AddViagemScreen
      await dbHelper.inserirViagem(novaViagem);
      _carregarViagens(); // Recarrega a lista de viagens
    }
  }

  void _editarViagem(int index) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado para editar viagem.'),
        ),
      );
      return;
    }

    final viagemAEditar = _viagens[index];
    // Embora listarViagens já filtre, é bom reforçar que a viagem pertence ao usuário
    if (viagemAEditar.userId != _currentUserId) {
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
              viagemExistente: viagemAEditar,
              viagensExistentes:
                  _viagens, // Passa as viagens existentes para validação de conflito
              userId:
                  _currentUserId, // <<< PASSA O USER ID PARA AddViagemScreen
            ),
      ),
    );

    if (viagemEditada != null) {
      // A viagemEditada já deve vir com o userId atribuído pela AddViagemScreen
      await dbHelper.atualizarViagem(viagemEditada);
      _carregarViagens(); // Recarrega a lista de viagens
    }
  }

  void _abrirCalendario() {
    // A CalendarioScreen recebe a lista de viagens, que já é filtrada pelo userId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarioScreen(viagens: _viagens),
      ),
    );
  }

  void _abrirMapa() {
    // MapsScreen já foi atualizada para obter o userId internamente
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
    if (_currentUserId == null || viagem.userId != _currentUserId) {
      // Mensagem de erro se o usuário tentar interagir com uma viagem que não lhe pertence (embora a lista deva ser filtrada)
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

                    // AQUI: Passa o userId para o método deletarViagem
                    await dbHelper.deletarViagem(viagem.id!, _currentUserId!);
                    _carregarViagens(); // Recarrega a lista

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Viagem "${viagem.titulo}" removida'),
                        action: SnackBarAction(
                          label: 'Desfazer',
                          onPressed: () async {
                            // Para desfazer, recriar a viagem com o userId correto
                            final Viagem viagemDesfeita = Viagem(
                              id: viagem.id, // Manter o ID original se possível
                              titulo: viagem.titulo,
                              destino: viagem.destino,
                              orcamento: viagem.orcamento,
                              dataIda: viagem.dataIda,
                              dataChegada: viagem.dataChegada,
                              corHex: viagem.corHex,
                              userId:
                                  viagem
                                      .userId, // Usa o userId original da viagem que foi deletada
                            );
                            await dbHelper.inserirViagem(viagemDesfeita);
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
    // Garante que _viagens está populada, se não, retorna lista vazia
    if (_viagens.isEmpty && !_isLoading) {
      // Se não está carregando e a lista está vazia
      return [];
    }

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

  @override
  Widget build(BuildContext context) {
    final viagensExibidas = _viagensFiltradasOrdenadas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Viagens'),
        // Use a cor primária do tema para consistência
        backgroundColor:
            Theme.of(
              context,
            ).primaryColor, // Cores.red substituído pela cor do tema
        foregroundColor:
            Colors.white, // Garante ícones e texto brancos na AppBar
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Ver Mapa',
            onPressed: _abrirMapa,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Ver calendário',
            onPressed: _abrirCalendario,
          ),
        ],
      ),
      body:
          _isLoading // Exibe um indicador de carregamento se estiver carregando
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                          items: const [
                            DropdownMenuItem(
                              value: 'Data',
                              child: Text('Ordenar por Data'),
                            ),
                            DropdownMenuItem(
                              value: 'Orçamento',
                              child: Text('Ordenar por Orçamento'),
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
                        viagensExibidas.isEmpty
                            ? const Center(
                              child: Text('Nenhuma viagem encontrada.'),
                            )
                            : ListView.builder(
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
                                        index,
                                      ),
                                  child: Hero(
                                    tag:
                                        viagem.id?.toString() ??
                                        viagem.hashCode.toString(),
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        // Usando a cor da viagem no leading CircleAvatar
                                        leading: CircleAvatar(
                                          backgroundColor: Color(
                                            int.tryParse(
                                                  viagem.corHex ?? '0xFF4A90E2',
                                                ) ??
                                                Theme.of(
                                                  context,
                                                ).primaryColor.value,
                                          ), // Usa cor da viagem ou a primária do tema
                                          child: const Icon(
                                            Icons.flight_takeoff,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(viagem.titulo),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
