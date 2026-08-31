class ArisanModel {
  final int? id;
  final String nama;
  final double iuran;
  final int totalBulan;
  final double biayaAdmin;
  final int bulanBerjalan;
  final DateTime tanggalMulai;
  final DateTime? tanggalSelesai;
  final String status; // 'aktif', 'selesai'

  ArisanModel({
    this.id,
    required this.nama,
    required this.iuran,
    required this.totalBulan,
    required this.tanggalMulai,
    this.bulanBerjalan = 1, 
    this.biayaAdmin = 0.0,
    this.tanggalSelesai,
    this.status = 'aktif',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'iuran': iuran,
      'biaya_admin': biayaAdmin,
      'total_bulan': totalBulan,       
      'bulan_berjalan': bulanBerjalan,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'status': status,
    };
  }

  factory ArisanModel.fromMap(Map<String, dynamic> map) {
    return ArisanModel(
      id: map['id'],
      nama: map['nama'],
      iuran: map['iuran']?.toDouble() ?? 0,
      biayaAdmin: map['biaya_admin']?.toDouble() ?? 0,
      totalBulan: map['total_bulan'] ?? 0,         
      bulanBerjalan: map['bulan_berjalan'] ?? 1,
      tanggalMulai: DateTime.parse(map['tanggal_mulai']),
      tanggalSelesai: map['tanggal_selesai'] != null
          ? DateTime.parse(map['tanggal_selesai'])
          : null,
      status: map['status'] ?? 'aktif',
    );
  }
}