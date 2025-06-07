import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../JsonModels/viagem.dart';
import '../widgets/destino_autocomplete.dart';
// Importe o SessionManager para obter o ID do usuário, caso não seja passado
import '../utils/session_manager.dart'; // <<< NOVO IMPORT

class AddViagemScreen extends StatefulWidget {
  final Viagem? viagemExistente;
  final List<Viagem> viagensExistentes;
  final int? userId; // <<< NOVO PARÂMETRO: O ID do usuário logado

  const AddViagemScreen({
    super.key,
    this.viagemExistente,
    required this.viagensExistentes,
    this.userId, // <<< Adicione ao construtor
  });

  @override
  State<AddViagemScreen> createState() => _AddViagemScreenState();
}

class _AddViagemScreenState extends State<AddViagemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController
  _destinoController; // Controlado pelo DestinoAutocomplete
  late TextEditingController _orcamentoController;
  DateTime? _dataIda;
  DateTime? _dataChegada;
  Color _corSelecionada = Colors.blue;
  String? _erroDatas;
  int? _currentUserId; // Para armazenar o ID do usuário logado nesta tela

  final String _apiKey = 'AIzaSyBJlxqOiGAgWuw4TDBg6IGIgmvCrTxLqFE';

  @override
  void initState() {
    super.initState();
    final v = widget.viagemExistente;
    _tituloController = TextEditingController(text: v?.titulo ?? '');
    _destinoController = TextEditingController(
      text: v?.destino ?? '',
    ); // Inicializa com o destino existente
    _orcamentoController = TextEditingController(
      text: v?.orcamento.toStringAsFixed(2) ?? '',
    );
    _dataIda = v?.dataIda ?? DateTime.now();
    _dataChegada =
        v?.dataChegada ?? DateTime.now().add(const Duration(days: 3));
    if (v?.corHex != null && v!.corHex!.isNotEmpty) {
      _corSelecionada = Color(int.tryParse(v.corHex!) ?? Colors.blue.value);
    }

    // Carrega o userId: prioriza o que foi passado, se não, busca do SessionManager
    _currentUserId = widget.userId;
    if (_currentUserId == null) {
      _loadUserId();
    }
  }

  // Função para carregar o userId do SessionManager caso não seja passado pelo construtor
  Future<void> _loadUserId() async {
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (_currentUserId == null && mounted) {
      // Se não houver userId, algo está errado (usuário não logado ou sessão expirada)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado. Faça login novamente.'),
        ),
      );
      // Opcional: Navegar de volta para a tela de login
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => const LoginScreen()),
      //   (Route<dynamic> route) => false,
      // );
    }
  }

  Future<void> _selecionarData(bool isIda) async {
    final dataInicial = isIda ? _dataIda : _dataChegada;
    final novaData = await showDatePicker(
      context: context,
      initialDate: dataInicial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (novaData != null) {
      setState(() {
        if (isIda) {
          _dataIda = novaData;
          if (_dataChegada != null && _dataChegada!.isBefore(_dataIda!)) {
            _dataChegada = _dataIda!.add(const Duration(days: 1));
          }
        } else {
          _dataChegada = novaData;
        }
        _erroDatas = null; // Limpa o erro de datas ao selecionar
      });
    }
  }

  bool _temConflitoDatas(DateTime novaIda, DateTime novaChegada) {
    for (var v in widget.viagensExistentes) {
      // Se estiver editando, pule a própria viagem da lista de conflitos
      if (widget.viagemExistente != null &&
          v.id == widget.viagemExistente!.id) {
        continue;
      }
      // Verifica se as datas da nova viagem se sobrepõem a uma viagem existente
      // Uma sobreposição ocorre se:
      // (novaIda está antes ou no mesmo dia que v.dataChegada) E (novaChegada está depois ou no mesmo dia que v.dataIda)
      // Normalizamos as datas para considerar apenas o dia, ignorando a hora
      final newTripStart = DateTime(novaIda.year, novaIda.month, novaIda.day);
      final newTripEnd = DateTime(
        novaChegada.year,
        novaChegada.month,
        novaChegada.day,
      );
      final existingTripStart = DateTime(
        v.dataIda.year,
        v.dataIda.month,
        v.dataIda.day,
      );
      final existingTripEnd = DateTime(
        v.dataChegada.year,
        v.dataChegada.month,
        v.dataChegada.day,
      );

      // Checa por sobreposição de intervalos: [A,B] e [C,D] se sobrepõem se max(A,C) <= min(B,D)
      if (newTripStart.isBefore(existingTripEnd.add(const Duration(days: 1))) &&
          newTripEnd.isAfter(
            existingTripStart.subtract(const Duration(days: 1)),
          )) {
        return true;
      }
    }
    return false;
  }

  bool _formularioValido() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Validação específica para o destino (se não estiver usando validator no DestinoAutocomplete)
    if (_destinoController.text.trim().isEmpty) {
      setState(() {
        _erroDatas =
            'Informe um destino válido'; // Reutilizando _erroDatas para feedback geral de erro de formulário
      });
      return false;
    }

    if (_dataIda == null || _dataChegada == null) {
      setState(() {
        _erroDatas = 'Selecione datas válidas';
      });
      return false;
    }

    if (_dataChegada!.isBefore(_dataIda!)) {
      setState(() {
        _erroDatas = 'Data de chegada deve ser igual ou após a data de ida';
      });
      return false;
    }

    if (_temConflitoDatas(_dataIda!, _dataChegada!)) {
      setState(() {
        _erroDatas = 'Já existe uma viagem cadastrada nesse período';
      });
      return false;
    }

    // Se todas as validações passarem, limpa qualquer erro anterior
    setState(() => _erroDatas = null);
    return true;
  }

  void _salvar() {
    // Não precisa de setState aqui, _formularioValido já lida com _erroDatas
    if (!_formularioValido()) {
      return;
    }

    final orcamento = double.tryParse(_orcamentoController.text);
    // Este validator já está no TextFormField, mas um último check é bom
    if (orcamento == null || orcamento <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um orçamento válido (> 0)')),
      );
      return;
    }

    // Verifica se o userId está disponível
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: ID do usuário não disponível. Tente novamente.'),
        ),
      );
      return;
    }

    // Cria a nova Viagem com o userId
    final novaViagem = Viagem(
      id: widget.viagemExistente?.id, // Manter o ID se for edição
      titulo: _tituloController.text.trim(),
      destino: _destinoController.text.trim(),
      orcamento: orcamento,
      dataIda: _dataIda!,
      dataChegada: _dataChegada!,
      corHex: _corSelecionada.value.toString(),
      userId: _currentUserId!, // <<< PASSA O userId AQUI PARA O MODELO VIAGEM
    );

    Navigator.pop(context, novaViagem);
  }

  Future<bool> _confirmarSaida() async {
    final temDados =
        _tituloController.text.isNotEmpty ||
        _destinoController.text.isNotEmpty ||
        _orcamentoController.text.isNotEmpty;

    if (!temDados) return true;

    final sair = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text('Você perderá os dados inseridos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sim'),
              ),
            ],
          ),
    );

    return sair ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmarSaida,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.viagemExistente == null ? 'Nova Viagem' : 'Editar Viagem',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Informe um título'
                              : null,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height:
                      200, // Altura pode ser ajustada ou removida para flexibilidade
                  child: DestinoAutocomplete(
                    apiKey: _apiKey,
                    controller:
                        _destinoController, // <<< PASSA O CONTROLLER AQUI
                    onPlaceSelected: (descricao) {
                      setState(() => _destinoController.text = descricao);
                      _formKey.currentState
                          ?.validate(); // Força a revalidação do formulário
                    },
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _orcamentoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Orçamento',
                    prefixText: 'R\$ ',
                  ),
                  validator: (value) {
                    final v = double.tryParse(value ?? '');
                    if (v == null || v <= 0) {
                      return 'Informe um valor válido (> 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: const Text('Data de ida'),
                  subtitle: Text(
                    _dataIda != null
                        ? '${_dataIda!.day}/${_dataIda!.month}/${_dataIda!.year}'
                        : 'Selecione',
                  ),
                  trailing: const Icon(Icons.date_range),
                  tileColor:
                      _erroDatas != null ? Colors.red.withOpacity(0.1) : null,
                  onTap: () => _selecionarData(true),
                ),
                ListTile(
                  title: const Text('Data de chegada'),
                  subtitle: Text(
                    _dataChegada != null
                        ? '${_dataChegada!.day}/${_dataChegada!.month}/${_dataChegada!.year}'
                        : 'Selecione',
                  ),
                  trailing: const Icon(Icons.date_range),
                  tileColor:
                      _erroDatas != null ? Colors.red.withOpacity(0.1) : null,
                  onTap: () => _selecionarData(false),
                ),

                if (_erroDatas != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _erroDatas!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text('Cor da viagem:'),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final novaCor = await showDialog<Color>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Escolher cor'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: _corSelecionada,
                                    onColorChanged:
                                        (cor) => Navigator.pop(context, cor),
                                  ),
                                ),
                              ),
                        );
                        if (novaCor != null) {
                          setState(() => _corSelecionada = novaCor);
                        }
                      },
                      child: CircleAvatar(backgroundColor: _corSelecionada),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
