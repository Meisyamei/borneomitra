import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/pinjaman/domain/entities/pinjaman.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/core/services/api_service.dart';
import 'package:Koperasi/features/pinjaman/domain/repositories/pinjaman_repository.dart';
import 'package:Koperasi/core/constants/app_constants.dart';

class PinjamanRepositoryImpl implements PinjamanRepository {
  final Database database;

  PinjamanRepositoryImpl(this.database);

  // ===== UPDATE STATUS PINJAMAN (HANYA DIPANGGIL SAAT STARTUP) =====
  Future<void> updateAllPinjamanStatus() async {
    try {
      final db = database;
      
      await db.rawQuery('''
        UPDATE pinjaman 
        SET status = 'lunas' 
        WHERE sisa_pinjaman <= 0 AND status != 'lunas'
      ''');
      
      await db.rawQuery('''
        UPDATE pinjaman 
        SET status = 'menunggak' 
        WHERE id IN (
          SELECT DISTINCT pinjaman_id 
          FROM angsuran 
          WHERE status = 'belum_bayar' 
            AND tanggal_jatuh_tempo < date('now')
        ) AND status NOT IN ('lunas', 'menunggak')
      ''');
      
      await db.rawQuery('''
        UPDATE pinjaman 
        SET status = 'aktif' 
        WHERE id NOT IN (
          SELECT DISTINCT pinjaman_id 
          FROM angsuran 
          WHERE status = 'belum_bayar' 
            AND tanggal_jatuh_tempo < date('now')
        ) AND sisa_pinjaman > 0 AND status NOT IN ('aktif', 'lunas')
      ''');
      
      print('✅ Status pinjaman updated');
    } catch (e) {
      print('❌ Error update status pinjaman: $e');
    }
  }

  // ===== GET ALL PINJAMAN =====
  @override
  Future<Either<Failure, List<Pinjaman>>> getAllPinjaman() async {
    try {
      final db = database;
      
      // 🔴 HAPUS update status dari sini (pindah ke startup)
      // await updateAllPinjamanStatus();
      
      final result = await db.rawQuery('''
        SELECT 
          p.*,
          a.nama as nama_anggota,
          a.nik
        FROM pinjaman p
        LEFT JOIN anggota a ON p.anggota_id = a.id
        WHERE a.id IS NOT NULL
        ORDER BY p.tanggal_pinjam DESC
      ''');
      
      final pinjamanList = result.map((map) => _mapToEntity(map)).toList();
      return Right(pinjamanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data pinjaman: $e'));
    }
  }

  // ===== GET PINJAMAN BY ID =====
  @override
  Future<Either<Failure, Pinjaman>> getPinjamanById(int id) async {
    try {
      final db = database;
      final result = await db.rawQuery('''
        SELECT 
          p.*,
          a.nama as nama_anggota,
          a.nik
        FROM pinjaman p
        LEFT JOIN anggota a ON p.anggota_id = a.id
        WHERE p.id = ? AND a.id IS NOT NULL
      ''', [id]);
      
      if (result.isEmpty) {
        return Left(DatabaseFailure('Pinjaman tidak ditemukan'));
      }
      
      return Right(_mapToEntity(result.first));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data pinjaman: $e'));
    }
  }

  // ===== GET PINJAMAN BY ANGGOTA =====
  @override
  Future<Either<Failure, List<Pinjaman>>> getPinjamanByAnggota(int anggotaId) async {
    try {
      final db = database;

      final result = await db.rawQuery('''
        SELECT 
          p.*,
          a.nama as nama_anggota,
          a.nik
        FROM pinjaman p
        LEFT JOIN anggota a ON p.anggota_id = a.id
        WHERE p.anggota_id = ? AND a.id IS NOT NULL
        ORDER BY p.tanggal_pinjam DESC
      ''', [anggotaId]);
      
      final pinjamanList = result.map((map) => _mapToEntity(map)).toList();
      return Right(pinjamanList);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data pinjaman anggota: $e'));
    }
  }

  // ===== CREATE PINJAMAN =====
  @override
  Future<Either<Failure, void>> createPinjaman(Pinjaman pinjaman) async {
    try {
      final db = database;

      await db.transaction((txn) async {
        // 1. Insert pinjaman
        final pinjamanId = await txn.insert('pinjaman', {
          'anggota_id': pinjaman.anggotaId,
          'jumlah': pinjaman.jumlah,
          'bunga': pinjaman.bunga,
          'tenor': pinjaman.tenor,
          'tanggal_pinjam': pinjaman.tanggalPinjam.toIso8601String(),
          'status': pinjaman.status,
          'denda_keterlambatan': AppConstants.dendaPerBulan,
          'sisa_pinjaman': pinjaman.jumlah,
        });
        
        // 2. Generate angsuran otomatis
        final angsuranPerBulan = pinjaman.angsuranPerBulan;
        for (int i = 1; i <= pinjaman.tenor; i++) {
          final jatuhTempo = pinjaman.tanggalPinjam.add(Duration(days: i * 30));
          await txn.insert('angsuran', {
            'pinjaman_id': pinjamanId,
            'angsuran_ke': i,
            'nominal': angsuranPerBulan,
            'denda': 0,
            'tanggal_jatuh_tempo': jatuhTempo.toIso8601String(),
            'tanggal_bayar': null,
            'status': 'belum_bayar',
          });
        }

        // 3. Kirim ke server (async, tidak block)
        // try {
        //   await ApiService.postPinjaman({
        //     'anggota_id': pinjaman.anggotaId,
        //     'jumlah': pinjaman.jumlah,
        //     'bunga': pinjaman.bunga,
        //     'tenor': pinjaman.tenor,
        //     'tanggal_pinjam': pinjaman.tanggalPinjam.toIso8601String().substring(0, 10),
        //   });
        //   print('✅ Pinjaman berhasil dikirim ke server');
        // } catch (e) {
        //   print('⚠️ Gagal kirim pinjaman ke server: $e');
        // }
        
        // 4. Update total pinjaman anggota
        await txn.rawUpdate(
          'UPDATE anggota SET total_pinjaman = total_pinjaman + ? WHERE id = ?',
          [pinjaman.jumlah, pinjaman.anggotaId],
        );
      });
      
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan pinjaman: $e'));
    }
  }

  // ===== UPDATE STATUS PINJAMAN =====
  @override
  Future<Either<Failure, void>> updateStatusPinjaman(int id, String status) async {
    try {
      final db = database;
      await db.update(
        'pinjaman',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal update status pinjaman: $e'));
    }
  }

  // ===== UPDATE SISA PINJAMAN =====
  @override
  Future<Either<Failure, void>> updateSisaPinjaman(int id, double sisaBaru) async {
    try {
      final db = database;
      if (sisaBaru < 0) sisaBaru = 0;
      
      await db.update(
        'pinjaman',
        {'sisa_pinjaman': sisaBaru},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal update sisa pinjaman: $e'));
    }
  }

  // ===== MAP TO ENTITY =====
  Pinjaman _mapToEntity(Map<String, dynamic> map) {
    return Pinjaman(
      id: map['id'],
      anggotaId: map['anggota_id'],
      jumlah: map['jumlah']?.toDouble() ?? 0,
      bunga: map['bunga']?.toDouble() ?? 0,
      tenor: map['tenor'],
      tanggalPinjam: DateTime.parse(map['tanggal_pinjam']),
      status: map['status'],
      dendaKeterlambatan: map['denda_keterlambatan']?.toDouble() ?? 50000,
      sisaPinjaman: map['sisa_pinjaman']?.toDouble() ?? 0,
      namaAnggota: map['nama_anggota'] ?? 'Anggota Tidak Ditemukan',
    );
  }
}