import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/pinjaman.dart';
import '../../domain/repositories/pinjaman_repository.dart';

class PinjamanRepositoryImpl implements PinjamanRepository {
  final Database database;

  PinjamanRepositoryImpl(this.database);

  @override
  Future<Either<Failure, List<Pinjaman>>> getAllPinjaman() async {
    try {
      final result = await database.query(
        'pinjaman',
        orderBy: 'tanggal_pinjam DESC',
      );
      
      final pinjamanList = result.map((map) => _mapToEntity(map)).toList();
      return Right(pinjamanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data pinjaman: $e'));
    }
  }

  @override
  Future<Either<Failure, Pinjaman>> getPinjamanById(int id) async {
    try {
      final result = await database.query(
        'pinjaman',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isEmpty) {
        return Left(DatabaseFailure('Pinjaman tidak ditemukan'));
      }
      
      return Right(_mapToEntity(result.first));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data pinjaman: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Pinjaman>>> getPinjamanByAnggota(int anggotaId) async {
    try {
      final result = await database.query(
        'pinjaman',
        where: 'anggota_id = ?',
        whereArgs: [anggotaId],
        orderBy: 'tanggal_pinjam DESC',
      );
      
      final pinjamanList = result.map((map) => _mapToEntity(map)).toList();
      return Right(pinjamanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data pinjaman anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createPinjaman(Pinjaman pinjaman) async {
    try {
      await database.transaction((txn) async {
        // Insert pinjaman
        final pinjamanId = await txn.insert('pinjaman', {
          'anggota_id': pinjaman.anggotaId,
          'jumlah': pinjaman.jumlah,
          'bunga': pinjaman.bunga,
          'tenor': pinjaman.tenor,
          'tanggal_pinjam': pinjaman.tanggalPinjam.toIso8601String(),
          'status': pinjaman.status,
          'denda_keterlambatan': AppConstants.dendaPerBulan,
          'sisa_pinjaman': pinjaman.jumlah,
        });
        
        // Generate angsuran otomatis
        final angsuranPerBulan = pinjaman.angsuranPerBulan;
        for (int i = 1; i <= pinjaman.tenor; i++) {
          final jatuhTempo = pinjaman.tanggalPinjam.add(Duration(days: i * 30));
          await txn.insert('angsuran', {
            'pinjaman_id': pinjamanId,
            'angsuran_ke': i,
            'nominal': angsuranPerBulan,
            'denda': 0,
            'tanggal_jatuh_tempo': jatuhTempo.toIso8601String(),
            'tanggal_bayar': null,
            'status': 'belum_bayar',
          });
        }
        
        // Update total pinjaman anggota
        await txn.rawUpdate(
          'UPDATE anggota SET total_pinjaman = total_pinjaman + ? WHERE id = ?',
          [pinjaman.jumlah, pinjaman.anggotaId],
        );
      });
      
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan pinjaman: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatusPinjaman(int id, String status) async {
    try {
      await database.update(
        'pinjaman',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal update status pinjaman: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSisaPinjaman(int id, double sisaBaru) async {
    try {
      await database.update(
        'pinjaman',
        {'sisa_pinjaman': sisaBaru},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal update sisa pinjaman: $e'));
    }
  }

  Pinjaman _mapToEntity(Map<String, dynamic> map) {
    return Pinjaman(
      id: map['id'] as int?,
      anggotaId: map['anggota_id'] as int,
      jumlah: (map['jumlah'] as num).toDouble(),
      bunga: (map['bunga'] as num).toDouble(),
      tenor: map['tenor'] as int,
      tanggalPinjam: DateTime.parse(map['tanggal_pinjam'] as String),
      status: map['status'] as String,
      dendaKeterlambatan: (map['denda_keterlambatan'] as num?)?.toDouble() ?? 50000.0,
      sisaPinjaman: (map['sisa_pinjaman'] as num?)?.toDouble() ?? 0.0,
    );
  }
}