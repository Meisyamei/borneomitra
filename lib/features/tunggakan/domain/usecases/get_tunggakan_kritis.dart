import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/tunggakan.dart';
import '../repositories/tunggakan_repository.dart';

class GetTunggakanKritis {
  final TunggakanRepository repository;

  GetTunggakanKritis(this.repository);

  Future<Either<Failure, List<Tunggakan>>> execute() async {
    return await repository.getTunggakanKritis();
  }
}