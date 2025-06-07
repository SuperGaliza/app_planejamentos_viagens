import 'package:flutter/material.dart';
import 'add_viagem_screen.dart';
import '../JsonModels/viagem.dart';
import '../database/database_helper.dart';
import 'calendario_screen.dart';
import 'maps_screen.dart';
import 'detalhes_viagem_screen.dart'; // novo import

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

  @override
  void initState() {
    super.initState();
    _carregarViagens();
  }

  Future<void> _carregarViagens() async {
    final viagens = await dbHelper.listarViagens();

    if (!mounted) return;

    setState(() {
      _viagens = viagens;
    });
  }

  void _adicionarViagem() async {
    final novaViagem = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddViagemScreen(viagensExistentes: _viagens),
      ),
    );

    if (novaViagem != null) {
      await dbHelper.inserirViagem(novaViagem);
      _carregarViagens();
    }
  }

  void _editarViagem(int index) async {
    final viagemEditada = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddViagemScreen(
              viagemExistente: _viagens[index],
              viagensExistentes: _viagens,
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
                    if (viagem.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro: viagem sem ID')),
                      );
                      return;
                    }

                    await dbHelper.deletarViagem(viagem.id!);
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
        backgroundColor: Colors.red,
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
                    ? const Center(child: Text('Nenhuma viagem encontrada.'))
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
                              () => _mostrarOpcoesLongPress(viagem, index),
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
                                leading: const Icon(Icons.flight_takeoff),
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
