import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/pinjaman/domain/entities/pinjaman.dart';
import 'package:Koperasi/features/pinjaman/domain/usecases/get_pinjaman_by_id.dart';
import 'package:Koperasi/features/angsuran/domain/entities/angsuran.dart';
import 'package:Koperasi/features/angsuran/domain/usecases/get_angsuran_by_pinjaman.dart';
import 'package:Koperasi/features/angsuran/presentation/pages/bayar_angsuran_page.dart';

class DetailPinjamanPage extends StatefulWidget {
  final Pinjaman pinjaman;

  const DetailPinjamanPage({super.key, required this.pinjaman});

  @override
  State<DetailPinjamanPage> createState() => _DetailPinjamanPageState();
}

class _DetailPinjamanPageState extends State<DetailPinjamanPage> {
  late Pinjaman _pinjaman;
  List<Angsuran> _angsuranList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pinjaman = widget.pinjaman;
    _loadAngsuran();
  }

  Future<void> _loadAngsuran() async {
    setState(() => _isLoading = true);

    final result = await sl<GetAngsuranByPinjaman>()
        .execute(_pinjaman.id ?? 0);

    result.fold(
      (failure) => _showError('Gagal load angsuran: ${failure.message}'),
      (angsuran) {
        setState(() {
          _angsuranList = angsuran;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _refreshData() async {
    // Refresh pinjaman
    final pinjamanResult = await sl<GetPinjamanById>()
        .execute(_pinjaman.id ?? 0);
    pinjamanResult.fold(
      (failure) => _showError(failure.message),
      (pinjaman) => setState(() => _pinjaman = pinjaman),
    );

    // Refresh angsuran
    await _loadAngsuran();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  int get _totalTerbayar {
    return _angsuranList.where((a) => a.isLunas).length;
  }

  double get _totalNominalTerbayar {
    return _angsuranList
        .where((a) => a.isLunas)
        .fold(0.0, (sum, a) => sum + a.nominal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pinjaman'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Pinjaman
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Pinjaman',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(),
                      _buildInfoRow('Nama Anggota', _pinjaman.namaAnggota),
                      _buildInfoRow('Tanggal Pinjam',
                          DateFormatter.formatDate(_pinjaman.tanggalPinjam)),
                      _buildInfoRow('Jatuh Tempo',
                          DateFormatter.formatDate(_pinjaman.tanggalJatuhTempo)),
                      _buildInfoRow('Status', _pinjaman.status.toUpperCase()),
                      const Divider(),
                      _buildInfoRow('Jumlah Pinjaman',
                          NumberFormatter.formatRupiah(_pinjaman.jumlah)),
                      _buildInfoRow('Bunga', '${_pinjaman.bunga}%'),
                      _buildInfoRow('Tenor', '${_pinjaman.tenor} Bulan'),
                      _buildInfoRow('Angsuran/Bulan',
                          NumberFormatter.formatRupiah(_pinjaman.angsuranPerBulan)),
                      _buildInfoRow('Sisa Pinjaman',
                          NumberFormatter.formatRupiah(_pinjaman.sisaPinjaman),
                          isBold: true, color: Colors.red),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _pinjaman.progressPelunasan / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_pinjaman.progressPelunasan.toStringAsFixed(1)}% lunas',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Progress Ringkasan
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(height: 4),
                            Text('$_totalTerbayar/${_pinjaman.tenor}'),
                            const Text('Angsuran Terbayar',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(Icons.money, color: Colors.orange),
                            const SizedBox(height: 4),
                            Text(NumberFormatter.formatRupiah(
                                _totalNominalTerbayar)),
                            const Text('Total Terbayar',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Daftar Angsuran
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Angsuran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (!_pinjaman.isLunas)
                    ElevatedButton.icon(
                      onPressed: () {
                        final nextAngsuran = _angsuranList.firstWhere(
                          (a) => !a.isLunas,
                          orElse: () => Angsuran(
                            id: 0,
                            pinjamanId: 0,
                            angsuranKe: 0,
                            nominal: 0,
                            tanggalJatuhTempo: DateTime.now(),
                            status: 'belum_bayar',
                          ),
                        );
                        if (nextAngsuran.id != 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BayarAngsuranPage(
                                angsuranId: nextAngsuran.id!,
                                pinjamanId: _pinjaman.id!,
                                nominal: nextAngsuran.nominal,
                                angsuranKe: nextAngsuran.angsuranKe,
                                tanggalJatuhTempo:
                                    nextAngsuran.tanggalJatuhTempo,
                                namaAnggota: _pinjaman.namaAnggota,
                              ),
                            ),
                          ).then((_) => _refreshData());
                        }
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Bayar Angsuran'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_angsuranList.isEmpty)
                const Center(child: Text('Belum ada data angsuran'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _angsuranList.length,
                  itemBuilder: (context, index) {
                    final angsuran = _angsuranList[index];
                    final isLunas = angsuran.isLunas;
                    final isLate = !isLunas && angsuran.isTerlambat;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isLate ? Colors.red.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLunas
                              ? Colors.green
                              : (isLate ? Colors.red : Colors.orange),
                          child: Text(
                            '${angsuran.angsuranKe}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('Angsuran ke-${angsuran.angsuranKe}'),
                        subtitle: Text(
                          'Jatuh tempo: ${DateFormatter.formatDate(angsuran.tanggalJatuhTempo)}',
                          style: TextStyle(
                              color: isLate ? Colors.red : Colors.grey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              NumberFormatter.formatRupiah(angsuran.nominal),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (angsuran.denda > 0)
                              Text(
                                'Denda: ${NumberFormatter.formatRupiah(angsuran.denda)}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.red),
                              ),
                            if (isLunas)
                              const Chip(
                                label: Text('LUNAS'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(
                                    fontSize: 10, color: Colors.white),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                        onTap: isLunas
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BayarAngsuranPage(
                                      angsuranId: angsuran.id!,
                                      pinjamanId: _pinjaman.id!,
                                      nominal: angsuran.nominal,
                                      angsuranKe: angsuran.angsuranKe,
                                      tanggalJatuhTempo:
                                          angsuran.tanggalJatuhTempo,
                                      namaAnggota: _pinjaman.namaAnggota,
                                    ),
                                  ),
                                );
                                if (result == true) _refreshData();
                              },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}