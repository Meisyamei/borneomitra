import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/angsuran.dart';

abstract class AngsuranRepository {
  Future<Either<Failure, List<Angsuran>>> getAngsuranByPinjaman(int pinjamanId);
  Future<Either<Failure, Angsuran>> getAngsuranById(int id);
  Future<Either<Failure, void>> bayarAngsuran(int angsuranId, DateTime tanggalBayar);
  Future<Either<Failure, List<Angsuran>>> getTunggakan();
  Future<Either<Failure, double>> hitungDenda(int angsuranId, DateTime tanggalBayar);
}