import 'package:Koperasi/features/simpanan/domain/usecases/get_total_simpanan_per_jenis.dart';
import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/get_all_simpanan.dart';
import 'package:Koperasi/features/simpanan/presentation/pages/tambah_simpanan_page.dart';

class SimpananPage extends StatefulWidget {
  const SimpananPage({super.key});

  @override
  State<SimpananPage> createState() => _SimpananPageState();
}

class _SimpananPageState extends State<SimpananPage> {
  List<Simpanan> _simpananList = [];
  List<Simpanan> _filteredList = [];
  bool _isLoading = true;
  String _selectedJenis = 'semua';
  String _searchQuery = '';
  Map<String, double> _totalPerJenis = {};

  final List<String> _jenisOptions = ['sukarela'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadSimpanan();
    await _loadTotalPerJenis();
    setState(() => _isLoading = false);
  }

  Future<void> _loadSimpanan() async {
    final result = await sl<GetAllSimpanan>().execute();
    result.fold(
      (failure) => _showError('Gagal load data: ${failure.message}'),
      (simpanan) {
        setState(() {
          _simpananList = simpanan;
          _filteredList = simpanan;
        });
      },
    );
  }

  Future<void> _loadTotalPerJenis() async {
    final result = await sl<GetTotalSimpanan>().execute();
    result.fold(
      (failure) => _showError('Gagal load total: ${failure.message}'),
      (total) => setState(() => _totalPerJenis = {'sukarela': total}),
    );
  }

  void _filterSimpanan() {
    var filtered = _simpananList;

    if (_selectedJenis != 'semua') {
      filtered = filtered.where((s) => s.jenis == _selectedJenis).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.namaAnggota.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    setState(() => _filteredList = filtered);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double get _totalSimpanan {
    return _filteredList.fold(0.0, (sum, s) {
      return s.tipe == 'keluar'
          ? sum - s.nominal
          : sum + s.nominal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Simpanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama anggota...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _filterSimpanan();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterSimpanan();
              },
            ),
          ),

          // Total Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.savings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Total Simpanan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormatter.formatRupiah(_totalSimpanan),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // List Simpanan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.savings_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada data simpanan'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final simpanan = _filteredList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: simpanan.jenisColor.withOpacity(0.2),
                                child: Icon(Icons.savings, color: simpanan.jenisColor),
                              ),
                              title: Text(simpanan.namaAnggota),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(simpanan.jenisDisplay),
                                  Text(
                                    DateFormatter.formatDate(simpanan.tanggal),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${simpanan.tipe == 'keluar' ? '-' : '+'}${NumberFormatter.formatRupiah(simpanan.nominal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: simpanan.tipe == 'keluar'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  if (simpanan.keterangan != null)
                                    Text(
                                      simpanan.keterangan!,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahSimpananPage()),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Simpanan'),
      ),
    );
  }

  Widget _buildJenisTotal(String label, double total, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color)),
        Text(
          NumberFormatter.formatRupiah(total),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}