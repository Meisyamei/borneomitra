import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/core/services/api_service.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';

class SimpananRepositoryImpl implements SimpananRepository {
  final DatabaseService dbService;

  SimpananRepositoryImpl(this.dbService);

  Future<Database> get _db async => await dbService.database;

  @override
  Future<Either<Failure, List<Simpanan>>> getAllSimpanan() async {
    try {
      final db = await _db;
      final result = await db.query(
        'simpanan',
        orderBy: 'tanggal DESC',
      );

      final Map<int, String> anggotaNama = await _getAnggotaNamaMap();

      final simpananList = result.map((map) {
        return Simpanan(
          id: map['id'] as int?,
          anggotaId: map['anggota_id'] as int,
          jenis: map['jenis'] as String,
          tipe: map['tipe'] as String? ?? 'masuk',
          nominal: (map['nominal'] as num).toDouble(),
          tanggal: DateTime.parse(map['tanggal'] as String),
          keterangan: map['keterangan'] as String?,
          namaAnggota: anggotaNama[map['anggota_id'] as int] ?? 'Unknown',
        );
      }).toList();

      return Right(simpananList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data simpanan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Simpanan>>> getSimpananByAnggota(int anggotaId) async {
    try {
      final db = await _db;
      final result = await db.query(
        'simpanan',
        where: 'anggota_id = ?',
        whereArgs: [anggotaId],
        orderBy: 'tanggal DESC',
      );

      final Map<int, String> anggotaNama = await _getAnggotaNamaMap();

      final simpananList = result.map((map) {
        return Simpanan(
          id: map['id'] as int?,
          anggotaId: map['anggota_id'] as int,
          jenis: map['jenis'] as String,
          tipe: map['tipe'] as String? ?? 'masuk',
          nominal: (map['nominal'] as num).toDouble(),
          tanggal: DateTime.parse(map['tanggal'] as String),
          keterangan: map['keterangan'] as String?,
          namaAnggota: anggotaNama[map['anggota_id'] as int] ?? 'Unknown',
        );
      }).toList();

      return Right(simpananList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data simpanan: $e'));
    }
  }

   @override
  Future<Either<Failure, void>> createSimpanan(Simpanan simpanan) async {
    try {
      final db = await _db;

      await db.transaction((txn) async {
        await txn.insert('simpanan', {
          'anggota_id': simpanan.anggotaId,
          'jenis': simpanan.jenis,
          'tipe': simpanan.tipe,
          'nominal': simpanan.nominal,
          'tanggal': simpanan.tanggal.toIso8601String(),
          'keterangan': simpanan.keterangan,
        });
        
        // try {
        //   await ApiService.postSimpanan({
        //     'anggota_id': simpanan.anggotaId,
        //     'jenis': simpanan.jenis,
        //     'tipe': simpanan.tipe,
        //     'nominal': simpanan.nominal,
        //     'tanggal': simpanan.tanggal.toIso8601String().substring(0, 10),
        //     'keterangan': simpanan.keterangan,
        //   });
        //   print('✅ Simpanan berhasil dikirim ke server');
        // } catch (e) {
        //   print('⚠️ Gagal kirim simpanan ke server: $e');
        // }

        // ===== 3. UPDATE TOTAL SIMPANAN ANGGOTA =====
        if (simpanan.tipe == 'masuk') {
          await txn.rawUpdate(
            'UPDATE anggota SET total_simpanan = total_simpanan + ? WHERE id = ?',
            [simpanan.nominal, simpanan.anggotaId],
          );
        } else if (simpanan.tipe == 'keluar') {
          await txn.rawUpdate(
            'UPDATE anggota SET total_simpanan = total_simpanan - ? WHERE id = ?',
            [simpanan.nominal, simpanan.anggotaId],
          );
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan simpanan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> tarikSimpanan(
    int anggotaId,
    double nominal,
    String? keterangan,
  ) async {
    try {
      final db = await _db;
      
      // Cek saldo cukup
      final saldoResult = await db.rawQuery(
        'SELECT total_simpanan FROM anggota WHERE id = ?',
        [anggotaId],
      );
      
      if (saldoResult.isEmpty) {
        return Left(DatabaseFailure('Anggota tidak ditemukan'));
      }
      
      final saldoSekarang = (saldoResult.first['total_simpanan'] as num?)?.toDouble() ?? 0;
      
      if (nominal > saldoSekarang) {
        return Left(ValidationFailure('Saldo tidak mencukupi'));
      }
      
      print("========== SEBELUM TARIK ==========");

      final anggota = await db.query("anggota");
      for (var row in anggota) {
        print(row);
      }

      final simpanan = await db.query("simpanan");
      for (var row in simpanan) {
        print(row);
      }

      print("==================================");

      await db.transaction((txn) async {
        // Catat penarikan sebagai transaksi "keluar"
        await txn.insert('simpanan', {
          'anggota_id': anggotaId,
          'jenis': 'sukarela',
          'tipe': 'keluar',
          'nominal': nominal,
          'tanggal': DateTime.now().toIso8601String(),
          'keterangan': 'Penarikan: ${keterangan ?? 'Tarik dana'}',
        });


        
        // Kurangi total simpanan anggota
        await txn.rawUpdate(
          'UPDATE anggota SET total_simpanan = total_simpanan - ? WHERE id = ?',
          [nominal, anggotaId],
        );
      });
      
      print("========== SETELAH TARIK ==========");

      final anggota2 = await db.query("anggota");
      for (var row in anggota2) {
        print(row);
      }

      final simpanan2 = await db.query("simpanan");
      for (var row in simpanan2) {
        print(row);
      }

      print("==================================");

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal tarik simpanan: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalSimpanan() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(nominal), 0) as total 
        FROM simpanan 
        WHERE tipe = 'masuk'
      ''');
      final total = (result.first['total'] as num?)?.toDouble() ?? 0;
      return Right(total);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil total simpanan: $e'));
    }
  }

  @override
Future<Either<Failure, double>> getTotalSimpananByAnggota(int anggotaId) async {
  try {
    final db = await _db;
    
    final masukResult = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total 
      FROM simpanan 
      WHERE anggota_id = ? AND tipe = 'masuk'
    ''', [anggotaId]);
    final totalMasuk = (masukResult.first['total'] as num?)?.toDouble() ?? 0;
    
    final keluarResult = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total 
      FROM simpanan 
      WHERE anggota_id = ? AND tipe = 'keluar'
    ''', [anggotaId]);
    final totalKeluar = (keluarResult.first['total'] as num?)?.toDouble() ?? 0;
    
    final saldo = totalMasuk - totalKeluar;
    
    return Right(saldo);
  } catch (e) {
    return Left(DatabaseFailure('Gagal mengambil total simpanan anggota: $e'));
  }
}

  @override
  Future<Either<Failure, Map<String, double>>> getTotalSimpananPerJenis() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT 
          jenis, 
          COALESCE(SUM(CASE WHEN tipe = 'masuk' THEN nominal ELSE -nominal END), 0) as total 
        FROM simpanan 
        GROUP BY jenis
      ''');

      final Map<String, double> totalPerJenis = {};
      for (var row in result) {
        final jenis = row['jenis'] as String;
        final total = (row['total'] as num?)?.toDouble() ?? 0;
        totalPerJenis[jenis] = total;
      }

      return Right(totalPerJenis);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil total simpanan per jenis: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Simpanan>>> getSimpananByPeriode(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _db;
      final result = await db.query(
        'simpanan',
        where: 'tanggal >= ? AND tanggal < ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'tanggal DESC',
      );

      final Map<int, String> anggotaNama = await _getAnggotaNamaMap();

      final simpananList = result.map((map) {
        return Simpanan(
          id: map['id'] as int?,
          anggotaId: map['anggota_id'] as int,
          jenis: map['jenis'] as String,
          tipe: map['tipe'] as String? ?? 'masuk',
          nominal: (map['nominal'] as num).toDouble(),
          tanggal: DateTime.parse(map['tanggal'] as String),
          keterangan: map['keterangan'] as String?,
          namaAnggota: anggotaNama[map['anggota_id'] as int] ?? 'Unknown',
        );
      }).toList();

      return Right(simpananList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data simpanan per periode: $e'));
    }
  }

  @override
  Future<Either<Failure, Simpanan>> getSimpananById(int id) async {
    try {
      final db = await _db;
      final result = await db.query(
        'simpanan',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        return Left(DatabaseFailure('Simpanan tidak ditemukan'));
      }

      final map = result.first;
      final Map<int, String> anggotaNama = await _getAnggotaNamaMap();

      final simpanan = Simpanan(
        id: map['id'] as int?,
        anggotaId: map['anggota_id'] as int,
        jenis: map['jenis'] as String,
        tipe: map['tipe'] as String? ?? 'masuk',
        nominal: (map['nominal'] as num).toDouble(),
        tanggal: DateTime.parse(map['tanggal'] as String),
        keterangan: map['keterangan'] as String?,
        namaAnggota: anggotaNama[map['anggota_id'] as int] ?? 'Unknown',
      );

      return Right(simpanan);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil simpanan: $e'));
    }
  }

  // Helper Methods
  Future<Map<int, String>> _getAnggotaNamaMap() async {
    final db = await _db;
    final anggotaResult = await db.query('anggota', columns: ['id', 'nama']);
    final Map<int, String> map = {};
    for (var row in anggotaResult) {
      map[row['id'] as int] = row['nama'] as String;
    }
    return map;
  }
}