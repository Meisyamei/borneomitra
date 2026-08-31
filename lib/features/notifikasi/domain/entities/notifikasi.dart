import 'package:flutter/material.dart';

class Notifikasi {
  final int id;
  final String judul;
  final String pesan;
  final String jenis; // 'info', 'warning', 'danger', 'success'
  final DateTime tanggal;
  final bool dibaca;
  final bool dihapus;

  Notifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.jenis,
    required this.tanggal,
    this.dibaca = false,
    this.dihapus = false,
  });

  String get icon {
    switch (jenis) {
      case 'warning':
        return '⚠️';
      case 'danger':
        return '🔴';
      case 'success':
        return '✅';
      default:
        return 'ℹ️';
    }
  }

  Color get color {
    switch (jenis) {
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  bool get isExpired {
    return tanggal.add(const Duration(days: 15)).isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'pesan': pesan,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(),
      'dibaca': dibaca ? 1 : 0,
      'dihapus': dihapus ? 1 : 0,
    };
  }

  // 🔴 PERBAIKI: Handle null value
  factory Notifikasi.fromMap(Map<String, dynamic> map) {
    return Notifikasi(
      id: map['id'] as int? ?? 0,  // ← jika null, default 0
      judul: map['judul'] as String? ?? '',
      pesan: map['pesan'] as String? ?? '',
      jenis: map['jenis'] as String? ?? 'info',
      tanggal: map['tanggal'] != null 
          ? DateTime.parse(map['tanggal'] as String) 
          : DateTime.now(),
      dibaca: (map['dibaca'] as int?) == 1,  // ← handle null
      dihapus: (map['dihapus'] as int?) == 1,  // ← handle null
    );
  }
}