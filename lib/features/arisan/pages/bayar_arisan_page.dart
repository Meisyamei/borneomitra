import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/features/arisan/services/arisan_service.dart';

class BayarArisanPage extends StatefulWidget {
  final int pesertaId;
  final int arisanId;
  final String namaAnggota;
  final double iuran;
  final int totalBulan;
  final int bulanBerjalan;
  final List<bool> pembayaranBulan;

  const BayarArisanPage({
    super.key,
    required this.pesertaId,
    required this.arisanId,
    required this.namaAnggota,
    required this.iuran,
    required this.totalBulan,
    required this.bulanBerjalan,
    required this.pembayaranBulan,
  });

  @override
  State<BayarArisanPage> createState() => _BayarArisanPageState();
}

class _BayarArisanPageState extends State<BayarArisanPage> {
  final ArisanService _arisanService = ArisanService();
  int _selectedBulan = 0; // 0 = belum dipilih
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bayar Arisan - ${widget.namaAnggota}'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== INFO ANGGOTA =====
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nama Anggota', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.namaAnggota),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Iuran per Bulan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(NumberFormatter.formatRupiah(widget.iuran)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bulan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${widget.totalBulan} Bulan'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bulan Berjalan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${widget.bulanBerjalan}/${widget.totalBulan}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== STATUS PEMBAYARAN =====
            const Text(
              'Status Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ===== GRID BULAN =====
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: widget.totalBulan,
              itemBuilder: (context, index) {
                final bulanKe = index + 1;
                final sudahBayar = widget.pembayaranBulan[index];
                final isCurrent = bulanKe == widget.bulanBerjalan;
                final isPast = bulanKe < widget.bulanBerjalan;

                Color bgColor;
                Color borderColor;
                String label;

                if (sudahBayar) {
                  bgColor = Colors.green;
                  borderColor = Colors.green.shade700;
                  label = '✅ LUNAS';
                } else if (isPast) {
                  bgColor = Colors.red.shade100;
                  borderColor = Colors.red.shade700;
                  label = '❌ TERLEWAT';
                } else if (isCurrent) {
                  bgColor = Colors.orange.shade100;
                  borderColor = Colors.orange.shade700;
                  label = '🔄 BAYAR';
                } else {
                  bgColor = Colors.grey.shade300;
                  borderColor = Colors.grey.shade400;
                  label = '⏳ NANTI';
                }

                return GestureDetector(
                  onTap: () {
                    if (!sudahBayar && isCurrent) {
                      setState(() => _selectedBulan = bulanKe);
                      _showBayarDialog(bulanKe);
                    } else if (sudahBayar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bulan ini sudah dibayar!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (isPast) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bulan ini sudah terlewat! Hubungi admin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bulan ini belum waktunya bayar.'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bulan $bulanKe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sudahBayar ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: sudahBayar ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ===== RINGKASAN =====
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Bayar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      NumberFormatter.formatRupiah(
                        widget.pembayaranBulan.where((b) => b).length * widget.iuran,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== LEGEND =====
            const Text(
              'Keterangan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegend('✅ LUNAS', Colors.green),
                _buildLegend('🔄 BAYAR (Bulan Ini)', Colors.orange),
                _buildLegend('❌ TERLEWAT', Colors.red),
                _buildLegend('⏳ NANTI', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showBayarDialog(int bulanKe) {
    final nominal = widget.iuran;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bayar arisan bulan ke-$bulanKe'),
            const SizedBox(height: 8),
            Text(
              'Nominal: ${NumberFormatter.formatRupiah(nominal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bayar(bulanKe, nominal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Bayar Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _bayar(int bulanKe, double nominal) async {
    setState(() => _isLoading = true);

    try {
      final result = await _arisanService.bayarArisan(
        widget.pesertaId,
        bulanKe,
        nominal,
      );

      if (result == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bulan ini sudah dibayar!'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran bulan ke-$bulanKe berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke detail arisan dengan refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membayar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}