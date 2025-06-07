import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../JsonModels/viagem.dart';
import '../JsonModels/users.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  // Definição da tabela de usuários
  String usersTable =
      "create table users (usrId INTEGER PRIMARY KEY AUTOINCREMENT, usrName TEXT UNIQUE, usrPassword TEXT)";

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'viagens.db');

    // Aumentar a versão para forçar a execução do onUpgrade e adicionar a coluna userId
    return await openDatabase(
      path,
      version: 3, // <<< AUMENTADO PARA A VERSÃO 3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Criação da tabela de viagens com a nova coluna userId
    await db.execute('''
      CREATE TABLE viagens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        destino TEXT NOT NULL,
        orcamento REAL NOT NULL,
        dataIda TEXT NOT NULL,
        dataChegada TEXT NOT NULL,
        corHex TEXT,
        userId INTEGER NOT NULL -- <<< NOVA COLUNA userId
      )
    ''');
    // Criação da tabela de usuários
    await db.execute(usersTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migração de versão 1 para 2 (já existente)
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE viagens ADD COLUMN dataChegada TEXT');
      await db.execute('ALTER TABLE viagens ADD COLUMN corHex TEXT');
    }
    // Migração de versão 2 para 3 (nova)
    if (oldVersion < 3) {
      // Adiciona a coluna userId à tabela viagens existente
      // DEFAULT -1 é um valor temporário para viagens que existiam antes da migração.
      // É crucial que as novas viagens tenham um userId válido.
      await db.execute(
        'ALTER TABLE viagens ADD COLUMN userId INTEGER DEFAULT -1 NOT NULL',
      );
    }
  }

  // Métodos Viagem

  /// Insere uma nova viagem no banco de dados.
  /// Retorna o ID da nova linha inserida.
  Future<int> inserirViagem(Viagem viagem) async {
    final db = await database;
    // O objeto 'viagem' já deve conter o userId ao ser passado para cá
    return await db.insert(
      'viagens',
      viagem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lista todas as viagens pertencentes a um determinado usuário.
  /// Recebe o [userId] do usuário logado para filtrar as viagens.
  Future<List<Viagem>> listarViagens(int userId) async {
    final db = await database;
    // Filtra as viagens pelo userId
    final maps = await db.query(
      'viagens',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dataIda',
    );
    return maps.map((map) => Viagem.fromMap(map)).toList();
  }

  /// Atualiza uma viagem existente no banco de dados.
  /// A atualização só ocorrerá se a viagem pertencer ao [userId] especificado.
  /// Retorna o número de linhas afetadas.
  Future<int> atualizarViagem(Viagem viagem) async {
    if (viagem.id == null)
      throw Exception('ID da viagem é obrigatório para atualização.');
    final db = await database;
    // Garante que o usuário só pode atualizar suas próprias viagens
    return await db.update(
      'viagens',
      viagem.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [
        viagem.id,
        viagem.userId,
      ], // userId deve estar presente no objeto Viagem
    );
  }

  /// Deleta uma viagem do banco de dados.
  /// A exclusão só ocorrerá se a viagem pertencer ao [userId] especificado.
  /// Retorna o número de linhas afetadas.
  Future<int> deletarViagem(int id, int userId) async {
    final db = await database;
    // Garante que o usuário só pode deletar suas próprias viagens
    return await db.delete(
      'viagens',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Métodos de Autenticação (Login e Cadastro)

  /// Realiza o login de um usuário.
  /// Retorna o objeto [Users] se o login for bem-sucedido, ou null caso contrário.
  ///
  /// NOTA DE SEGURANÇA: Para um aplicativo em produção, a senha DEVERIA
  /// ser hasheada (e salgada) antes de ser armazenada e comparada.
  Future<Users?> login(Users user) async {
    final Database db = await _initDB();

    // Usando query() com whereArgs para prevenir SQL Injection
    var result = await db.query(
      "users",
      where: "usrName = ? AND usrPassword = ?",
      whereArgs: [user.usrName, user.usrPassword], // Lembre-se do hash da senha
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Users.fromMap(result.first); // Retorna o objeto Users completo
    } else {
      return null;
    }
  }

  /// Cadastra um novo usuário no banco de dados.
  /// Retorna o ID da nova linha inserida se bem-sucedido, ou null em caso de falha
  /// (ex: nome de usuário já existente devido à restrição UNIQUE).
  ///
  /// NOTA DE SEGURANÇA: Para um aplicativo em produção, a senha DEVERIA
  /// ser hasheada (e salgada) antes de ser armazenada.
  Future<int?> Signup(Users user) async {
    final Database db = await _initDB();
    try {
      final id = await db.insert('users', user.toMap());
      return id;
    } catch (e) {
      print("Erro ao cadastrar usuário: $e");
      // Pode adicionar lógica para verificar se o erro é por usuário duplicado
      return null;
    }
  }
}
