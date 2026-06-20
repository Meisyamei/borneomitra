import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/angsuran_repository.dart';
import '../../../../injection_container.dart';

class BayarAngsuranPage extends StatefulWidget {
  final int angsuranId;
  final int pinjamanId;
  final double nominal;
  final int angsuranKe;
  final DateTime tanggalJatuhTempo;
  final String? namaAnggota;

  const BayarAngsuranPage({
    super.key,
    required this.angsuranId,
    required this.pinjamanId,
    required this.nominal,
    required this.angsuranKe,
    required this.tanggalJatuhTempo,
    this.namaAnggota,
  });

  @override
  State<BayarAngsuranPage> createState() => _BayarAngsuranPageState();
}

class _BayarAngsuranPageState extends State<BayarAngsuranPage> {
  late AngsuranRepository _repository;
  
  DateTime _tanggalBayar = DateTime.now();
  double _denda = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ============ INI PERBAIKANNYA ============
    _repository = sl<AngsuranRepository>();
    // ==========================================
    _hitungDenda();
  }

  Future<void> _hitungDenda() async {
    final result = await _repository.hitungDenda(widget.angsuranId, _tanggalBayar);
    result.fold(
      (failure) => setState(() => _denda = 0),
      (denda) => setState(() => _denda = denda),
    );
  }

  Future<void> _bayar() async {
    setState(() => _isLoading = true);
    
    final result = await _repository.bayarAngsuran(widget.angsuranId, _tanggalBayar);
    
    setState(() => _isLoading = false);
    
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${failure.message}'), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLate = _tanggalBayar.isAfter(widget.tanggalJatuhTempo);
    final totalBayar = widget.nominal + _denda;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bayar Angsuran ke-${widget.angsuranKe}'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const Center(
              child: Icon(Icons.payment, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Konfirmasi Pembayaran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Info Anggota
            if (widget.namaAnggota != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Nama Anggota'),
                  subtitle: Text(widget.namaAnggota!),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Detail Angsuran
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Angsuran ke', '${widget.angsuranKe}'),
                    const Divider(),
                    _buildDetailRow('Nominal', NumberFormatter.formatRupiah(widget.nominal)),
                    const Divider(),
                    _buildDetailRow('Jatuh Tempo', DateFormatter.formatDate(widget.tanggalJatuhTempo)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tanggal Bayar
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal Pembayaran'),
                subtitle: Text(DateFormatter.formatDate(_tanggalBayar)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _tanggalBayar,
                    firstDate: widget.tanggalJatuhTempo,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _tanggalBayar = date);
                    _hitungDenda();
                  }
                },
              ),
            ),
            
            // Denda
            if (isLate && _denda > 0) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Denda Keterlambatan'),
                            ],
                          ),
                          Text(
                            NumberFormatter.formatRupiah(_denda),
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                      'Denda Rp${NumberFormatter.formatNumber(AppConstants.dendaPerBulan)} per bulan',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // if (isLate && _denda > 0) ...[
            //   const SizedBox(height: 16),
            //   Card(
            //     color: Colors.red.shade50,
            //     child: Padding(
            //       padding: const EdgeInsets.all(16),
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const Row(
            //             children: [
            //               Icon(Icons.warning, color: Colors.red),
            //               SizedBox(width: 8),
            //               Text('Denda Keterlambatan'),
            //             ],
            //           ),
            //           Text(
            //             NumberFormatter.formatRupiah(_denda),
            //             style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ],
            
            const SizedBox(height: 16),
            
            // Total
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      NumberFormatter.formatRupiah(totalBayar),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _bayar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Bayar Sekarang', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}