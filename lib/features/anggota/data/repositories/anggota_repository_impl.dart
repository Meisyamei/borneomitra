import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/aes_service.dart';
import '../../domain/entities/anggota.dart';
import '../../domain/repositories/anggota_repository.dart';

class AnggotaRepositoryImpl implements AnggotaRepository {
  final Database database;

  AnggotaRepositoryImpl(this.database);

  @override
  Future<Either<Failure, List<Anggota>>> getAllAnggota() async {
    try {
      final result = await database.query('anggota', orderBy: 'nama ASC');

      print("DATA DATABASE:");
      print(result);

      final anggotaList = result.map((map) => _mapToEntity(map)).toList();

      return Right(anggotaList);
    } catch (e, stack) {
      print("ERROR GET ANGGOTA:");
      print(e);
      print(stack);

      return Left(DatabaseFailure('Gagal mengambil data anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, Anggota>> getAnggotaById(int id) async {
    try {
      final result = await database.query(
        'anggota',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) {
        return Left(DatabaseFailure('Anggota tidak ditemukan'));
      }
      return Right(_mapToEntity(result.first));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, Anggota>> getAnggotaByNik(String nik) async {
    try {
      final result = await database.query(
        'anggota',
        where: 'nik = ?',
        whereArgs: [nik],
      );
      if (result.isEmpty) {
        return Left(DatabaseFailure('Anggota dengan NIK $nik tidak ditemukan'));
      }
      return Right(_mapToEntity(result.first));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createAnggota(Anggota anggota) async {
    try {
      final existing = await database.query(
        'anggota',
        where: 'nik = ?',
        whereArgs: [anggota.nik],
      );
      if (existing.isNotEmpty) {
        return Left(ValidationFailure('NIK ${anggota.nik} sudah terdaftar'));
      }

      final encryptedData = AesService.encryptSensitiveData({
        'nik': anggota.nik,
        'nama': anggota.nama,
        'alamat': anggota.alamat,
        'no_hp': anggota.noHp,
      });

      await database.insert('anggota', {
        'nik': anggota.nik,
        'nama': anggota.nama,
        'encrypted_data': encryptedData,
        'tanggal_daftar': anggota.tanggalDaftar.toIso8601String(),
        'total_simpanan': anggota.totalSimpanan,
        'total_pinjaman': anggota.totalPinjaman,
        'status': anggota.status,
      });

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAnggota(Anggota anggota) async {
    try {
      final encryptedData = AesService.encryptSensitiveData({
        'nik': anggota.nik,
        'nama': anggota.nama,
        'alamat': anggota.alamat,
        'no_hp': anggota.noHp,
      });

      await database.update(
        'anggota',
        {
          'nik': anggota.nik,
          'nama': anggota.nama,
          'encrypted_data': encryptedData,
          'tanggal_daftar': anggota.tanggalDaftar.toIso8601String(),
          'total_simpanan': anggota.totalSimpanan,
          'total_pinjaman': anggota.totalPinjaman,
          'status': anggota.status,
        },
        where: 'id = ?',
        whereArgs: [anggota.id],
      );

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengupdate anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAnggota(int id) async {
    try {
      await database.delete('anggota', where: 'id = ?', whereArgs: [id]);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghapus anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Anggota>>> searchAnggota(String keyword) async {
    try {
      final result = await database.query(
        'anggota',
        where: 'nama LIKE ? OR nik LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%'],
        orderBy: 'nama ASC',
      );
      final anggotaList = result.map((map) => _mapToEntity(map)).toList();
      return Right(anggotaList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mencari anggota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTotalSimpanan(int anggotaId, double nominal) async {
    try {
      final result = await getAnggotaById(anggotaId);
      if (result.isLeft()) {
        return Left(DatabaseFailure('Anggota tidak ditemukan'));
      }
      final currentAnggota = (result as Right).value;
      final newTotal = currentAnggota.totalSimpanan + nominal;

      await database.update(
        'anggota',
        {'total_simpanan': newTotal},
        where: 'id = ?',
        whereArgs: [anggotaId],
      );

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal update total simpanan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTotalPinjaman(int anggotaId, double nominal) async {
    try {
      final result = await getAnggotaById(anggotaId);
      if (result.isLeft()) {
        return Left(DatabaseFailure('Anggota tidak ditemukan'));
      }
      final currentAnggota = (result as Right).value;
      final newTotal = currentAnggota.totalPinjaman + nominal;

      await database.update(
        'anggota',
        {'total_pinjaman': newTotal},
        where: 'id = ?',
        whereArgs: [anggotaId],
      );

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal update total pinjaman: $e'));
    }
  }

  // Tambahkan method ini di AnggotaRepositoryImpl
  Future<void> _repairCorruptedData() async {
    try {
      final result = await database.query('anggota');
      
      for (var row in result) {
        final id = row['id'];
        final encryptedData = row['encrypted_data'] as String?;
        
        if (encryptedData != null && encryptedData.isNotEmpty) {
          try {
            // Coba dekripsi
            AesService.decryptSensitiveData(encryptedData);
          } catch (e) {
            print('⚠️ Data corrupted untuk ID $id, akan diperbaiki...');
            
            // Backup data dari column biasa
            final nik = row['nik']?.toString() ?? '';
            final nama = row['nama']?.toString() ?? '';
            
            // Re-encrypt dengan benar
            final newEncrypted = AesService.encryptSensitiveData({
              'nik': nik,
              'nama': nama,
              'alamat': row['alamat']?.toString() ?? '',
              'no_hp': row['no_hp']?.toString() ?? '',
            });
            
            // Update database
            await database.update(
              'anggota',
              {'encrypted_data': newEncrypted},
              where: 'id = ?',
              whereArgs: [id],
            );
            
            print('✅ Data untuk ID $id telah diperbaiki');
          }
        }
      }
    } catch (e) {
      print('❌ Gagal repair data: $e');
    }
  }

  Anggota _mapToEntity(Map<String, dynamic> map) {
    // Cek apakah ada encrypted_data
    final encryptedData = map['encrypted_data'] as String?;
    
    if (encryptedData != null && encryptedData.isNotEmpty) {
      try {
        // Coba dekripsi
        final decrypted = AesService.decryptSensitiveData(encryptedData);
        
        // Cek apakah hasil dekripsi adalah Map yang valid
        if (decrypted is Map<String, dynamic>) {
          return Anggota(
            id: map['id'],
            nik: decrypted['nik']?.toString() ?? '',
            nama: decrypted['nama']?.toString() ?? '',
            alamat: decrypted['alamat']?.toString() ?? '',
            noHp: decrypted['no_hp']?.toString() ?? '',
            tanggalDaftar: map['tanggal_daftar'] != null 
                ? DateTime.parse(map['tanggal_daftar'].toString()) 
                : DateTime.now(),
            totalSimpanan: (map['total_simpanan'] as num?)?.toDouble() ?? 0,
            totalPinjaman: (map['total_pinjaman'] as num?)?.toDouble() ?? 0,
            status: map['status']?.toString() ?? 'aktif',
          );
        }
      } catch (e) {
        // Jika dekripsi gagal, coba baca data dari column lain
        print('⚠️ Gagal mendekripsi data untuk ID ${map['id']}: $e');
        
        // Fallback: baca dari column biasa
        return Anggota(
          id: map['id'],
          nik: map['nik']?.toString() ?? '',
          nama: map['nama']?.toString() ?? '',
          alamat: map['alamat']?.toString() ?? '',
          noHp: map['no_hp']?.toString() ?? '',
          tanggalDaftar: map['tanggal_daftar'] != null 
              ? DateTime.parse(map['tanggal_daftar'].toString()) 
              : DateTime.now(),
          totalSimpanan: (map['total_simpanan'] as num?)?.toDouble() ?? 0,
          totalPinjaman: (map['total_pinjaman'] as num?)?.toDouble() ?? 0,
          status: map['status']?.toString() ?? 'aktif',
        );
      }
    }
    
    // Jika tidak ada encrypted_data, baca dari column biasa
    return Anggota(
      id: map['id'],
      nik: map['nik']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      alamat: map['alamat']?.toString() ?? '',
      noHp: map['no_hp']?.toString() ?? '',
      tanggalDaftar: map['tanggal_daftar'] != null 
          ? DateTime.parse(map['tanggal_daftar'].toString()) 
          : DateTime.now(),
      totalSimpanan: (map['total_simpanan'] as num?)?.toDouble() ?? 0,
      totalPinjaman: (map['total_pinjaman'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'aktif',
    );
  }
}