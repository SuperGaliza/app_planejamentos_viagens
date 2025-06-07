class Viagem {
  int? id;
  String titulo;
  String destino;
  double orcamento;
  DateTime dataIda;
  DateTime dataChegada;
  String? corHex;
  int userId; // <<--- NOVO CAMPO: ID do usuário proprietário da viagem

  Viagem({
    this.id,
    required this.titulo,
    required this.destino,
    required this.orcamento,
    required this.dataIda,
    required this.dataChegada,
    this.corHex,
    required this.userId, // <<--- Adicionar ao construtor
  });

  factory Viagem.fromMap(Map<String, dynamic> map) {
    return Viagem(
      id: map['id'],
      titulo: map['titulo'],
      destino: map['destino'],
      orcamento: map['orcamento'],
      dataIda: DateTime.parse(map['dataIda']),
      dataChegada: DateTime.parse(map['dataChegada']),
      corHex: map['corHex'] as String?,
      userId: map['userId'], // <<--- Ler do mapa
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
      'userId': userId, // <<--- Escrever no mapa
    };
  }
}
