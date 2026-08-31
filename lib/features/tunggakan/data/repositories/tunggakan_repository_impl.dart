import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/tunggakan/domain/entities/tunggakan.dart';
import 'package:Koperasi/features/tunggakan/domain/repositories/tunggakan_repository.dart';
import 'package:Koperasi/features/tunggakan/domain/entities/hampir_jatuh_tempo.dart';

class TunggakanRepositoryImpl implements TunggakanRepository {
  final DatabaseService dbService;

  TunggakanRepositoryImpl(this.dbService);

  Future<Database> get _db async => await dbService.database;

  @override
  Future<Either<Failure, List<Tunggakan>>> getAllTunggakan() async {
    try {
      final db = await _db;
      
      // Update status pinjaman
      await db.rawQuery('''
        UPDATE pinjaman 
        SET status = 'lunas' 
        WHERE sisa_pinjaman <= 0 AND status != 'lunas'
      ''');
      
      await db.rawQuery('''
        UPDATE pinjaman 
        SET status = 'menunggak' 
        WHERE id IN (
          SELECT DISTINCT pinjaman_id 
          FROM angsuran 
          WHERE status = 'belum_bayar' 
            AND tanggal_jatuh_tempo < date('now')
        ) AND status NOT IN ('lunas', 'menunggak')
      ''');
      
      await db.rawQuery('''
        UPDATE pinjaman 
        SET status = 'aktif' 
        WHERE id NOT IN (
          SELECT DISTINCT pinjaman_id 
          FROM angsuran 
          WHERE status = 'belum_bayar' 
            AND tanggal_jatuh_tempo < date('now')
        ) AND sisa_pinjaman > 0 AND status NOT IN ('aktif', 'lunas')
      ''');

      // ===== PERBAIKI: TAMPILKAN PER PINJAMAN, BUKAN PER ANGGOTA =====
      final result = await db.rawQuery('''
        SELECT 
          a.id as anggota_id,
          a.nama as nama_anggota,
          a.nik,
          p.id as pinjaman_id,
          p.jumlah as jumlah_pinjaman,
          p.sisa_pinjaman,
          COUNT(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN 1 END) as jumlah_bulan_tunggakan,
          COALESCE(SUM(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN ang.nominal ELSE 0 END), 0) as total_tunggakan,
          COALESCE(SUM(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN ang.denda ELSE 0 END), 0) as denda_total,
          MIN(ang.tanggal_jatuh_tempo) as tanggal_jatuh_tempo_pertama
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'menunggak'
        GROUP BY a.id, p.id   -- ← GROUP BY ANGGOTA DAN PINJAMAN
        ORDER BY a.nama ASC, jumlah_bulan_tunggakan DESC
      ''');

      print('✅ Query getAllTunggakan berhasil: ${result.length} data');

      final tunggakanList = result
          .map((map) {
            try {
              return _mapToEntity(map);
            } catch (e) {
              print('⚠️ Gagal mapping data: $e, data: $map');
              return null;
            }
          })
          .whereType<Tunggakan>()
          .toList();
      return Right(tunggakanList);
    } catch (e) {
      print('❌ Error getAllTunggakan: $e');
      return Left(DatabaseFailure('Gagal mengambil data tunggakan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Tunggakan>>> getTunggakanByAnggota(
    int anggotaId,
  ) async {
    try {
      final db = await _db;

      final result = await db.rawQuery(
        '''
        SELECT 
          a.id as anggota_id,
          a.nama as nama_anggota,
          a.nik,
          p.id as pinjaman_id,
          p.jumlah as jumlah_pinjaman,
          p.sisa_pinjaman,
          COUNT(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN 1 END) as jumlah_bulan_tunggakan,
          COALESCE(SUM(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN ang.nominal ELSE 0 END), 0) as total_tunggakan,
          COALESCE(SUM(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN ang.denda ELSE 0 END), 0) as denda_total,
          MIN(ang.tanggal_jatuh_tempo) as tanggal_jatuh_tempo_pertama
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'menunggak' AND a.id = ?
        GROUP BY a.id, p.id
      ''',
        [anggotaId],
      );

      final tunggakanList = result.map((map) => _mapToEntity(map)).toList();
      return Right(tunggakanList);
    } catch (e) {
      return Left(
        DatabaseFailure('Gagal mengambil data tunggakan anggota: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Tunggakan>>> getTunggakanKritis() async {
    try {
      final db = await _db;

      final result = await db.rawQuery('''
        SELECT 
          a.id as anggota_id,
          a.nama as nama_anggota,
          a.nik,
          p.id as pinjaman_id,
          p.jumlah as jumlah_pinjaman,
          p.sisa_pinjaman,
          COUNT(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN 1 END) as jumlah_bulan_tunggakan,
          COALESCE(SUM(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN ang.nominal ELSE 0 END), 0) as total_tunggakan,
          COALESCE(SUM(CASE WHEN ang.status = 'belum_bayar' AND ang.tanggal_jatuh_tempo < date('now') THEN ang.denda ELSE 0 END), 0) as denda_total,
          MIN(ang.tanggal_jatuh_tempo) as tanggal_jatuh_tempo_pertama
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'menunggak'
        GROUP BY a.id, p.id
        HAVING jumlah_bulan_tunggakan >= 3
        ORDER BY jumlah_bulan_tunggakan DESC
      ''');

      final tunggakanList = result.map((map) => _mapToEntity(map)).toList();
      return Right(tunggakanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data tunggakan kritis: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalTunggakanCount() async {
    try {
      final db = await _db;

      final result = await db.rawQuery('''
        SELECT COUNT(*) as total
        FROM pinjaman
        WHERE status = 'menunggak'
      ''');

      final total = (result.first['total'] as int?) ?? 0;
      return Right(total);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil total tunggakan: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalNominalTunggakan() async {
    try {
      final db = await _db;

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(ang.nominal), 0) as total
        FROM angsuran ang
        JOIN pinjaman p ON ang.pinjaman_id = p.id
        WHERE p.status = 'menunggak'
          AND ang.status = 'belum_bayar'
      ''');

      final total = (result.first['total'] as num?)?.toDouble() ?? 0;
      return Right(total);
    } catch (e) {
      return Left(
        DatabaseFailure('Gagal mengambil total nominal tunggakan: $e'),
      );
    }
  }

  Tunggakan _mapToEntity(Map<String, dynamic> map) {
    final jumlahBulan = (map['jumlah_bulan_tunggakan'] as int?) ?? 0;

    DateTime tanggalJatuhTempo;
    try {
      tanggalJatuhTempo = DateTime.parse(map['tanggal_jatuh_tempo_pertama']);
    } catch (e) {
      tanggalJatuhTempo = DateTime.now();
      print('⚠️ Gagal parse tanggal: ${map['tanggal_jatuh_tempo_pertama']}');
    }

    final hariTerlambat = DateTime.now().difference(tanggalJatuhTempo).inDays;

    String status;
    if (hariTerlambat >= 30) {
      status = 'kritis';
    } else if (hariTerlambat >= 15) {
      status = 'sedang';
    } else {
      status = 'ringan';
    }

    print(
      '📊 ${map['nama_anggota']} - Telat $hariTerlambat hari - Status: $status',
    );

    return Tunggakan(
      id: map['anggota_id'],
      anggotaId: map['anggota_id'],
      namaAnggota: map['nama_anggota'] ?? 'Unknown',
      nik: map['nik'] ?? '-',
      noHp: '-',
      pinjamanId: map['pinjaman_id'],
      jumlahPinjaman: (map['jumlah_pinjaman'] as num?)?.toDouble() ?? 0,
      sisaPinjaman: (map['sisa_pinjaman'] as num?)?.toDouble() ?? 0,
      jumlahBulanTunggakan: jumlahBulan,
      totalTunggakan: (map['total_tunggakan'] as num?)?.toDouble() ?? 0,
      dendaTotal: (map['denda_total'] as num?)?.toDouble() ?? 0,
      tanggalJatuhTempoTerakhir: tanggalJatuhTempo,
      status: status,
    );
  }

 @override
  Future<Either<Failure, List<HampirJatuhTempo>>> getHampirJatuhTempo() async {
    try {
      final db = await _db;

      print('🔍 Query getHampirJatuhTempo dijalankan...');
      
      // ===== PERBAIKI =====
      final result = await db.rawQuery('''
        SELECT 
          a.id as anggota_id,
          a.nama as nama_anggota,
          a.nik,
          p.id as pinjaman_id,
          ang.id as angsuran_id,
          ang.angsuran_ke,
          ang.nominal,
          ang.tanggal_jatuh_tempo,
          CAST(julianday(ang.tanggal_jatuh_tempo) - julianday('now') AS INTEGER) as hari_tersisa
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status IN ('aktif', 'menunggak')  -- ← PERBAIKI 1
          AND ang.status = 'belum_bayar'
          AND ang.tanggal_jatuh_tempo >= date('now')
          AND ang.tanggal_jatuh_tempo <= date('now', '+3 days')  -- ← PERBAIKI 2
        ORDER BY ang.tanggal_jatuh_tempo ASC
      ''');

      print('✅ getHampirJatuhTempo berhasil: ${result.length} data');

      final hampirJatuhTempoList = result.map((map) {
        final hariTersisa = (map['hari_tersisa'] as int?) ?? 0;

        DateTime tanggalJatuhTempo;
        try {
          tanggalJatuhTempo = DateTime.parse(
            map['tanggal_jatuh_tempo'] as String,
          );
        } catch (e) {
          tanggalJatuhTempo = DateTime.now();
          print('⚠️ Gagal parse tanggal: ${map['tanggal_jatuh_tempo']}');
        }

        return HampirJatuhTempo(
          anggotaId: map['anggota_id'] as int? ?? 0,
          namaAnggota: map['nama_anggota'] as String? ?? 'Unknown',
          nik: map['nik'] as String? ?? '-',
          pinjamanId: map['pinjaman_id'] as int? ?? 0,
          angsuranId: map['angsuran_id'] as int? ?? 0,
          angsuranKe: (map['angsuran_ke'] as num?)?.toInt() ?? 0,
          nominal: (map['nominal'] as num?)?.toDouble() ?? 0,
          tanggalJatuhTempo: tanggalJatuhTempo,
          hariTersisa: hariTersisa,
        );
      }).toList();

      return Right(hampirJatuhTempoList);
    } catch (e) {
      print('❌ Error getHampirJatuhTempo: $e');
      return Left(
        DatabaseFailure('Gagal mengambil data hampir jatuh tempo: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<HampirJatuhTempo>>> getJatuhTempo() async {
    try {
      final db = await _db;
      
      print('🔍 Query getJatuhTempo dijalankan...');
      
      // ===== PERBAIKI =====
      final result = await db.rawQuery('''
        SELECT 
          a.id as anggota_id,
          a.nama as nama_anggota,
          a.nik,
          p.id as pinjaman_id,
          ang.id as angsuran_id,
          ang.angsuran_ke,
          ang.nominal,
          ang.tanggal_jatuh_tempo,
          0 as hari_tersisa  -- ← PERBAIKI 3
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status IN ('aktif', 'menunggak')
          AND ang.status = 'belum_bayar'
          AND date(ang.tanggal_jatuh_tempo) = date('now')
        ORDER BY ang.tanggal_jatuh_tempo ASC
      ''');
      
      print('✅ getJatuhTempo berhasil: ${result.length} data');
      
      final jatuhTempoList = result.map((map) {
        final hariTersisa = (map['hari_tersisa'] as int?) ?? 0;
        
        DateTime tanggalJatuhTempo;
        try {
          tanggalJatuhTempo = DateTime.parse(map['tanggal_jatuh_tempo'] as String);
        } catch (e) {
          tanggalJatuhTempo = DateTime.now();
          print('⚠️ Gagal parse tanggal: ${map['tanggal_jatuh_tempo']}');
        }
        
        return HampirJatuhTempo(
          anggotaId: map['anggota_id'] as int? ?? 0,
          namaAnggota: map['nama_anggota'] as String? ?? 'Unknown',
          nik: map['nik'] as String? ?? '-',
          pinjamanId: map['pinjaman_id'] as int? ?? 0,
          angsuranId: map['angsuran_id'] as int? ?? 0,
          angsuranKe: (map['angsuran_ke'] as num?)?.toInt() ?? 0, 
          nominal: (map['nominal'] as num?)?.toDouble() ?? 0,
          tanggalJatuhTempo: tanggalJatuhTempo,
          hariTersisa: hariTersisa,  // ← PERBAIKI 4 (langsung 0)
        );
      }).toList();
      
      return Right(jatuhTempoList);
    } catch (e) {
      print('❌ Error getJatuhTempo: $e');
      return Left(DatabaseFailure('Gagal mengambil data jatuh tempo: $e'));
    }
  }

}