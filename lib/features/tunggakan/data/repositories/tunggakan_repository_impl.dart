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
        WHERE p.status = 'aktif'
        GROUP BY a.id
        HAVING jumlah_bulan_tunggakan > 0
        ORDER BY jumlah_bulan_tunggakan DESC, total_tunggakan DESC
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
        WHERE p.status = 'aktif' AND a.id = ?
        GROUP BY a.id
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
        WHERE p.status = 'aktif'
        GROUP BY a.id
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
        SELECT COUNT(DISTINCT a.id) as total
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'aktif'
          AND ang.status = 'belum_bayar'
          AND ang.tanggal_jatuh_tempo < date('now')
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
        WHERE p.status = 'aktif'
          AND ang.status = 'belum_bayar'
          AND ang.tanggal_jatuh_tempo < date('now')
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

    // Ambil tanggal jatuh tempo pertama
    DateTime tanggalJatuhTempo;
    try {
      tanggalJatuhTempo = DateTime.parse(map['tanggal_jatuh_tempo_pertama']);
    } catch (e) {
      tanggalJatuhTempo = DateTime.now();
      print('⚠️ Gagal parse tanggal: ${map['tanggal_jatuh_tempo_pertama']}');
    }

    // Hitung hari terlambat dari tanggal jatuh tempo pertama
    final hariTerlambat = DateTime.now().difference(tanggalJatuhTempo).inDays;

    // Tentukan status berdasarkan hari terlambat
    String status;
    if (hariTerlambat >= 30) {
      status = 'kritis';
    } else if (hariTerlambat >= 15) {
      status = 'sedang';
    } else {
      status = 'ringan';
    }

    // Debug print
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
      WHERE p.status = 'aktif'
        AND ang.status = 'belum_bayar'
        AND ang.tanggal_jatuh_tempo > date('now')
        AND ang.tanggal_jatuh_tempo <= date('now', '+3 days')  
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
      
      // Ambil semua yang sudah lewat jatuh tempo (termasuk yang sudah lewat)
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
          CAST(julianday('now') - julianday(ang.tanggal_jatuh_tempo) AS INTEGER) as hari_tersisa
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'aktif'
          AND ang.status = 'belum_bayar'
          AND ang.tanggal_jatuh_tempo < date('now')  -- SUDAH LEWAT JATUH TEMPO
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
          hariTersisa: -hariTersisa, // Negative value untuk yang sudah lewat
        );
      }).toList();
      
      return Right(jatuhTempoList);
    } catch (e) {
      print('❌ Error getJatuhTempo: $e');
      return Left(DatabaseFailure('Gagal mengambil data jatuh tempo: $e'));
    }
  }
}
