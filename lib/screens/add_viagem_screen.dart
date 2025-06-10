import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _orcamentoController;
  late TextEditingController _hospedagemController;
  late TextEditingController _transporteController;
  late TextEditingController _alimentacaoController;
  late TextEditingController _despesasDiversasController;
  late TextEditingController _passeiosController;

  DateTime? _dataIda;
  DateTime? _dataChegada;
  Color _corSelecionada = Colors.blue;
  int? _currentUserId;

  final String _apiKey = 'AIzaSyBJlxqOiGAgWuw4TDBg6IGIgmvCrTxLqFE';

  // Função auxiliar para inicializar os controladores de orçamento da forma correta
  TextEditingController _initBudgetController(double? value) {
    // Se o valor for nulo ou zero, o campo começa vazio (para mostrar o hintText)
    // Se houver um valor, ele é exibido normalmente.
    return TextEditingController(text: (value == null || value == 0.0) ? '' : value.toStringAsFixed(2));
  }

  @override
  void initState() {
    super.initState();
    final v = widget.viagemExistente;

    _tituloController = TextEditingController(text: v?.titulo ?? '');
    _destinoController = TextEditingController(text: v?.destino ?? '');

    // --- MUDANÇA: Usando a nova função para inicializar os campos ---
    _hospedagemController = _initBudgetController(v?.hospedagem);
    _transporteController = _initBudgetController(v?.transporte);
    _alimentacaoController = _initBudgetController(v?.alimentacao);
    _despesasDiversasController = _initBudgetController(v?.despesasDiversas);
    _passeiosController = _initBudgetController(v?.passeios);
    
    _orcamentoController = TextEditingController();

    // Os "ouvintes" para o cálculo automático continuam
    [_hospedagemController, _transporteController, _alimentacaoController, _despesasDiversasController, _passeiosController]
        .forEach((controller) => controller.addListener(_updateTotalBudget));

    _dataIda = v?.dataIda;
    _dataChegada = v?.dataChegada;
    if (v?.corHex != null && v!.corHex!.isNotEmpty) {
      _corSelecionada = Color(int.tryParse(v.corHex!) ?? Colors.blue.value);
    }

    _loadUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTotalBudget();
    });
  }

  @override
  void dispose() {
    // O dispose agora é mais simples, sem FocusNodes
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

  Future<void> _loadUserId() async {
    _currentUserId = widget.userId ?? await SessionManager.getLoggedInUserId();
    if (_currentUserId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado.')),
      );
      Navigator.of(context).pop();
    }
  }

  void _updateTotalBudget() {
    // A lógica de parse com '?? 0.0' já trata o texto vazio como zero
    final double hospedagem = double.tryParse(_hospedagemController.text) ?? 0.0;
    final double transporte = double.tryParse(_transporteController.text) ?? 0.0;
    final double alimentacao = double.tryParse(_alimentacaoController.text) ?? 0.0;
    final double despesas = double.tryParse(_despesasDiversasController.text) ?? 0.0;
    final double passeios = double.tryParse(_passeiosController.text) ?? 0.0;

    final double total = hospedagem + transporte + alimentacao + despesas + passeios;
    _orcamentoController.text = total.toStringAsFixed(2);
  }

  Future<void> _selecionarData(BuildContext context, bool isIda) async {
    final dataInicial = isIda ? (_dataIda ?? DateTime.now()) : (_dataChegada ?? _dataIda ?? DateTime.now());
    final novaData = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (novaData != null) {
      setState(() {
        if (isIda) {
          _dataIda = novaData;
          if (_dataChegada != null && _dataChegada!.isBefore(_dataIda!)) {
            _dataChegada = _dataIda;
          }
        } else {
          _dataChegada = novaData;
        }
      });
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha os campos obrigatórios.')),
      );
      return;
    }
    if (_dataIda == null || _dataChegada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione as datas da viagem.')),
      );
      return;
    }
    if (_dataChegada!.isBefore(_dataIda!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data de chegada não pode ser anterior à de ida.')),
      );
      return;
    }
    final novaViagem = Viagem(
      id: widget.viagemExistente?.id,
      titulo: _tituloController.text.trim(),
      destino: _destinoController.text.trim(),
      orcamento: double.tryParse(_orcamentoController.text) ?? 0.0,
      dataIda: _dataIda!,
      dataChegada: _dataChegada!,
      corHex: _corSelecionada.value.toString(),
      userId: _currentUserId!,
      hospedagem: double.tryParse(_hospedagemController.text) ?? 0.0,
      transporte: double.tryParse(_transporteController.text) ?? 0.0,
      alimentacao: double.tryParse(_alimentacaoController.text) ?? 0.0,
      despesasDiversas: double.tryParse(_despesasDiversasController.text) ?? 0.0,
      passeios: double.tryParse(_passeiosController.text) ?? 0.0,
    );
    Navigator.pop(context, novaViagem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viagemExistente == null ? 'Nova Viagem' : 'Editar Viagem'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título da Viagem',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O título é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text("Destino", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DestinoAutocomplete(
                apiKey: _apiKey,
                controller: _destinoController,
                hintText: 'Digite o destino...',
                height: 200,
                onPlaceSelected: (descricao) {
                  setState(() => _destinoController.text = descricao);
                },
              ),
              const SizedBox(height: 24),
              const Text("Orçamento", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildBudgetField(controller: _hospedagemController, label: 'Hospedagem', icon: Icons.hotel),
              _buildBudgetField(controller: _transporteController, label: 'Transporte', icon: Icons.directions_car),
              _buildBudgetField(controller: _alimentacaoController, label: 'Alimentação', icon: Icons.restaurant),
              _buildBudgetField(controller: _passeiosController, label: 'Passeios', icon: Icons.attractions),
              _buildBudgetField(controller: _despesasDiversasController, label: 'Despesas Diversas', icon: Icons.shopping_bag),
              const Divider(height: 32, thickness: 1),
              TextFormField(
                controller: _orcamentoController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Orçamento Total',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                  filled: true,
                  fillColor: Color.fromARGB(255, 223, 222, 222),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 24),
              const Text("Datas e Cor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selecionarData(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataIda == null ? 'Ida' : DateFormat('dd/MM/yy').format(_dataIda!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selecionarData(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataChegada == null ? 'Chegada' : DateFormat('dd/MM/yy').format(_dataChegada!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Escolha uma cor'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: _corSelecionada,
                          onColorChanged: (color) => setState(() => _corSelecionada = color),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        )
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.color_lens_outlined),
                      const SizedBox(width: 12),
                      const Text('Cor da Viagem'),
                      const Spacer(),
                      CircleAvatar(backgroundColor: _corSelecionada, radius: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('SALVAR VIAGEM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MUDANÇA: Widget auxiliar agora usa hintText e não precisa mais do FocusNode ---
  Widget _buildBudgetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'R\$ ',
          hintText: '0.00', // <--- A MÁGICA ACONTECE AQUI
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          // Permite que o campo esteja vazio, mas valida se não é um texto inválido.
          if (value != null && value.isNotEmpty && double.tryParse(value.replaceAll(',', '.')) == null) {
            return 'Valor inválido';
          }
          return null;
        },
      ),
    );
  }
}