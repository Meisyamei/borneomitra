import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';

class GetSimpananByAnggota {
  final SimpananRepository repository;

  GetSimpananByAnggota(this.repository);

  Future<Either<Failure, List<Simpanan>>> execute(int anggotaId) async {
    if (anggotaId <= 0) {
      return Left(ValidationFailure('ID anggota tidak valid'));
    }
    return await repository.getSimpananByAnggota(anggotaId);
  }
}