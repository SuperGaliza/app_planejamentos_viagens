class Usuario {
  int? id;
  String email;
  String senha;

  Usuario({this.id, required this.email, required this.senha});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'email': email, 'senha': senha};

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(id: map['id'], email: map['email'], senha: map['senha']);
  }
}
