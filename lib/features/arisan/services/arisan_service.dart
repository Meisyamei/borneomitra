import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/services/database_service.dart';
import '../models/arisan_model.dart';

class ArisanService {
  final DatabaseService _dbService = DatabaseService();

  Future<Database> get _db async => await _dbService.database;

  // Get all arisan
  Future<List<ArisanModel>> getAllArisan() async {
    final db = await _db;
    final result = await db.query('arisan', orderBy: 'tanggal_mulai DESC');
    return result.map((map) => ArisanModel.fromMap(map)).toList();
  }

  // Get arisan by id
  Future<ArisanModel?> getArisanById(int id) async {
    final db = await _db;
    final result = await db.query(
      'arisan',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ArisanModel.fromMap(result.first);
  }

  // Create arisan
  Future<int> createArisan(ArisanModel arisan) async {
    final db = await _db;
    return await db.insert('arisan', arisan.toMap());
  }

  // Update arisan
  Future<int> updateArisan(ArisanModel arisan) async {
    final db = await _db;
    return await db.update(
      'arisan',
      arisan.toMap(),
      where: 'id = ?',
      whereArgs: [arisan.id],
    );
  }

  // Delete arisan
  Future<int> deleteArisan(int id) async {
    final db = await _db;
    return await db.delete('arisan', where: 'id = ?', whereArgs: [id]);
  }

  // Update status arisan
  Future<int> updateStatus(int id, String status) async {
    final db = await _db;
    return await db.update(
      'arisan',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get peserta arisan
  Future<List<Map<String, dynamic>>> getPeserta(int arisanId) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT pa.*, a.nama as nama_anggota 
      FROM peserta_arisan pa
      JOIN anggota a ON pa.anggota_id = a.id
      WHERE pa.arisan_id = ?
      ORDER BY pa.nomor_urut ASC
    ''', [arisanId]);
  }

  // Add peserta ke arisan
  Future<int> addPeserta(int arisanId, int anggotaId, int nomorUrut) async {
    final db = await _db;
    return await db.insert('peserta_arisan', {
      'arisan_id': arisanId,
      'anggota_id': anggotaId,
      'nomor_urut': nomorUrut,
      'status': 'aktif',
    });
  }

  // Remove peserta
  Future<int> removePeserta(int pesertaId) async {
    final db = await _db;
    return await db.delete('peserta_arisan', where: 'id = ?', whereArgs: [pesertaId]);
  }
}