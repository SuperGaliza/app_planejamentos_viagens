// lib/JsonModels/viagem.dart
import 'dart:convert';

class Viagem {
  int? id;
  String titulo;
  String destino;
  double orcamento;
  DateTime dataIda;
  DateTime dataChegada;
  String? corHex;
  int userId;
  double hospedagem;
  double transporte;
  double alimentacao;
  double despesasDiversas;
  double passeios;

  // NOVOS CAMPOS PARA ARMAZENAR DADOS COMPLEXOS
  String? checklistJson;
  String? galleryImagePathsJson;
  String? notes;
  String? linksJson;

  Viagem({
    this.id,
    required this.titulo,
    required this.destino,
    required this.orcamento,
    required this.dataIda,
    required this.dataChegada,
    this.corHex,
    required this.userId,
    this.hospedagem = 0.0,
    this.transporte = 0.0,
    this.alimentacao = 0.0,
    this.despesasDiversas = 0.0,
    this.passeios = 0.0,
    this.checklistJson,
    this.galleryImagePathsJson,
    this.notes,
    this.linksJson,
  });

  // Métodos de ajuda para a checklist
  List<Map<String, dynamic>> getChecklistAsMapList() {
    if (checklistJson == null || checklistJson!.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(checklistJson!);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  void setChecklistFromJsonList(List<Map<String, dynamic>> checklist) {
    checklistJson = jsonEncode(checklist);
  }

  // Métodos de ajuda para a galeria
  List<String> getGalleryImagePaths() {
    if (galleryImagePathsJson == null || galleryImagePathsJson!.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(galleryImagePathsJson!));
    } catch (e) {
      return [];
    }
  }

  void setGalleryImagePaths(List<String> paths) {
    galleryImagePathsJson = jsonEncode(paths);
  }

  // Métodos de ajuda para os links
  List<Map<String, String>> getLinks() {
    if (linksJson == null || linksJson!.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(linksJson!);
      return List<Map<String, String>>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  void setLinks(List<Map<String, String>> links) {
    linksJson = jsonEncode(links);
  }

  factory Viagem.fromMap(Map<String, dynamic> map) {
    return Viagem(
      id: map['id'],
      titulo: map['titulo'],
      destino: map['destino'],
      orcamento: map['orcamento']?.toDouble() ?? 0.0,
      dataIda: DateTime.parse(map['dataIda']),
      dataChegada: DateTime.parse(map['dataChegada']),
      corHex: map['corHex'] as String?,
      userId: map['userId'],
      hospedagem: map['hospedagem']?.toDouble() ?? 0.0,
      transporte: map['transporte']?.toDouble() ?? 0.0,
      alimentacao: map['alimentacao']?.toDouble() ?? 0.0,
      despesasDiversas: map['despesasDiversas']?.toDouble() ?? map['presentes']?.toDouble() ?? 0.0,
      passeios: map['passeios']?.toDouble() ?? 0.0,
      checklistJson: map['checklistJson'],
      galleryImagePathsJson: map['galleryImagePathsJson'],
      notes: map['notes'],
      linksJson: map['linksJson'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'destino': destino,
      'orcamento': orcamento,
      'dataIda': dataIda.toIso8601String(),
      'dataChegada': dataChegada.toIso8601String(),
      'corHex': corHex,
      'userId': userId,
      'hospedagem': hospedagem,
      'transporte': transporte,
      'alimentacao': alimentacao,
      'despesasDiversas': despesasDiversas,
      'passeios': passeios,
      'checklistJson': checklistJson,
      'galleryImagePathsJson': galleryImagePathsJson,
      'notes': notes,
      'linksJson': linksJson,
    };
  }
}