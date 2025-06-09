import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../JsonModels/viagem.dart';
import '../widgets/destino_autocomplete.dart';
import '../utils/session_manager.dart';

class AddViagemScreen extends StatefulWidget {
  final Viagem? viagemExistente;
  final List<Viagem> viagensExistentes;
  final int? userId;

  const AddViagemScreen({
    super.key,
    this.viagemExistente,
    required this.viagensExistentes,
    this.userId,
  });

  @override
  State<AddViagemScreen> createState() => _AddViagemScreenState();
}

class _AddViagemScreenState extends State<AddViagemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _destinoController;
  late TextEditingController _orcamentoController; // Será a soma, readonly
  late TextEditingController _hospedagemController;
  late TextEditingController _transporteController;
  late TextEditingController _alimentacaoController;
  late TextEditingController
  _despesasDiversasController; // Renomeado de 'presentes'
  late TextEditingController _passeiosController;

  DateTime? _dataIda;
  DateTime? _dataChegada;
  Color _corSelecionada = Colors.blue;
  String? _erroDatas;
  int? _currentUserId;

  final String _apiKey = 'AIzaSyBJlxqOiGAgWuw4TDBg6IGIgmvCrTxLqFE';

  @override
  void initState() {
    super.initState();
    final v = widget.viagemExistente;
    _tituloController = TextEditingController(text: v?.titulo ?? '');
    _destinoController = TextEditingController(text: v?.destino ?? '');

    _hospedagemController = TextEditingController(
      text: v?.hospedagem.toStringAsFixed(2) ?? '0.00',
    );
    _transporteController = TextEditingController(
      text: v?.transporte.toStringAsFixed(2) ?? '0.00',
    );
    _alimentacaoController = TextEditingController(
      text: v?.alimentacao.toStringAsFixed(2) ?? '0.00',
    );
    _despesasDiversasController = TextEditingController(
      text: v?.despesasDiversas.toStringAsFixed(2) ?? '0.00',
    );
    _passeiosController = TextEditingController(
      text: v?.passeios.toStringAsFixed(2) ?? '0.00',
    );

    _orcamentoController = TextEditingController(
      text: ((v?.hospedagem ?? 0.0) +
              (v?.transporte ?? 0.0) +
              (v?.alimentacao ?? 0.0) +
              (v?.despesasDiversas ?? 0.0) +
              (v?.passeios ?? 0.0))
          .toStringAsFixed(2),
    );

    _dataIda = v?.dataIda ?? DateTime.now();
    _dataChegada =
        v?.dataChegada ?? DateTime.now().add(const Duration(days: 3));
    if (v?.corHex != null && v!.corHex!.isNotEmpty) {
      _corSelecionada = Color(int.tryParse(v.corHex!) ?? Colors.blue.value);
    }

    _currentUserId = widget.userId;
    if (_currentUserId == null) {
      _loadUserId();
    }

    _hospedagemController.addListener(_updateTotalBudget);
    _transporteController.addListener(_updateTotalBudget);
    _alimentacaoController.addListener(_updateTotalBudget);
    _despesasDiversasController.addListener(_updateTotalBudget);
    _passeiosController.addListener(_updateTotalBudget);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTotalBudget());
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _destinoController.dispose();
    _orcamentoController.dispose();
    _hospedagemController.dispose();
    _transporteController.dispose();
    _alimentacaoController.dispose();
    _despesasDiversasController.dispose();
    _passeiosController.dispose();
    super.dispose();
  }

  void _updateTotalBudget() {
    final double hospedagem =
        double.tryParse(_hospedagemController.text) ?? 0.0;
    final double transporte =
        double.tryParse(_transporteController.text) ?? 0.0;
    final double alimentacao =
        double.tryParse(_alimentacaoController.text) ?? 0.0;
    final double despesasDiversas =
        double.tryParse(_despesasDiversasController.text) ?? 0.0;
    final double passeios = double.tryParse(_passeiosController.text) ?? 0.0;

    final double total =
        hospedagem + transporte + alimentacao + despesasDiversas + passeios;

    final String newTotalText = total.toStringAsFixed(2);
    if (_orcamentoController.text != newTotalText) {
      _orcamentoController.text = newTotalText;
    }
  }

  Future<void> _loadUserId() async {
    _currentUserId = await SessionManager.getLoggedInUserId();
    if (_currentUserId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não logado. Faça login novamente.'),
        ),
      );
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
        _erroDatas = null;
      });
    }
  }

  bool _temConflitoDatas(DateTime novaIda, DateTime novaChegada) {
    for (var v in widget.viagensExistentes) {
      if (widget.viagemExistente != null &&
          v.id == widget.viagemExistente!.id) {
        continue;
      }
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

    if (_destinoController.text.trim().isEmpty) {
      setState(() {
        _erroDatas = 'Informe um destino válido';
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

    final double orcamentoTotal =
        double.tryParse(_orcamentoController.text) ?? 0.0;
    if (orcamentoTotal <= 0) {
      setState(() {
        _erroDatas = 'O orçamento total deve ser maior que 0.';
      });
      return false;
    }

    setState(() => _erroDatas = null);
    return true;
  }

  void _salvar() {
    if (!_formularioValido()) {
      return;
    }

    final double hospedagem =
        double.tryParse(_hospedagemController.text) ?? 0.0;
    final double transporte =
        double.tryParse(_transporteController.text) ?? 0.0;
    final double alimentacao =
        double.tryParse(_alimentacaoController.text) ?? 0.0;
    final double despesasDiversas =
        double.tryParse(_despesasDiversasController.text) ?? 0.0;
    final double passeios = double.tryParse(_passeiosController.text) ?? 0.0;

    final double orcamentoTotal =
        hospedagem + transporte + alimentacao + despesasDiversas + passeios;

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: ID do usuário não disponível. Tente novamente.'),
        ),
      );
      return;
    }

    final int? finalUserId;
    if (widget.viagemExistente != null) {
      finalUserId = widget.viagemExistente!.userId;
    } else {
      finalUserId = _currentUserId;
    }

    if (finalUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro: ID do usuário não disponível para salvar a viagem. Tente novamente.',
          ),
        ),
      );
      return;
    }

    final novaViagem = Viagem(
      id: widget.viagemExistente?.id,
      titulo: _tituloController.text.trim(),
      destino: _destinoController.text.trim(),
      orcamento: orcamentoTotal,
      dataIda: _dataIda!,
      dataChegada: _dataChegada!,
      corHex: _corSelecionada.value.toString(),
      userId: finalUserId,
      hospedagem: hospedagem,
      transporte: transporte,
      alimentacao: alimentacao,
      despesasDiversas: despesasDiversas,
      passeios: passeios,
    );

    Navigator.pop(context, novaViagem);
  }

  Future<bool> _confirmarSaida() async {
    final temDados =
        _tituloController.text.isNotEmpty ||
        _destinoController.text.isNotEmpty ||
        _orcamentoController.text.isNotEmpty ||
        _hospedagemController.text.isNotEmpty ||
        _transporteController.text.isNotEmpty ||
        _alimentacaoController.text.isNotEmpty ||
        _despesasDiversasController.text.isNotEmpty ||
        _passeiosController.text.isNotEmpty;

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

  // Método auxiliar para criar os TextFormField de orçamento detalhado
  Widget _buildBudgetDetailField(
    TextEditingController controller,
    String labelText,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: labelText,
        prefixText: 'R\$ ',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final v = double.tryParse(
          value ?? '0.0',
        ); // <<< CORREÇÃO AQUI: '0.0' como fallback para parse
        if (v == null || v < 0) {
          return 'Informe um valor válido (>= 0)';
        }
        return null;
      },
      onChanged: (_) => _updateTotalBudget(),
    );
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
                  height: 200,
                  child: DestinoAutocomplete(
                    apiKey: _apiKey,
                    controller: _destinoController,
                    onPlaceSelected: (descricao) {
                      setState(() => _destinoController.text = descricao);
                      _formKey.currentState?.validate();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // CAMPO DE ORÇAMENTO TOTAL (SEMPRE VISÍVEL E SOMENTE LEITURA)
                TextFormField(
                  controller: _orcamentoController,
                  readOnly: true, // Sempre somente leitura
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Orçamento Total',
                    prefixText: 'R\$ ',
                    border: const OutlineInputBorder(),
                    filled:
                        true, // Sempre preenchido para visual de somente leitura
                    fillColor:
                        Colors.grey[200], // Cor de fundo para somente leitura
                  ),
                  validator: (value) {
                    final v = double.tryParse(value ?? '0.0');
                    if (v == null || v <= 0) {
                      return 'O orçamento total deve ser maior que 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Divider(height: 32, thickness: 1), // Separador
                const Text(
                  'Detalhes do Orçamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // CAMPO DE ORÇAMENTO DETALHADO (AGORA SEMPRE VISÍVEIS)
                _buildBudgetDetailField(_hospedagemController, 'Hospedagem'),
                const SizedBox(height: 16),
                _buildBudgetDetailField(_transporteController, 'Transporte'),
                const SizedBox(height: 16),
                _buildBudgetDetailField(_alimentacaoController, 'Alimentação'),
                const SizedBox(height: 16),
                _buildBudgetDetailField(
                  _despesasDiversasController,
                  'Despesas Diversas',
                ),
                const SizedBox(height: 16),
                _buildBudgetDetailField(_passeiosController, 'Passeios'),
                const SizedBox(height: 16),

                // FIM DOS CAMPOS DE ORÇAMENTO DETALHADO
                ListTile(
                  title: const Text('Data de ida'),
                  subtitle: Text(
                    // <<< LINHA COM ERRO DE FORMATAÇÃO NO SEU TERMINAL (linha 410 no seu output)
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
