import 'package:Koperasi/features/pinjaman/presentation/widgets/pinjaman_card.dart';
import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/pinjaman/domain/entities/pinjaman.dart';
import 'package:Koperasi/features/pinjaman/domain/usecases/get_all_pinjaman.dart';
import 'package:Koperasi/features/pinjaman/presentation/pages/tambah_pinjaman_page.dart';
import 'package:Koperasi/features/pinjaman/presentation/pages/detail_pinjaman_page.dart';

class PinjamanPage extends StatefulWidget {
  const PinjamanPage({super.key});

  @override
  State<PinjamanPage> createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage> {
  List<Pinjaman> _pinjamanList = [];
  List<Pinjaman> _filteredList = [];
  bool _isLoading = true;
  String _selectedStatus = 'semua';
  String _searchQuery = '';

  final List<String> _statusOptions = ['semua', 'aktif', 'menunggak', 'lunas'];

  @override
  void initState() {
    super.initState();
    _loadPinjaman();
  }

  Future<void> _loadPinjaman() async {
    setState(() => _isLoading = true);

    final result = await sl<GetAllPinjaman>().execute();

    result.fold(
      (failure) => _showError('Gagal load data: ${failure.message}'),
      (pinjaman) {
        setState(() {
          _pinjamanList = pinjaman;
          _filteredList = pinjaman;
          _isLoading = false;
        });
      },
    );
  }

  void _filterPinjaman() {
    var filtered = _pinjamanList;

    if (_selectedStatus != 'semua') {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.namaAnggota.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.id.toString().contains(_searchQuery)).toList();
    }

    setState(() => _filteredList = filtered);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  double get _totalPinjamanAktif {
    return _filteredList
        .where((p) => p.status == 'aktif')
        .fold(0, (sum, p) => sum + p.sisaPinjaman);
  }

  int get _totalMenunggak {
    return _filteredList.where((p) => p.status == 'menunggak').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pinjaman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPinjaman,
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
                hintText: 'Cari nama anggota atau ID pinjaman...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _filterPinjaman();
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
                _filterPinjaman();
              },
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusOptions.map((status) {
                  Color color;
                  switch (status) {
                    case 'aktif':
                      color = Colors.green;
                      break;
                    case 'menunggak':
                      color = Colors.red;
                      break;
                    case 'lunas':
                      color = Colors.blue;
                      break;
                    default:
                      color = Colors.grey;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status == 'semua'
                          ? 'Semua'
                          : status == 'aktif'
                              ? 'Aktif'
                              : status == 'menunggak'
                                  ? 'Menunggak'
                                  : 'Lunas'),
                      selected: _selectedStatus == status,
                      selectedColor: color.withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() => _selectedStatus = status);
                        _filterPinjaman();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Pinjaman Aktif',
                    NumberFormatter.formatRupiah(_totalPinjamanAktif),
                    Icons.credit_card,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Jumlah Menunggak',
                    '$_totalMenunggak anggota',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // List Pinjaman
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada data pinjaman'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final pinjaman = _filteredList[index];
                          return PinjamanCard(
                            pinjaman: pinjaman,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailPinjamanPage(pinjaman: pinjaman),
                                ),
                              );
                              if (result == true) _loadPinjaman();
                            },
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
            MaterialPageRoute(
              builder: (context) => const TambahPinjamanPage(),
            ),
          );
          if (result == true) _loadPinjaman();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pinjaman'),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Text(title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}