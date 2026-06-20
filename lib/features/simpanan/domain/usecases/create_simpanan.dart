import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';

class CreateSimpanan {
  final SimpananRepository repository;

  CreateSimpanan(this.repository);

  Future<Either<Failure, void>> execute(Simpanan simpanan) async {
    // Validasi
    if (simpanan.anggotaId <= 0) {
      return Left(ValidationFailure('Anggota tidak valid'));
    }
    if (simpanan.nominal <= 0) {
      return Left(ValidationFailure('Nominal simpanan harus lebih dari 0'));
    }
    if (simpanan.jenis.isEmpty) {
      return Left(ValidationFailure('Jenis simpanan tidak boleh kosong'));
    }

    // Validasi minimal simpanan per jenis
    switch (simpanan.jenis) {
      case 'wajib':
        if (simpanan.nominal < 50000) {
          return Left(ValidationFailure('Minimal simpanan wajib Rp50.000'));
        }
        break;
      case 'sukarela':
        if (simpanan.nominal < 10000) {
          return Left(ValidationFailure('Minimal simpanan sukarela Rp10.000'));
        }
        break;
      case 'pokok':
        if (simpanan.nominal < 100000) {
          return Left(ValidationFailure('Minimal simpanan pokok Rp100.000'));
        }
        break;
    }

    return await repository.createSimpanan(simpanan);
  }
}