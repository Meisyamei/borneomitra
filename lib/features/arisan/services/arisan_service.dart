import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/services/database_service.dart';
import '../models/arisan_model.dart';
import '../models/peserta_arisan_model.dart';
import '../models/pembayaran_arisan_model.dart';

class ArisanService {
  final DatabaseService _dbService = DatabaseService();

  Future<Database> get _db async => await _dbService.database;

  // ===== ARISAN =====
  Future<List<ArisanModel>> getAllArisan() async {
    final db = await _db;
    final result = await db.query('arisan', orderBy: 'tanggal_mulai DESC');
    return result.map((map) => ArisanModel.fromMap(map)).toList();
  }

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

  Future<int> createArisan(ArisanModel arisan) async {
    final db = await _db;
    return await db.insert('arisan', arisan.toMap());
  }

  Future<int> deleteArisan(int id) async {
    final db = await _db;
    return await db.delete('arisan', where: 'id = ?', whereArgs: [id]);
  }

  // ===== PESERTA ARISAN =====
  Future<List<PesertaArisan>> getPeserta(int arisanId) async {
    final db = await _db;
    
    // Ambil peserta
    final pesertaResult = await db.rawQuery('''
      SELECT pa.*, a.nama as nama_anggota
      FROM peserta_arisan pa
      JOIN anggota a ON pa.anggota_id = a.id
      WHERE pa.arisan_id = ?
      ORDER BY pa.nomor_urut ASC
    ''', [arisanId]);
    
    // Ambil arisan untuk tahu total bulan
    final arisan = await getArisanById(arisanId);
    final totalBulan = arisan?.totalBulan ?? 0;
    
    List<PesertaArisan> result = [];
    
    for (var row in pesertaResult) {
      final pesertaId = row['id'] as int;
      
      // 🔴 AMBIL PEMBAYARAN PER BULAN
      final paymentResult = await db.rawQuery('''
        SELECT periode_ke
        FROM pembayaran_arisan
        WHERE peserta_id = ?
        ORDER BY periode_ke ASC
      ''', [pesertaId]);
      
      // Buat list pembayaran per bulan
      List<bool> pembayaranBulan = List.filled(totalBulan, false);
      for (var payment in paymentResult) {
        final periode = (payment['periode_ke'] as int?) ?? 0;
        if (periode > 0 && periode <= totalBulan) {
          pembayaranBulan[periode - 1] = true;
        }
      }
      
      result.add(PesertaArisan.fromMap(
        row,
        pembayaranBulan: pembayaranBulan,
      ));
    }
    
    return result;
  }

  Future<int> addPeserta(int arisanId, int anggotaId, int nomorUrut) async {
    final db = await _db;
    return await db.insert('peserta_arisan', {
      'arisan_id': arisanId,
      'anggota_id': anggotaId,
      'nomor_urut': nomorUrut,
      'status': 'aktif',
    });
  }

  Future<int> removePeserta(int pesertaId) async {
    final db = await _db;
    return await db.delete('peserta_arisan', where: 'id = ?', whereArgs: [pesertaId]);
  }

  // ===== PEMBAYARAN ARISAN =====
  Future<int> bayarArisan(int pesertaId, int periodeKe, double nominal) async {
    final db = await _db;
    
    // Cek apakah sudah bayar bulan ini
    final existing = await db.query(
      'pembayaran_arisan',
      where: 'peserta_id = ? AND periode_ke = ?',
      whereArgs: [pesertaId, periodeKe],
    );
    
    if (existing.isNotEmpty) {
      return -1; // Sudah bayar
    }
    
    return await db.insert('pembayaran_arisan', {
      'peserta_id': pesertaId,
      'periode_ke': periodeKe,
      'nominal': nominal,
      'tanggal_bayar': DateTime.now().toIso8601String(),
      'status': 'lunas',
    });
  }

  // ===== NEXT BULAN =====
  Future<int> nextBulan(int arisanId) async {
    final db = await _db;
    final arisan = await getArisanById(arisanId);
    if (arisan == null) return 0;
    
    final bulanBaru = arisan.bulanBerjalan + 1;
    
    if (bulanBaru > arisan.totalBulan) {
      // Arisan selesai
      await db.update(
        'arisan',
        {'status': 'selesai', 'bulan_berjalan': bulanBaru},
        where: 'id = ?',
        whereArgs: [arisanId],
      );
      return bulanBaru;
    }
    
    await db.update(
      'arisan',
      {'bulan_berjalan': bulanBaru},
      where: 'id = ?',
      whereArgs: [arisanId],
    );
    return bulanBaru;
  }
}