import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/viagem.dart';
import '../models/usuario.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

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
      version: 2,
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
        corHex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        senha TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE viagens ADD COLUMN dataChegada TEXT');
      await db.execute('ALTER TABLE viagens ADD COLUMN corHex TEXT');
    }
  }

  // Métodos Viagem
  Future<int> inserirViagem(Viagem viagem) async {
    final db = await database;
    return await db.insert(
      'viagens',
      viagem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Viagem>> listarViagens() async {
    final db = await database;
    final maps = await db.query('viagens', orderBy: 'dataIda');
    return maps.map((map) => Viagem.fromMap(map)).toList();
  }

  Future<int> atualizarViagem(Viagem viagem) async {
    if (viagem.id == null) throw Exception('ID obrigatório para atualização.');
    final db = await database;
    return await db.update(
      'viagens',
      viagem.toMap(),
      where: 'id = ?',
      whereArgs: [viagem.id],
    );
  }

  Future<int> deletarViagem(int id) async {
    final db = await database;
    return await db.delete('viagens', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos Usuário
  Future<int> inserirUsuario(Usuario usuario) async {
    try {
      final db = await database;
      return await db.insert('usuarios', usuario.toMap());
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao inserir usuário: $e');
      return -1;
    }
  }

  Future<Usuario?> autenticarUsuario(String email, String senha) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [email, senha],
    );
    return result.isNotEmpty ? Usuario.fromMap(result.first) : null;
  }

  Future<void> fecharBanco() async {
    final db = await database;
    await db.close();
  }
}
