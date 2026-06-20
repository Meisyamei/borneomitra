import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
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
          nominal: (map['nominal'] as num).toDouble(),
          tanggal: DateTime.parse(map['tanggal'] as String),
          keterangan: map['keterangan'] as String?,
          namaAnggota: anggotaNama[map['anggota_id'] as int] ?? 'Unknown',
        );
      }).toList();

      return Right(simpananList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data simpanan anggota: $e'));
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
      );

      if (result.isEmpty) {
        return Left(DatabaseFailure('Simpanan tidak ditemukan'));
      }

      final Map<int, String> anggotaNama = await _getAnggotaNamaMap();
      final map = result.first;

      return Right(Simpanan(
        id: map['id'] as int?,
        anggotaId: map['anggota_id'] as int,
        jenis: map['jenis'] as String,
        nominal: (map['nominal'] as num).toDouble(),
        tanggal: DateTime.parse(map['tanggal'] as String),
        keterangan: map['keterangan'] as String?,
        namaAnggota: anggotaNama[map['anggota_id'] as int] ?? 'Unknown',
      ));
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
          'nominal': simpanan.nominal,
          'tanggal': simpanan.tanggal.toIso8601String(),
          'keterangan': simpanan.keterangan,
        });

        await txn.rawUpdate(
          'UPDATE anggota SET total_simpanan = total_simpanan + ? WHERE id = ?',
          [simpanan.nominal, simpanan.anggotaId],
        );
      });

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan simpanan: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalSimpanan() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('SELECT COALESCE(SUM(nominal), 0) as total FROM simpanan');
      final total = (result.first['total'] as num).toDouble();
      return Right(total);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil total simpanan: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalSimpananByAnggota(int anggotaId) async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(nominal), 0) as total FROM simpanan WHERE anggota_id = ?',
        [anggotaId],
      );
      final total = (result.first['total'] as num).toDouble(); 
      return Right(total);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil total simpanan anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getTotalSimpananPerJenis() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT jenis, COALESCE(SUM(nominal), 0) as total 
        FROM simpanan 
        GROUP BY jenis
      ''');

      final Map<String, double> totalPerJenis = {};
      for (var row in result) {
        final jenis = row['jenis'] as String;
        final total = (row['total'] as num).toDouble(); 
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