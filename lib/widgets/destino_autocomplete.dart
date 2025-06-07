import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

class DestinoAutocomplete extends StatefulWidget {
  final Function(String) onPlaceSelected;
  final TextEditingController?
  controller; // <<< ADICIONE ESTA LINHA: O controller externo é opcional
  final double height;
  final String hintText;
  final String apiKey;

  const DestinoAutocomplete({
    super.key,
    required this.onPlaceSelected,
    required this.apiKey,
    this.controller, // <<< ADICIONE ESTA LINHA: Inclua no construtor
    this.height = 250,
    this.hintText = 'Digite o destino',
  });

  @override
  State<DestinoAutocomplete> createState() => _DestinoAutocompleteState();
}

class _DestinoAutocompleteState extends State<DestinoAutocomplete> {
  late TextEditingController
  _internalController; // <<< ESTA LINHA É A CHAVE: Controller que o widget usará
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa _internalController: usa o controller passado (se houver) ou cria um novo
    _internalController = widget.controller ?? TextEditingController();
    googlePlace = GooglePlace(widget.apiKey);

    // Opcional: Adiciona um listener para disparar a busca se o texto for alterado por fora
    // (ex: ao carregar uma viagem existente na AddViagemScreen)
    _internalController.addListener(_onControllerTextChanged);

    // Dispara a busca inicial se já houver texto (ex: edição de viagem)
    if (_internalController.text.isNotEmpty) {
      autoCompleteSearch(_internalController.text);
    }
  }

  // Novo método para lidar com a mudança de texto no controller
  void _onControllerTextChanged() {
    // Evita loop se a mudança veio de uma seleção interna
    if (_internalController.text !=
        (predictions.isNotEmpty &&
                predictions.first.description == _internalController.text
            ? predictions.first.description
            : null)) {
      autoCompleteSearch(_internalController.text);
    }
  }

  @override
  void didUpdateWidget(covariant DestinoAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o controller externo (widget.controller) mudou:
    if (widget.controller != oldWidget.controller) {
      // Remove o listener do controller antigo
      oldWidget.controller?.removeListener(_onControllerTextChanged);
      _internalController.removeListener(
        _onControllerTextChanged,
      ); // Remover do interno também

      // Se um novo controller externo foi fornecido, use-o
      if (widget.controller != null) {
        // Se o controller interno era auto-gerenciado, ele deve ser descartado.
        if (oldWidget.controller == null) {
          _internalController.dispose();
        }
        _internalController = widget.controller!;
      } else {
        // Se o controller externo foi removido, crie um novo interno e mantenha o texto
        _internalController = TextEditingController(
          text: _internalController.text,
        );
      }
      // Adiciona o listener ao novo controller interno
      _internalController.addListener(_onControllerTextChanged);
      // Dispara a busca se o texto do novo controller for diferente
      if (_internalController.text.isNotEmpty &&
          _internalController.text != oldWidget.controller?.text) {
        autoCompleteSearch(_internalController.text);
      }
    }
  }

  @override
  void dispose() {
    // Remove o listener para evitar memory leaks
    _internalController.removeListener(_onControllerTextChanged);
    // Descarta o controller apenas se ele foi criado internamente por este widget.
    // Se ele foi passado de fora (widget.controller não era null), o widget pai é responsável por descartá-lo.
    if (widget.controller == null) {
      _internalController.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  void autoCompleteSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          var result = await googlePlace.autocomplete.get(value);
          if (mounted) {
            setState(() {
              predictions = result?.predictions ?? [];
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              predictions = []; // Limpa as previsões em caso de erro
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro na busca de destino: $e')),
            );
          }
        }
      } else {
        setState(() {
          predictions = [];
          _isLoading = false;
        });
      }
    });
  }

  void _clearText() {
    _internalController.clear();
    setState(() {
      predictions = [];
    });
    widget.onPlaceSelected(''); // Notifica o pai que o campo foi limpo
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          TextField(
            controller:
                _internalController, // <<< USE O CONTROLLER INTERNO AQUI
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _internalController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearText,
                      )
                      : null,
            ),
            onChanged: (value) {
              // Quando o texto é alterado manualmente, o listener já cuidará disso
              // autoCompleteSearch(value); // Remova esta linha se o listener já estiver ativo
            },
          ),
          const SizedBox(height: 8),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading &&
              predictions.isEmpty &&
              _internalController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Nenhum resultado encontrado'),
            ),
          if (predictions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(predictions[index].description ?? ''),
                    onTap: () {
                      final descricao = predictions[index].description ?? '';
                      _internalController.text =
                          descricao; // Atualiza o controller interno
                      widget.onPlaceSelected(
                        descricao,
                      ); // Chama o callback para o widget pai
                      setState(() {
                        predictions = []; // Limpa as sugestões após seleção
                      });
                      FocusScope.of(context).unfocus(); // Esconde o teclado
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
