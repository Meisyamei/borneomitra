import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/services/database_service.dart';
import '../../domain/entities/notifikasi.dart';

class NotifikasiLocalDataSource {
  final DatabaseService dbService;

  NotifikasiLocalDataSource(this.dbService);

  Future<Database> get _db async => await dbService.database;

  // Simpan notifikasi
  Future<void> saveNotifikasi(Notifikasi notifikasi) async {
    final db = await _db;
    await db.insert('notifikasi', notifikasi.toMap());
  }

  // Ambil semua notifikasi (belum dihapus)
  Future<List<Notifikasi>> getAllNotifikasi() async {
    final db = await _db;
    final result = await db.query(
      'notifikasi',
      where: 'dihapus = 0',
      orderBy: 'tanggal DESC',
    );
    return result.map((map) => Notifikasi.fromMap(map)).toList();
  }

  // Ambil notifikasi yang belum dibaca
  Future<List<Notifikasi>> getNotifikasiBelumDibaca() async {
    final db = await _db;
    final result = await db.query(
      'notifikasi',
      where: 'dibaca = 0 AND dihapus = 0',
      orderBy: 'tanggal DESC',
    );
    return result.map((map) => Notifikasi.fromMap(map)).toList();
  }

  // Tandai sudah dibaca
  Future<void> markAsRead(int id) async {
    final db = await _db;
    await db.update(
      'notifikasi',
      {'dibaca': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tandai sudah dibaca semua
  Future<void> markAllAsRead() async {
    final db = await _db;
    await db.update(
      'notifikasi',
      {'dibaca': 1},
      where: 'dibaca = 0 AND dihapus = 0',
    );
  }

  // Hapus notifikasi (soft delete)
  Future<void> deleteNotifikasi(int id) async {
    final db = await _db;
    await db.update(
      'notifikasi',
      {'dihapus': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hapus notifikasi yang sudah expired (>15 hari) dan sudah dihapus
  Future<void> deleteExpiredNotifikasi() async {
    final db = await _db;
    final expiredDate = DateTime.now().subtract(const Duration(days: 15));
    await db.delete(
      'notifikasi',
      where: 'tanggal < ? AND dihapus = 1',
      whereArgs: [expiredDate.toIso8601String()],
    );
  }

  // Hitung notifikasi belum dibaca
  Future<int> getUnreadCount() async {
    final db = await _db;
    final result = await db.query(
      'notifikasi',
      where: 'dibaca = 0 AND dihapus = 0',
    );
    return result.length;
  }
}