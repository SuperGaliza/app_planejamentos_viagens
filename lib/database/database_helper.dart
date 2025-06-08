import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../JsonModels/viagem.dart';
import '../JsonModels/users.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  String usersTable =
      "CREATE TABLE users (usrId INTEGER PRIMARY KEY AUTOINCREMENT, usrName TEXT UNIQUE, usrPassword TEXT, profileImagePath TEXT)";

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'viagens.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE viagens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        destino TEXT NOT NULL,
        orcamento REAL NOT NULL,
        dataIda TEXT NOT NULL,
        dataChegada TEXT NOT NULL,
        corHex TEXT,
        userId INTEGER NOT NULL
      )
    ''');
    await db.execute(usersTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE viagens ADD COLUMN dataChegada TEXT');
      await db.execute('ALTER TABLE viagens ADD COLUMN corHex TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE viagens ADD COLUMN userId INTEGER DEFAULT -1 NOT NULL',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN profileImagePath TEXT');
    }
  }

  // Métodos Viagem
  Future<int> inserirViagem(Viagem viagem) async {
    final db = await database;
    return await db.insert('viagens', viagem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Viagem>> listarViagens(int userId) async {
    final db = await database;
    final maps = await db
        .query('viagens', where: 'userId = ?', whereArgs: [userId], orderBy: 'dataIda');
    return maps.map((map) => Viagem.fromMap(map)).toList();
  }

  Future<int> atualizarViagem(Viagem viagem) async {
    if (viagem.id == null) {
      throw Exception('ID da viagem é obrigatório para atualização.');
    }
    final db = await database;
    return await db.update('viagens', viagem.toMap(),
        where: 'id = ? AND userId = ?', whereArgs: [viagem.id, viagem.userId]);
  }

  Future<int> deletarViagem(int id, int userId) async {
    final db = await database;
    return await db
        .delete('viagens', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  // Métodos para a Tela de Perfil
  Future<Users?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('users', where: 'usrId = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Users.fromMap(maps.first);
    }
    return null;
  }

  Future<int> countPastTrips(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM viagens WHERE userId = ? AND dataChegada < ?',
        [userId, now]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countFutureTrips(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM viagens WHERE userId = ? AND dataIda >= ?',
        [userId, now]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> updateUser(Users user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'usrId = ?',
      whereArgs: [user.usrId],
    );
  }

  // --- MÉTODO PARA ALTERAR A SENHA (O QUE ESTAVA FALTANDO) ---
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    final db = await database;
    var result = await db.query(
      'users',
      where: 'usrId = ? AND usrPassword = ?',
      whereArgs: [userId, oldPassword],
    );

    if (result.isNotEmpty) {
      int rowsAffected = await db.update(
        'users',
        {'usrPassword': newPassword},
        where: 'usrId = ?',
        whereArgs: [userId],
      );
      return rowsAffected > 0;
    } else {
      return false;
    }
  }

  // Métodos de Autenticação
  Future<Users?> login(Users user) async {
    final Database db = await database; // Correção para usar a instância do getter
    var result = await db.query("users",
        where: "usrName = ? AND usrPassword = ?",
        whereArgs: [user.usrName, user.usrPassword],
        limit: 1);
    if (result.isNotEmpty) {
      return Users.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int?> Signup(Users user) async {
    final Database db = await database; // Correção para usar a instância do getter
    try {
      final id = await db.insert('users', user.toMap());
      return id;
    } catch (e) {
      print("Erro ao cadastrar usuário: $e");
      return null;
    }
  }
}