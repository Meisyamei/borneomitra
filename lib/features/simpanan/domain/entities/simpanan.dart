import 'dart:ui';
import 'package:equatable/equatable.dart';

class Simpanan extends Equatable {
  final int? id;
  final int anggotaId;
  final String jenis; // 'sukarela'
  final String tipe;  // ← TAMBAHKAN: 'masuk' atau 'keluar'
  final double nominal;
  final DateTime tanggal;
  final String? keterangan;
  final String namaAnggota;

  const Simpanan({
    this.id,
    required this.anggotaId,
    required this.jenis,
    required this.tipe,  // ← TAMBAHKAN
    required this.nominal,
    required this.tanggal,
    this.keterangan,
    this.namaAnggota = '',
  });

  String get jenisDisplay {
    switch (jenis) {
      case 'sukarela': return 'Simpanan Sukarela';
      default: return jenis;
    }
  }

  String get jenisSingkat {
    switch (jenis) {
      case 'sukarela': return 'Sukarela';
      default: return jenis;
    }
  }

  String get tipeDisplay {
    return tipe == 'masuk' ? 'Setor' : 'Tarik';
  }

  Color get tipeColor {
    return tipe == 'masuk' ? Color(0xFF4CAF50) : Color(0xFFF44336);
  }

  Color get jenisColor {
    switch (jenis) {
      case 'sukarela': return Color(0xFF28A745);
      default: return Color(0xFFB0BEC5);
    }
  }

  @override
  List<Object?> get props => [id, anggotaId, jenis, tipe, nominal, tanggal];
}