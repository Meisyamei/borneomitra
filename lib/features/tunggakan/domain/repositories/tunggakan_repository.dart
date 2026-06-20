import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/tunggakan.dart';
import '../entities/hampir_jatuh_tempo.dart';

abstract class TunggakanRepository {
  Future<Either<Failure, List<Tunggakan>>> getAllTunggakan();
  Future<Either<Failure, List<Tunggakan>>> getTunggakanByAnggota(int anggotaId);
  Future<Either<Failure, List<Tunggakan>>> getTunggakanKritis();
  Future<Either<Failure, int>> getTotalTunggakanCount();
  Future<Either<Failure, double>> getTotalNominalTunggakan();
  Future<Either<Failure, List<HampirJatuhTempo>>> getHampirJatuhTempo();
  Future<Either<Failure, List<HampirJatuhTempo>>> getJatuhTempo();
}