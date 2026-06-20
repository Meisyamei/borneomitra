import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/angsuran.dart';
import '../../domain/repositories/angsuran_repository.dart';

class AngsuranRepositoryImpl implements AngsuranRepository {
  final Database database;

  AngsuranRepositoryImpl(this.database);

  @override
  Future<Either<Failure, List<Angsuran>>> getAngsuranByPinjaman(
    int pinjamanId,
  ) async {
    try {
      final result = await database.query(
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
      final result = await database.query(
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
  Future<Either<Failure, void>> bayarAngsuran(
    int angsuranId,
    DateTime tanggalBayar,
  ) async {
    try {
      // Ambil data angsuran dulu
      final angsuranResult = await getAngsuranById(angsuranId);
      if (angsuranResult.isLeft()) {
        return Left(DatabaseFailure('Angsuran tidak ditemukan'));
      }

      final angsuran = (angsuranResult as Right).value;

      // Hitung denda
      final dendaResult = await hitungDenda(angsuranId, tanggalBayar);
      double denda = 0;
      dendaResult.fold((failure) => denda = 0, (value) => denda = value);

      // Update angsuran
      await database.update(
        'angsuran',
        {
          'tanggal_bayar': tanggalBayar.toIso8601String(),
          'status': 'lunas',
          'denda': denda,
        },
        where: 'id = ?',
        whereArgs: [angsuranId],
      );

      // Update sisa pinjaman
      await database.rawUpdate(
        '''
        UPDATE pinjaman 
        SET sisa_pinjaman = sisa_pinjaman - ? 
        WHERE id = ?
      ''',
        [angsuran.nominal, angsuran.pinjamanId],
      );

      // Cek apakah pinjaman sudah lunas
      final pinjamanResult = await database.query(
        'pinjaman',
        where: 'id = ?',
        whereArgs: [angsuran.pinjamanId],
      );

      if (pinjamanResult.isNotEmpty) {
        final sisaPinjaman = pinjamanResult.first['sisa_pinjaman'] as double;
        if (sisaPinjaman <= 0) {
          await database.update(
            'pinjaman',
            {'status': 'lunas'},
            where: 'id = ?',
            whereArgs: [angsuran.pinjamanId],
          );
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal membayar angsuran: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Angsuran>>> getTunggakan() async {
    try {
      final result = await database.rawQuery('''
        SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
        FROM angsuran a
        JOIN pinjaman p ON a.pinjaman_id = p.id
        JOIN anggota ag ON p.anggota_id = ag.id
        WHERE a.status = 'belum_bayar' 
          AND a.tanggal_jatuh_tempo < date('now')
        ORDER BY a.tanggal_jatuh_tempo ASC
      ''');

      final tunggakanList = result
          .map((map) => Angsuran(
                id: map['id'] as int?,
                pinjamanId: map['pinjaman_id'] as int,
                angsuranKe: map['angsuran_ke'] as int,
                nominal: (map['nominal'] as num?)?.toDouble() ?? 0,
                denda: (map['denda'] as num?)?.toDouble() ?? 0,
                tanggalJatuhTempo: DateTime.parse(map['tanggal_jatuh_tempo'] as String),
                tanggalBayar: map['tanggal_bayar'] != null
                    ? DateTime.parse(map['tanggal_bayar'] as String)
                    : null,
                status: map['status'] as String,
                namaAnggota: map['nama_anggota'] as String?,
                jumlahPinjaman: (map['jumlah_pinjaman'] as num?)?.toDouble(),
              ))
          .toList();

      return Right(tunggakanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data tunggakan: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> hitungDenda(
    int angsuranId,
    DateTime tanggalBayar,
  ) async {
    try {
      final angsuranResult = await getAngsuranById(angsuranId);
      if (angsuranResult.isLeft()) {
        return Left(DatabaseFailure('Angsuran tidak ditemukan'));
      }

      final angsuran = (angsuranResult as Right).value;

      if (tanggalBayar.isAfter(angsuran.tanggalJatuhTempo)) {
        final hariTerlambat = tanggalBayar
            .difference(angsuran.tanggalJatuhTempo)
            .inDays;
        final bulanTerlambat = (hariTerlambat / 30).ceil();
        final denda = bulanTerlambat * AppConstants.dendaPerBulan;
        return Right(denda);
      }

      return Right(0.0);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghitung denda: $e'));
    }
  }

  Angsuran _mapToEntity(Map<String, dynamic> map) {
    return Angsuran(
      id: map['id'] as int?,
      pinjamanId: map['pinjaman_id'] as int,
      angsuranKe: map['angsuran_ke'] as int,
      nominal: (map['nominal'] as num).toDouble(),
      denda: (map['denda'] as num?)?.toDouble() ?? 0.0,
      tanggalJatuhTempo: DateTime.parse(map['tanggal_jatuh_tempo'] as String),
      tanggalBayar: map['tanggal_bayar'] != null 
          ? DateTime.parse(map['tanggal_bayar'] as String) 
          : null,
      status: map['status'] as String,
    );
  }
}
