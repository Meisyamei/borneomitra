class PembayaranArisan {
  final int? id;
  final int pesertaId;
  final int periodeKe;      // Bulan ke-1, ke-2, dst
  final double nominal;
  final DateTime tanggalBayar;
  final String status;      // 'lunas', 'belum'

  PembayaranArisan({
    this.id,
    required this.pesertaId,
    required this.periodeKe,
    required this.nominal,
    required this.tanggalBayar,
    this.status = 'lunas',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peserta_id': pesertaId,
      'periode_ke': periodeKe,
      'nominal': nominal,
      'tanggal_bayar': tanggalBayar.toIso8601String(),
      'status': status,
    };
  }

  factory PembayaranArisan.fromMap(Map<String, dynamic> map) {
    return PembayaranArisan(
      id: map['id'],
      pesertaId: map['peserta_id'],
      periodeKe: map['periode_ke'],
      nominal: map['nominal']?.toDouble() ?? 0,
      tanggalBayar: DateTime.parse(map['tanggal_bayar']),
      status: map['status'] ?? 'lunas',
    );
  }
}