import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../security/hash_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    // INISIALISASI KHUSUS UNTUK LINUX/DESKTOP
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, AppConstants.dbName);
    
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    print('=== MEMBUAT DATABASE BARU ===');
    // Tabel Admin
    await db.execute('''
      CREATE TABLE admin(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password_hash TEXT,
        nama_lengkap TEXT,
        created_at TEXT
      )
    ''');
    
    // Insert default admin
    await db.insert('admin', {
      'username': 'admin',
      'password_hash': HashService.hashPassword('admin123'),
      'nama_lengkap': 'Administrator',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Tabel Anggota
    await db.execute('''
      CREATE TABLE anggota(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nik TEXT UNIQUE,
        nama TEXT,
        encrypted_data TEXT,
        tanggal_daftar TEXT,
        total_simpanan REAL DEFAULT 0,
        total_pinjaman REAL DEFAULT 0,
        status TEXT DEFAULT 'aktif',
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    print('=== TABEL ANGGOTA DIBUAT DENGAN KOLOM status ===');
    
    // Tabel Simpanan
    await db.execute('''
      CREATE TABLE simpanan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anggota_id INTEGER,
        jenis TEXT,
        nominal REAL,
        tanggal TEXT,
        keterangan TEXT,
        created_at TEXT,
        FOREIGN KEY(anggota_id) REFERENCES anggota(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabel Pinjaman
    await db.execute('''
      CREATE TABLE pinjaman(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anggota_id INTEGER,
        jumlah REAL,
        bunga REAL,
        tenor INTEGER,
        tanggal_pinjam TEXT,
        status TEXT,
        denda_keterlambatan REAL DEFAULT 50000,
        sisa_pinjaman REAL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY(anggota_id) REFERENCES anggota(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabel Angsuran
    await db.execute('''
      CREATE TABLE angsuran(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pinjaman_id INTEGER,
        angsuran_ke INTEGER,
        nominal REAL,
        denda REAL DEFAULT 0,
        tanggal_jatuh_tempo TEXT,
        tanggal_bayar TEXT,
        status TEXT,
        created_at TEXT,
        FOREIGN KEY(pinjaman_id) REFERENCES pinjaman(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabel Arisan
    await db.execute('''
      CREATE TABLE arisan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT,
        iuran REAL,
        tanggal_mulai TEXT,
        tanggal_selesai TEXT,
        status TEXT,
        created_at TEXT
      )
    ''');
    
    // Tabel Peserta Arisan
    await db.execute('''
      CREATE TABLE peserta_arisan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        arisan_id INTEGER,
        anggota_id INTEGER,
        nomor_urut INTEGER,
        status TEXT,
        tanggal_menang TEXT,
        created_at TEXT,
        FOREIGN KEY(arisan_id) REFERENCES arisan(id) ON DELETE CASCADE,
        FOREIGN KEY(anggota_id) REFERENCES anggota(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabel Pembayaran Arisan
    await db.execute('''
      CREATE TABLE pembayaran_arisan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        peserta_id INTEGER,
        periode_ke INTEGER,
        nominal REAL,
        tanggal_bayar TEXT,
        status TEXT,
        created_at TEXT,
        FOREIGN KEY(peserta_id) REFERENCES peserta_arisan(id) ON DELETE CASCADE
      )
    ''');
    
    // Index untuk performa
    await db.execute('CREATE INDEX idx_anggota_nik ON anggota(nik)');
    await db.execute('CREATE INDEX idx_anggota_nama ON anggota(nama)');
    await db.execute('CREATE INDEX idx_pinjaman_status ON pinjaman(status)');
    await db.execute('CREATE INDEX idx_angsuran_status ON angsuran(status)');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
       await db.execute('ALTER TABLE anggota ADD COLUMN status TEXT DEFAULT "aktif"');
      // Migrasi jika diperlukan
    }
  }
  
  // Generic CRUD methods
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(table, data);
  }
  
  Future<int> update(String table, int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
  
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }
  
  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }
  
  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    return result.length;
  }
  
  // ============ INI YANG DIPERBAIKI ============
  // Method transaction dengan parameter Transaction (BUKAN Database)
  Future<void> transaction(Future<void> Function(Transaction txn) action) async {
    final db = await database;
    await db.transaction((txn) async {
      await action(txn);
    });
  }
  // =============================================
}