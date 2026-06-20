import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/hampir_jatuh_tempo.dart';
import '../repositories/tunggakan_repository.dart';

class GetHampirJatuhTempo {
  final TunggakanRepository repository;

  GetHampirJatuhTempo(this.repository);

  Future<Either<Failure, List<HampirJatuhTempo>>> execute() async {
    return await repository.getHampirJatuhTempo();
  }
}