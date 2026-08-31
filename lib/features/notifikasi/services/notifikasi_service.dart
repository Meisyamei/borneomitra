import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/services/database_service.dart';
import '../data/datasources/notifikasi_local_datasource.dart';
import '../domain/entities/notifikasi.dart';

class NotifikasiService {
  final DatabaseService dbService;

  NotifikasiService(this.dbService);

  Future<void> generateNotifikasi() async {
    try {
      final db = await dbService.database;
      final notifSource = NotifikasiLocalDataSource(dbService);
      
      print('🔍 Generating notifikasi...');
      
      // 🔴 HAPUS SEMUA NOTIFIKASI LAMA
      await db.delete('notifikasi');
      print('🧹 Old notifikasi deleted');

      // 1. Cek tunggakan
      final tunggakanResult = await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT a.id) as total,
          COALESCE(SUM(ang.nominal), 0) as nominal
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'menunggak'
          AND ang.status = 'belum_bayar'
      ''');
      
      final totalTunggakan = tunggakanResult.first['total'] as int? ?? 0;
      final nominalTunggakan = (tunggakanResult.first['nominal'] as num?)?.toDouble() ?? 0;
      print('📊 Total tunggakan: $totalTunggakan, nominal: $nominalTunggakan');

      // 2. Cek tunggakan kritis
      final kritisResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT a.id) as total
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'menunggak'
          AND ang.status = 'belum_bayar'
          AND julianday('now') - julianday(ang.tanggal_jatuh_tempo) > 30
      ''');
      final totalKritis = kritisResult.first['total'] as int? ?? 0;
      print('📊 Total kritis: $totalKritis');

      // 3. Cek hampir jatuh tempo
      final hampirResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT a.id) as total
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'aktif'
          AND ang.status = 'belum_bayar'
          AND ang.tanggal_jatuh_tempo >= date('now')
          AND ang.tanggal_jatuh_tempo <= date('now', '+3 days')
      ''');
      final totalHampir = hampirResult.first['total'] as int? ?? 0;
      print('📊 Total hampir: $totalHampir');

      // 4. Cek jatuh tempo hari ini
      final hariIniResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT a.id) as total
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status IN ('aktif', 'menunggak')
          AND ang.status = 'belum_bayar'
          AND date(ang.tanggal_jatuh_tempo) = date('now')
      ''');
      final totalHariIni = hariIniResult.first['total'] as int? ?? 0;
      print('📊 Total hari ini: $totalHariIni');

      int idCounter = DateTime.now().millisecondsSinceEpoch;
      int savedCount = 0;

      // 🔴 BUAT NOTIFIKASI
      if (totalTunggakan > 0) {
        await notifSource.saveNotifikasi(
          Notifikasi(
            id: idCounter++,
            judul: '⚠️ Tunggakan Terdeteksi',
            pesan: '$totalTunggakan anggota menunggak dengan total Rp${nominalTunggakan.toStringAsFixed(0)}',
            jenis: 'danger',
            tanggal: DateTime.now(),
          ),
        );
        savedCount++;
      }

      if (totalKritis > 0) {
        await notifSource.saveNotifikasi(
          Notifikasi(
            id: idCounter++,
            judul: '🔴 Tunggakan Kritis',
            pesan: '$totalKritis anggota memiliki tunggakan lebih dari 30 hari',
            jenis: 'danger',
            tanggal: DateTime.now(),
          ),
        );
        savedCount++;
      }

      if (totalHampir > 0) {
        await notifSource.saveNotifikasi(
          Notifikasi(
            id: idCounter++,
            judul: '⏰ Hampir Jatuh Tempo',
            pesan: '$totalHampir anggota akan jatuh tempo dalam 1-3 hari',
            jenis: 'warning',
            tanggal: DateTime.now(),
          ),
        );
        savedCount++;
      }

      if (totalHariIni > 0) {
        await notifSource.saveNotifikasi(
          Notifikasi(
            id: idCounter++,
            judul: '📅 Jatuh Tempo Hari Ini',
            pesan: '$totalHariIni anggota jatuh tempo hari ini',
            jenis: 'warning',
            tanggal: DateTime.now(),
          ),
        );
        savedCount++;
      }

      // 🔴 NOTIFIKASI POSITIF
      if (totalTunggakan == 0 && totalKritis == 0 && totalHampir == 0 && totalHariIni == 0) {
        await notifSource.saveNotifikasi(
          Notifikasi(
            id: idCounter++,
            judul: '✅ Semua Lancar',
            pesan: 'Tidak ada tunggakan atau jatuh tempo. Semua angsuran berjalan lancar!',
            jenis: 'success',
            tanggal: DateTime.now(),
          ),
        );
        savedCount++;
      }

      print('✅ Notifikasi generated: $savedCount notifikasi disimpan');
    } catch (e) {
      print('❌ Error generate notifikasi: $e');
    }
  }
}