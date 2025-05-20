import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

class DestinoAutocomplete extends StatefulWidget {
  final Function(String) onPlaceSelected;
  final double height;
  final String hintText;
  final String apiKey;

  const DestinoAutocomplete({
    super.key,
    required this.onPlaceSelected,
    required this.apiKey,
    this.height = 250,
    this.hintText = 'Digite o destino',
  });

  @override
  State<DestinoAutocomplete> createState() => _DestinoAutocompleteState();
}

class _DestinoAutocompleteState extends State<DestinoAutocomplete> {
  final _controller = TextEditingController();
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(widget.apiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void autoCompleteSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        setState(() => _isLoading = true);
        var result = await googlePlace.autocomplete.get(value);
        if (mounted) {
          setState(() {
            predictions = result?.predictions ?? [];
            _isLoading = false;
          });
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
    _controller.clear();
    setState(() {
      predictions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _controller.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearText,
                      )
                      : null,
            ),
            onChanged: autoCompleteSearch,
          ),
          const SizedBox(height: 8),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && predictions.isEmpty)
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
                      _controller.text = descricao;
                      widget.onPlaceSelected(descricao);
                      setState(() {
                        predictions = [];
                      });
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
