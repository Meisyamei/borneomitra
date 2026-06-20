import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_constants.dart';

class HitungDenda {
  HitungDenda();

  Future<Either<Failure, double>> execute(
    DateTime tanggalJatuhTempo,
    DateTime tanggalBayar,
  ) async {
    try {
      if (tanggalBayar.isAfter(tanggalJatuhTempo)) {
        final hariTerlambat = tanggalBayar.difference(tanggalJatuhTempo).inDays;
        final bulanTerlambat = (hariTerlambat / 30).ceil();
        final denda = bulanTerlambat * AppConstants.dendaPerBulan;
        return Right(denda);
      }
      return Right(0.0);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghitung denda: $e'));
    }
  }
}