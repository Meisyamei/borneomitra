import 'dart:ui';

import 'package:equatable/equatable.dart';

class Simpanan extends Equatable {
  final int? id;
  final int anggotaId;
  final String jenis; // 'wajib', 'sukarela', 'pokok'
  final double nominal;
  final DateTime tanggal;
  final String? keterangan;
  final String namaAnggota;

  const Simpanan({
    this.id,
    required this.anggotaId,
    required this.jenis,
    required this.nominal,
    required this.tanggal,
    this.keterangan,
    this.namaAnggota = '',
  });

  String get jenisDisplay {
    switch (jenis) {
      case 'wajib':
        return 'Simpanan Wajib';
      case 'sukarela':
        return 'Simpanan Sukarela';
      case 'pokok':
        return 'Simpanan Pokok';
      default:
        return jenis;
    }
  }

  String get jenisSingkat {
    switch (jenis) {
      case 'wajib':
        return 'Wajib';
      case 'sukarela':
        return 'Sukarela';
      case 'pokok':
        return 'Pokok';
      default:
        return jenis;
    }
  }

  

  Color get jenisColor {
    switch (jenis) {
      case 'wajib':
        return Color(0xFF007BFF); 
      case 'sukarela':
        return Color(0xFF28A745);
      case 'pokok':
        return Color(0xFFFFC107); 
      default:
        return Color(0xFFB0BEC5); 
    }
  }

  @override
  List<Object?> get props => [id, anggotaId, jenis, nominal, tanggal];
}