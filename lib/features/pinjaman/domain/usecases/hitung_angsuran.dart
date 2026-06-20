import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

class HitungAngsuran {
  HitungAngsuran();

  Future<Either<Failure, Map<String, double>>> execute(
    double jumlah,
    double bunga,
    int tenor,
  ) async {
    try {
      if (jumlah <= 0) {
        return Left(ValidationFailure('Jumlah pinjaman harus lebih dari 0'));
      }
      if (tenor <= 0) {
        return Left(ValidationFailure('Tenor harus lebih dari 0'));
      }
      if (bunga < 0) {
        return Left(ValidationFailure('Bunga tidak valid'));
      }

      // Perhitungan bunga flat
      final totalBunga = jumlah * (bunga / 100);
      final totalHarusBayar = jumlah + totalBunga;
      final angsuranPerBulan = totalHarusBayar / tenor;
      final biayaAdmin = 25000.0;
      final totalAngsuranPerBulan = angsuranPerBulan + biayaAdmin;

      return Right({
        'total_bunga': totalBunga,
        'total_harus_bayar': totalHarusBayar,
        'angsuran_per_bulan': angsuranPerBulan,
        'biaya_admin': biayaAdmin,
        'total_angsuran_per_bulan': totalAngsuranPerBulan,
      });
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghitung angsuran: $e'));
    }
  }
}