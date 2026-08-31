import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/angsuran/domain/entities/angsuran.dart';
import 'package:Koperasi/features/angsuran/domain/repositories/angsuran_repository.dart';
import 'package:Koperasi/core/constants/app_constants.dart';

class AngsuranRepositoryImpl implements AngsuranRepository {
  final DatabaseService dbService;

  AngsuranRepositoryImpl(this.dbService);

  Future<Database> get _db async => await dbService.database;

  @override
  Future<Either<Failure, List<Angsuran>>> getAngsuranByPinjaman(int pinjamanId) async {
    try {
      final db = await _db;
      final result = await db.query(
        'angsuran',
        where: 'pinjaman_id = ?',
        whereArgs: [pinjamanId],
        orderBy: 'angsuran_ke ASC',
      );
      
      final angsuranList = result.map((map) => _mapToEntity(map)).toList();
      return Right(angsuranList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data angsuran: $e'));
    }
  }

  @override
  Future<Either<Failure, Angsuran>> getAngsuranById(int id) async {
    try {
      final db = await _db;
      final result = await db.query(
        'angsuran',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isEmpty) {
        return Left(DatabaseFailure('Angsuran tidak ditemukan'));
      }
      
      return Right(_mapToEntity(result.first));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data angsuran: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> bayarAngsuran(int angsuranId, DateTime tanggalBayar) async {
    try {
      final db = await _db;
      
      // Ambil data angsuran
      final angsuranResult = await db.query(
        'angsuran',
        where: 'id = ?',
        whereArgs: [angsuranId],
      );
      
      if (angsuranResult.isEmpty) {
        return Left(DatabaseFailure('Angsuran tidak ditemukan'));
      }
      
      final angsuran = angsuranResult.first;
      final pinjamanId = angsuran['pinjaman_id'];
      final nominal = (angsuran['nominal'] as num).toDouble();
      
      // Hitung denda
      double denda = 0;
      final jatuhTempo = DateTime.parse(angsuran['tanggal_jatuh_tempo'] as String);
      if (tanggalBayar.isAfter(jatuhTempo)) {
        final hariTerlambat = tanggalBayar.difference(jatuhTempo).inDays;
        final bulanTerlambat = (hariTerlambat / 30).ceil();
        denda = bulanTerlambat * AppConstants.dendaPerBulan;
      }
      
      await db.transaction((txn) async {
        // Update angsuran
        await txn.update(
          'angsuran',
          {
            'tanggal_bayar': tanggalBayar.toIso8601String(),
            'status': 'lunas',
            'denda': denda,
          },
          where: 'id = ?',
          whereArgs: [angsuranId],
        );
        
        // Ambil pinjaman saat ini
        final pinjamanResult = await txn.query(
          'pinjaman',
          where: 'id = ?',
          whereArgs: [pinjamanId],
        );
        
        if (pinjamanResult.isNotEmpty) {
          final currentPinjaman = pinjamanResult.first;
          double sisaSekarang = (currentPinjaman['sisa_pinjaman'] as num).toDouble();
          
          // Jangan biarkan sisa pinjaman negatif
          double sisaBaru = sisaSekarang - nominal;
          if (sisaBaru < 0) sisaBaru = 0;
          
          // Update sisa pinjaman
          await txn.update(
            'pinjaman',
            {'sisa_pinjaman': sisaBaru},
            where: 'id = ?',
            whereArgs: [pinjamanId],
          );
          
          // 🔴 CEK STATUS MENUNGGAK
          final checkResult = await txn.rawQuery('''
            SELECT COUNT(*) as total
            FROM angsuran
            WHERE pinjaman_id = ?
              AND status = 'belum_bayar'
              AND tanggal_jatuh_tempo < date('now')
          ''', [pinjamanId]);
          
          final totalMenunggak = (checkResult.first['total'] as int?) ?? 0;
          
          // Update status pinjaman
          String statusBaru = 'aktif';
          if (sisaBaru <= 0) {
            statusBaru = 'lunas';
          } else if (totalMenunggak > 0) {
            statusBaru = 'menunggak';
          }
          
          await txn.update(
            'pinjaman',
            {'status': statusBaru},
            where: 'id = ?',
            whereArgs: [pinjamanId],
          );
          
          // Update total pinjaman anggota jika lunas
          if (statusBaru == 'lunas') {
            final anggotaResult = await txn.query(
              'anggota',
              where: 'id = ?',
              whereArgs: [currentPinjaman['anggota_id']],
            );
            if (anggotaResult.isNotEmpty) {
              final currentAnggota = anggotaResult.first;
              double totalPinjaman = (currentAnggota['total_pinjaman'] as num).toDouble();
              double newTotalPinjaman = totalPinjaman - (currentPinjaman['jumlah'] as num).toDouble();
              if (newTotalPinjaman < 0) newTotalPinjaman = 0;
              
              await txn.update(
                'anggota',
                {'total_pinjaman': newTotalPinjaman},
                where: 'id = ?',
                whereArgs: [currentPinjaman['anggota_id']],
              );
            }
          }
        }
      });
      
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal membayar angsuran: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> hitungDenda(int angsuranId, DateTime tanggalBayar) async {
    try {
      final angsuranResult = await getAngsuranById(angsuranId);
      if (angsuranResult.isLeft()) {
        return Left(DatabaseFailure('Angsuran tidak ditemukan'));
      }
      
      final angsuran = (angsuranResult as Right).value;
      
      if (tanggalBayar.isAfter(angsuran.tanggalJatuhTempo)) {
        final hariTerlambat = tanggalBayar.difference(angsuran.tanggalJatuhTempo).inDays;
        final bulanTerlambat = (hariTerlambat / 30).ceil();
        final denda = bulanTerlambat * AppConstants.dendaPerBulan;
        return Right(denda);
      }
      
      return Right(0.0);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghitung denda: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Angsuran>>> getTunggakan() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
        FROM angsuran a
        JOIN pinjaman p ON a.pinjaman_id = p.id
        JOIN anggota ag ON p.anggota_id = ag.id
        WHERE a.status = 'belum_bayar' 
          AND a.tanggal_jatuh_tempo < date('now')
        ORDER BY a.tanggal_jatuh_tempo ASC
      ''');
      
      final tunggakanList = result.map((map) => Angsuran(
        id: map['id'] as int?,
        pinjamanId: (map['pinjaman_id'] as int?) ?? 0,
        angsuranKe: (map['angsuran_ke'] as int?) ?? 0,
        nominal: (map['nominal'] as num?)?.toDouble() ?? 0,
        denda: (map['denda'] as num?)?.toDouble() ?? 0,
        tanggalJatuhTempo: DateTime.parse(map['tanggal_jatuh_tempo'] as String),
        tanggalBayar: map['tanggal_bayar'] != null 
            ? DateTime.parse(map['tanggal_bayar'] as String) 
            : null,
        status: (map['status'] as String?) ?? '',
        namaAnggota: map['nama_anggota'] as String?,
        jumlahPinjaman: (map['jumlah_pinjaman'] as num?)?.toDouble(),
      )).toList();
      
      return Right(tunggakanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data tunggakan: $e'));
    }
  }

  Angsuran _mapToEntity(Map<String, dynamic> map) {
    return Angsuran(
      id: map['id'] as int?,
      pinjamanId: (map['pinjaman_id'] as int?) ?? 0,
      angsuranKe: (map['angsuran_ke'] as int?) ?? 0,
      nominal: (map['nominal'] as num?)?.toDouble() ?? 0,
      denda: (map['denda'] as num?)?.toDouble() ?? 0,
      tanggalJatuhTempo: DateTime.parse(map['tanggal_jatuh_tempo'] as String),
      tanggalBayar: map['tanggal_bayar'] != null 
          ? DateTime.parse(map['tanggal_bayar'] as String) 
          : null,
      status: (map['status'] as String?) ?? '',
    );
  }
}