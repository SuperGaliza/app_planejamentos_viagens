import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../JsonModels/viagem.dart';
import '../widgets/destino_autocomplete.dart';

class AddViagemScreen extends StatefulWidget {
  final Viagem? viagemExistente;
  final List<Viagem> viagensExistentes;

  const AddViagemScreen({
    super.key,
    this.viagemExistente,
    required this.viagensExistentes,
  });

  @override
  State<AddViagemScreen> createState() => _AddViagemScreenState();
}

class _AddViagemScreenState extends State<AddViagemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _destinoController;
  late TextEditingController _orcamentoController;
  DateTime? _dataIda;
  DateTime? _dataChegada;
  Color _corSelecionada = Colors.blue;
  String? _erroDatas;

  final String _apiKey = 'AIzaSyBJlxqOiGAgWuw4TDBg6IGIgmvCrTxLqFE';

  @override
  void initState() {
    super.initState();
    final v = widget.viagemExistente;
    _tituloController = TextEditingController(text: v?.titulo ?? '');
    _destinoController = TextEditingController(text: v?.destino ?? '');
    _orcamentoController = TextEditingController(
      text: v?.orcamento.toStringAsFixed(2) ?? '',
    );
    _dataIda = v?.dataIda ?? DateTime.now();
    _dataChegada =
        v?.dataChegada ?? DateTime.now().add(const Duration(days: 3));
    if (v?.corHex != null && v!.corHex!.isNotEmpty) {
      _corSelecionada = Color(int.tryParse(v.corHex!) ?? Colors.blue.value);
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
      if (!(novaChegada.isBefore(v.dataIda) ||
          novaIda.isAfter(v.dataChegada))) {
        return true;
      }
    }
    return false;
  }

  bool _formularioValido() {
    if (!_formKey.currentState!.validate()) return false;

    if (_dataIda == null || _dataChegada == null) {
      _erroDatas = 'Selecione datas válidas';
      return false;
    }

    if (_dataChegada!.isBefore(_dataIda!)) {
      _erroDatas = 'Data de chegada deve ser igual ou após a data de ida';
      return false;
    }

    if (_temConflitoDatas(_dataIda!, _dataChegada!)) {
      _erroDatas = 'Já existe uma viagem cadastrada nesse período';
      return false;
    }

    return true;
  }

  void _salvar() {
    setState(() => _erroDatas = null);

    if (!_formularioValido()) {
      setState(() {});
      return;
    }

    final orcamento = double.tryParse(_orcamentoController.text);
    if (_destinoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe um destino')));
      return;
    }

    final novaViagem = Viagem(
      id: widget.viagemExistente?.id,
      titulo: _tituloController.text.trim(),
      destino: _destinoController.text.trim(),
      orcamento: orcamento!,
      dataIda: _dataIda!,
      dataChegada: _dataChegada!,
      corHex: _corSelecionada.value.toString(),
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
                  height: 200,
                  child: DestinoAutocomplete(
                    apiKey: _apiKey,
                    onPlaceSelected: (descricao) {
                      setState(() => _destinoController.text = descricao);
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
