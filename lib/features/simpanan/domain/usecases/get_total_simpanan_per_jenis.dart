import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';

class GetTotalSimpanan {
  final SimpananRepository repository;

  GetTotalSimpanan(this.repository);

  Future<Either<Failure, double>> execute() async {
    return await repository.getTotalSimpanan();
  }
}

class GetTotalSimpananByAnggota {
  final SimpananRepository repository;

  GetTotalSimpananByAnggota(this.repository);

  Future<Either<Failure, double>> execute(int anggotaId) async {
    if (anggotaId <= 0) {
      return Left(ValidationFailure('ID anggota tidak valid'));
    }
    return await repository.getTotalSimpananByAnggota(anggotaId);
  }
}

class GetTotalSimpananPerJenis {
  final SimpananRepository repository;

  GetTotalSimpananPerJenis(this.repository);

  Future<Either<Failure, Map<String, double>>> execute() async {
    return await repository.getTotalSimpananPerJenis();
  }
}
