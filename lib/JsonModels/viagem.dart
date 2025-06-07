class Viagem {
  int? id;
  String titulo;
  String destino;
  double orcamento;
  DateTime dataIda;
  DateTime dataChegada;
  String? corHex; // agora é opcional

  Viagem({
    this.id,
    required this.titulo,
    required this.destino,
    required this.orcamento,
    required this.dataIda,
    required this.dataChegada,
    this.corHex,
  });

  factory Viagem.fromMap(Map<String, dynamic> map) {
    return Viagem(
      id: map['id'],
      titulo: map['titulo'],
      destino: map['destino'],
      orcamento: map['orcamento'],
      dataIda: DateTime.parse(map['dataIda']),
      dataChegada: DateTime.parse(map['dataChegada']),
      corHex: map['corHex'] as String?, // permite null
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
    };
  }
}
