import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../entities/pinjaman.dart';
import '../repositories/pinjaman_repository.dart';

class CreatePinjaman {
  final PinjamanRepository repository;

  CreatePinjaman(this.repository);

  Future<Either<Failure, void>> execute(Pinjaman pinjaman) async {
    // Validasi
    if (pinjaman.anggotaId <= 0) {
      return Left(ValidationFailure('Anggota tidak valid'));
    }
    if (pinjaman.jumlah <= 0) {
      return Left(ValidationFailure('Jumlah pinjaman harus lebih dari 0'));
    }
    if (pinjaman.jumlah > AppConstants.maxPinjaman) {
      return Left(ValidationFailure('Jumlah pinjaman melebihi maksimal Rp${AppConstants.maxPinjaman}'));
    }
    if (pinjaman.tenor < 1 || pinjaman.tenor > 24) {
      return Left(ValidationFailure('Tenor harus antara 1-24 bulan'));
    }
    if (pinjaman.bunga < 0) {
      return Left(ValidationFailure('Bunga tidak valid'));
    }
    
    return await repository.createPinjaman(pinjaman);
  }
}