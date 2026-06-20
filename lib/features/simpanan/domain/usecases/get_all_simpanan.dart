import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';

class GetAllSimpanan {
  final SimpananRepository repository;

  GetAllSimpanan(this.repository);

  Future<Either<Failure, List<Simpanan>>> execute() async {
    return await repository.getAllSimpanan();
  }
}