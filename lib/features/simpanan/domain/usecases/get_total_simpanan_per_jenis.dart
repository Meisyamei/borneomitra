import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../repositories/simpanan_repository.dart';

class GetTotalSimpanan {
  final SimpananRepository repository;

  GetTotalSimpanan(this.repository);

  Future<Either<Failure, double>> execute() async {
    return await repository.getTotalSimpanan();
  }
}