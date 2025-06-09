// lib/JsonModels/viagem.dart
// Certifique-se de ter import 'dart:convert'; para jsonEncode/jsonDecode
import 'dart:convert'; // Para trabalhar com JSON
import 'package:flutter/material.dart'; // Mantido caso haja alguma dependência, mas pode não ser necessário aqui

class Viagem {
  int? id;
  String titulo;
  String destino;
  double orcamento; // Será o total calculado
  DateTime dataIda;
  DateTime dataChegada;
  String? corHex;
  int userId;
  double hospedagem;
  double transporte;
  double alimentacao;
  double despesasDiversas;
  double passeios;
  // <<< NOVO CAMPO: Para armazenar a checklist como JSON
  String? checklistJson; // String JSON da checklist
  // FIM DO NOVO CAMPO

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
    this.checklistJson, // <<< Adicione ao construtor
  });

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
      despesasDiversas:
          map['despesasDiversas']?.toDouble() ??
          map['presentes']?.toDouble() ??
          0.0,
      passeios: map['passeios']?.toDouble() ?? 0.0,
      checklistJson: map['checklistJson'] as String?, // <<< Leia do mapa
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
      'checklistJson': checklistJson, // <<< Escreva no mapa
    };
  }

  // --- MÉTODOS DE CONVENIÊNCIA PARA CHECKLIST ---
  // Para converter o JSON da checklist para List<Map<String, dynamic>>
  List<Map<String, dynamic>> getChecklistAsMapList() {
    if (checklistJson == null || checklistJson!.isEmpty) {
      return [];
    }
    try {
      // jsonDecode retorna um List<dynamic>, precisamos converter para List<Map<String, dynamic>>
      return (jsonDecode(checklistJson!) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print("Erro ao decodificar checklist JSON: $e");
      return [];
    }
  }

  // Para atualizar o JSON da checklist a partir de List<Map<String, dynamic>>
  void setChecklistFromJsonList(List<Map<String, dynamic>> checklist) {
    checklistJson = jsonEncode(checklist);
  }
}
