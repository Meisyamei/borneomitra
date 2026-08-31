import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/features/arisan/models/arisan_model.dart';
import 'package:Koperasi/features/arisan/models/peserta_arisan_model.dart';
import 'package:Koperasi/features/arisan/services/arisan_service.dart';
import 'package:Koperasi/features/anggota/domain/entities/anggota.dart';
import 'package:Koperasi/features/arisan/pages/bayar_arisan_page.dart';
import 'package:Koperasi/features/anggota/domain/usecases/get_all_anggota.dart';
import 'package:Koperasi/injection_container.dart';
import 'tambah_peserta_page.dart';

class DetailArisanPage extends StatefulWidget {
  final ArisanModel arisan;

  const DetailArisanPage({super.key, required this.arisan});

  @override
  State<DetailArisanPage> createState() => _DetailArisanPageState();
}

class _DetailArisanPageState extends State<DetailArisanPage> {
  final ArisanService _arisanService = ArisanService();
  List<PesertaArisan> _pesertaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _pesertaList = await _arisanService.getPeserta(widget.arisan.id!);
    setState(() => _isLoading = false);
  }

  Future<void> _addPeserta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahPesertaPage(arisanId: widget.arisan.id!),
      ),
    );
    if (result == true) _loadData();
  }

  // ===== DIALOG BAYAR ARISAN =====
  void _showBayarDialog(int pesertaId, int bulanKe, double nominal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bayar Arisan Bulan ke-$bulanKe'),
        content: Text('Bayar sebesar ${NumberFormatter.formatRupiah(nominal)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _arisanService.bayarArisan(pesertaId, bulanKe, nominal);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran berhasil!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }

  Future<void> _nextBulan() async {
    await _arisanService.nextBulan(widget.arisan.id!);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulan arisan berjalan!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _hapusPeserta(int pesertaId, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Peserta'),
        content: Text('Hapus $nama dari arisan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _arisanService.removePeserta(pesertaId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peserta dihapus'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIuran = widget.arisan.iuran * _pesertaList.length;
    final bulanSekarang = widget.arisan.bulanBerjalan;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arisan.nama),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addPeserta,
            tooltip: 'Tambah Peserta',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ===== INFO ARISAN =====
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Durasi', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${widget.arisan.totalBulan} Bulan'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bulan Berjalan', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$bulanSekarang/${widget.arisan.totalBulan}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Peserta', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_pesertaList.length} orang'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Iuran per Peserta', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(NumberFormatter.formatRupiah(widget.arisan.iuran)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Dana', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              NumberFormatter.formatRupiah(totalIuran),
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        // 🔴 PERBAIKI: Cek apakah biayaAdmin ada
                        // Hapus atau comment bagian biayaAdmin
                        // if (widget.arisan.biayaAdmin > 0) ...[
                        //   const Divider(),
                        //   Row(...)
                        // ],
                        if (bulanSekarang > widget.arisan.totalBulan)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.celebration, color: Colors.green),
                                SizedBox(width: 8),
                                Text('🎉 Arisan Selesai!', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ===== TOMBOL NEXT BULAN =====
                if (bulanSekarang <= widget.arisan.totalBulan)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ElevatedButton.icon(
                      onPressed: _nextBulan,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Bulan ke-$bulanSekarang Selesai -> Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.purple,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ===== LEGEND =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('Lunas', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 12),
                      Container(width: 20, height: 20, color: Colors.red.shade100),
                      const SizedBox(width: 4),
                      const Text('Terlewat', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 12),
                      Container(width: 20, height: 20, color: Colors.orange.shade100),
                      const SizedBox(width: 4),
                      const Text('Bulan Ini', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 12),
                      Container(width: 20, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 4),
                      const Text('Mendatang', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ===== DAFTAR PESERTA =====
                Expanded(
                  child: _pesertaList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('Belum ada peserta'),
                              const Text('Klik + untuk menambah peserta', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _pesertaList.length,
                          itemBuilder: (context, index) {
                            final peserta = _pesertaList[index];
                            final isWinner = peserta.status == 'sudah_menang';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isWinner ? Colors.green.shade50 : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ===== HEADER PESERTA =====
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isWinner ? Colors.green : Colors.purple,
                                              radius: 14,
                                              child: Text(
                                                '${peserta.nomorUrut}',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              peserta.namaAnggota,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (isWinner)
                                          const Chip(
                                            label: Text('🏆 MENANG'),
                                            backgroundColor: Colors.green,
                                            labelStyle: TextStyle(fontSize: 10, color: Colors.white),
                                            padding: EdgeInsets.zero,
                                          )
                                        // 🔴 PERBAIKI: Hapus atau comment isLunas
                                        // else if (peserta.isLunas && peserta.pembayaranBulan.isNotEmpty)
                                        //   const Chip(...),
                                      ],
                                    ),
                                    if (!isWinner && !peserta.isLunas)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => BayarArisanPage(
                                                  pesertaId: peserta.id!,
                                                  arisanId: widget.arisan.id!,
                                                  namaAnggota: peserta.namaAnggota,
                                                  iuran: widget.arisan.iuran,
                                                  totalBulan: widget.arisan.totalBulan,
                                                  bulanBerjalan: widget.arisan.bulanBerjalan,
                                                  pembayaranBulan: peserta.pembayaranBulan,
                                                ),
                                              ),
                                            ).then((_) => _loadData());
                                          },
                                          icon: const Icon(Icons.payment, size: 18),
                                          label: const Text('Bayar Arisan'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            minimumSize: const Size(double.infinity, 40),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),

                                    // ===== STATUS PEMBAYARAN PER BULAN =====
                                    if (peserta.pembayaranBulan.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: List.generate(
                                        peserta.pembayaranBulan.length,
                                        (i) {
                                          final sudahBayar = peserta.pembayaranBulan[i];
                                          final isCurrentMonth = (i + 1) == bulanSekarang;
                                          final isPastMonth = (i + 1) < bulanSekarang;

                                          // Tentukan warna dan label
                                          Color bgColor;
                                          Color textColor;
                                          String label;

                                          if (sudahBayar) {
                                            bgColor = Colors.green;
                                            textColor = Colors.white;
                                            label = '✅ Lunas';
                                          } else if (isPastMonth) {
                                            bgColor = Colors.red.shade100;
                                            textColor = Colors.red.shade700;
                                            label = '❌ Terlewat';
                                          } else if (isCurrentMonth) {
                                            bgColor = Colors.orange.shade100;
                                            textColor = Colors.orange.shade700;
                                            label = '🔄 Bayar';
                                          } else {
                                            bgColor = Colors.grey.shade300;
                                            textColor = Colors.grey.shade600;
                                            label = '⏳ Nanti';
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: bgColor,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Bulan ${i + 1}: $label',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '✅ Lunas: ${peserta.jumlahBayar}/${peserta.pembayaranBulan.length}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          '💰 Total: ${NumberFormatter.formatRupiah(peserta.jumlahBayar * widget.arisan.iuran)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],

                                    // ===== TOMBOL HAPUS PESERTA =====
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _hapusPeserta(peserta.id!, peserta.namaAnggota),
                                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                        label: const Text(
                                          'Hapus',
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}