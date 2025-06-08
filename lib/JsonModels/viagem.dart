// lib/JsonModels/viagem.dart
class Viagem {
  int? id;
  String titulo;
  String destino;
  double orcamento; // Será o total calculado
  DateTime dataIda;
  DateTime dataChegada;
  String? corHex;
  int userId;
  // <<< NOVOS CAMPOS PARA DETALHE DO ORÇAMENTO
  double hospedagem; // Novo campo
  double transporte;
  double alimentacao;
  double
  despesasDiversas; // Renomeado "presentes" para "despesasDiversas" (mais geral)
  double passeios;
  // FIM DOS NOVOS CAMPOS

  Viagem({
    this.id,
    required this.titulo,
    required this.destino,
    required this.orcamento, // Este será o total calculado
    required this.dataIda,
    required this.dataChegada,
    this.corHex,
    required this.userId,
    // <<< Inicialize os novos campos no construtor
    this.hospedagem = 0.0,
    this.transporte = 0.0,
    this.alimentacao = 0.0,
    this.despesasDiversas = 0.0,
    this.passeios = 0.0,
    // FIM DA INICIALIZAÇÃO
  });

  factory Viagem.fromMap(Map<String, dynamic> map) {
    return Viagem(
      id: map['id'],
      titulo: map['titulo'],
      destino: map['destino'],
      orcamento:
          map['orcamento']?.toDouble() ?? 0.0, // Leitura do orçamento total
      dataIda: DateTime.parse(map['dataIda']),
      dataChegada: DateTime.parse(map['dataChegada']),
      corHex: map['corHex'] as String?,
      userId: map['userId'],
      // <<< Leia os novos campos do mapa (com fallback para 0.0 se for nulo)
      hospedagem: map['hospedagem']?.toDouble() ?? 0.0, // Novo campo
      transporte: map['transporte']?.toDouble() ?? 0.0,
      alimentacao: map['alimentacao']?.toDouble() ?? 0.0,
      despesasDiversas:
          map['despesasDiversas']?.toDouble() ??
          map['presentes']?.toDouble() ??
          0.0, // Tentar ler 'despesasDiversas' ou 'presentes' para compatibilidade
      passeios: map['passeios']?.toDouble() ?? 0.0,
      // FIM DA LEITURA
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
      // <<< Escreva os novos campos no mapa
      'hospedagem': hospedagem, // Novo campo
      'transporte': transporte,
      'alimentacao': alimentacao,
      'despesasDiversas': despesasDiversas,
      'passeios': passeios,
      // FIM DA ESCRITA
    };
  }
}
