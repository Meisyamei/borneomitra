import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/tunggakan/domain/entities/hampir_jatuh_tempo.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_hampir_jatuh_tempo.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_jatuh_tempo.dart';
import 'package:Koperasi/features/tunggakan/presentation/widgets/hampir_jatuh_tempo_card.dart';
import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/tunggakan/domain/entities/tunggakan.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_all_tunggakan.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_tunggakan_kritis.dart';
import 'package:Koperasi/features/pinjaman/presentation/pages/detail_pinjaman_page.dart';
import 'package:Koperasi/features/pinjaman/domain/entities/pinjaman.dart';

class TunggakanPage extends StatefulWidget {
  const TunggakanPage({super.key});

  @override
  State<TunggakanPage> createState() => _TunggakanPageState();
}

class _TunggakanPageState extends State<TunggakanPage> {
  // Data Tunggakan (Menunggak)
  List<Tunggakan> _tunggakanList = [];
  List<Tunggakan> _filteredList = [];
  
  // Data Jatuh Tempo Hari Ini
  List<HampirJatuhTempo> _jatuhTempoList = [];
  List<HampirJatuhTempo> _filteredJatuhTempoList = [];
  
  // Data Hampir Jatuh Tempo (1-3 hari)
  List<HampirJatuhTempo> _hampirJatuhTempoList = [];
  List<HampirJatuhTempo> _filteredHampirList = [];
  
  // State
  bool _isLoading = true;
  String _filterStatus = 'semua';
  String _searchQuery = '';
  String? _errorMessage;
  String _currentTab = 'menunggak'; // 'menunggak', 'jatuh_tempo', 'hampir'

  final List<String> _statusOptions = ['semua', 'ringan', 'sedang', 'kritis'];

  @override
  void initState() {
    super.initState();
    _loadTunggakan();
  }

  // ==================== DEBUG ====================
  Future<void> _debugCheckTunggakan() async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;
      
      final result = await db.rawQuery('''
        SELECT 
          a.id as anggota_id,
          a.nama as nama_anggota,
          ang.id as angsuran_id,
          ang.tanggal_jatuh_tempo,
          ang.status,
          ang.nominal
        FROM anggota a
        JOIN pinjaman p ON a.id = p.anggota_id
        JOIN angsuran ang ON p.id = ang.pinjaman_id
        WHERE p.status = 'aktif'
          AND ang.status = 'belum_bayar'
          AND ang.tanggal_jatuh_tempo < date('now')
        LIMIT 10
      ''');
      
      print('📊 ===== DEBUG TUNGGAKAN =====');
      print('📊 Total data tunggakan di database: ${result.length}');
      for (var row in result) {
        print('📊 Anggota: ${row['nama_anggota']}, Jatuh Tempo: ${row['tanggal_jatuh_tempo']}, Nominal: ${row['nominal']}');
      }
      print('📊 ===== END DEBUG =====');
    } catch (e) {
      print('❌ Error debug: $e');
    }
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadTunggakan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTab = 'menunggak';
    });

    await _debugCheckTunggakan();

    try {
      final result = await sl<GetAllTunggakan>().execute();

      result.fold(
        (failure) {
          print('❌ Error load tunggakan: ${failure.message}');
          setState(() {
            _errorMessage = 'Gagal load data: ${failure.message}';
            _isLoading = false;
          });
          _showError('Gagal load data: ${failure.message}');
        },
        (tunggakan) {
          print('✅ Tunggakan loaded: ${tunggakan.length} data');
          setState(() {
            _tunggakanList = tunggakan;
            _filteredList = tunggakan;
            _isLoading = false;
            _errorMessage = null;
          });
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Terjadi error: $e';
        _isLoading = false;
      });
      _showError('Terjadi error: $e');
    }
  }

  Future<void> _loadTunggakanKritis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTab = 'menunggak';
    });

    try {
      final result = await sl<GetTunggakanKritis>().execute();

      result.fold(
        (failure) {
          print('❌ Error load tunggakan kritis: ${failure.message}');
          setState(() {
            _errorMessage = 'Gagal load data: ${failure.message}';
            _isLoading = false;
          });
          _showError('Gagal load data: ${failure.message}');
        },
        (tunggakan) {
          print('✅ Tunggakan kritis loaded: ${tunggakan.length} data');
          setState(() {
            _tunggakanList = tunggakan;
            _filteredList = tunggakan;
            _isLoading = false;
            _errorMessage = null;
          });
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Terjadi error: $e';
        _isLoading = false;
      });
      _showError('Terjadi error: $e');
    }
  }

  Future<void> _loadJatuhTempo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTab = 'jatuh_tempo';
    });

    try {
      final result = await sl<GetJatuhTempo>().execute();

      result.fold(
        (failure) {
          print('❌ Error load jatuh tempo: ${failure.message}');
          setState(() {
            _errorMessage = 'Gagal load data: ${failure.message}';
            _isLoading = false;
          });
          _showError('Gagal load data: ${failure.message}');
        },
        (data) {
          print('✅ Jatuh tempo hari ini loaded: ${data.length} data');
          setState(() {
            _jatuhTempoList = data;
            _filteredJatuhTempoList = data;
            _isLoading = false;
            _errorMessage = null;
          });
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Terjadi error: $e';
        _isLoading = false;
      });
      _showError('Terjadi error: $e');
    }
  }

  Future<void> _loadHampirJatuhTempo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTab = 'hampir';
    });

    try {
      final result = await sl<GetHampirJatuhTempo>().execute();

      result.fold(
        (failure) {
          print('❌ Error load hampir jatuh tempo: ${failure.message}');
          setState(() {
            _errorMessage = 'Gagal load data: ${failure.message}';
            _isLoading = false;
          });
          _showError('Gagal load data: ${failure.message}');
        },
        (data) {
          print('✅ Hampir jatuh tempo loaded: ${data.length} data');
          setState(() {
            _hampirJatuhTempoList = data;
            _filteredHampirList = data;
            _isLoading = false;
            _errorMessage = null;
          });
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Terjadi error: $e';
        _isLoading = false;
      });
      _showError('Terjadi error: $e');
    }
  }

  // ==================== FILTER ====================
  void _filterTunggakan() {
    var filtered = _tunggakanList;

    if (_filterStatus != 'semua') {
      filtered = filtered.where((t) => t.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
          t.namaAnggota.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.nik.contains(_searchQuery)).toList();
    }

    setState(() => _filteredList = filtered);
  }

  void _filterJatuhTempo() {
    var filtered = _jatuhTempoList;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
          t.namaAnggota.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.nik.contains(_searchQuery)).toList();
    }
    setState(() => _filteredJatuhTempoList = filtered);
  }

  void _filterHampirJatuhTempo() {
    var filtered = _hampirJatuhTempoList;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
          t.namaAnggota.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.nik.contains(_searchQuery)).toList();
    }
    setState(() => _filteredHampirList = filtered);
  }

  // ==================== SWITCH TAB ====================
  void _switchTab(String tab) {
    setState(() => _searchQuery = '');
    if (tab == 'menunggak') {
      _loadTunggakan();
    } else if (tab == 'jatuh_tempo') {
      _loadJatuhTempo();
    } else {
      _loadHampirJatuhTempo();
    }
  }

  // ==================== HELPERS ====================
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double get _totalTunggakan {
    return _filteredList.fold(0, (sum, t) => sum + t.totalTunggakan);
  }

  int get _totalKritis {
    return _filteredList.where((t) => t.status == 'kritis').length;
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Tunggakan'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentTab == 'menunggak') {
                _loadTunggakan();
              } else if (_currentTab == 'jatuh_tempo') {
                _loadJatuhTempo();
              } else {
                _loadHampirJatuhTempo();
              }
            },
          ),
          if (_currentTab == 'menunggak')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'semua') {
                  _loadTunggakan();
                } else if (value == 'kritis') {
                  _loadTunggakanKritis();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'semua', child: Text('Semua Tunggakan')),
                const PopupMenuItem(value: 'kritis', child: Text('Tunggakan Kritis (>3 bulan)')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ===== TAB BAR =====
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Menunggak', 'menunggak'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Jatuh Tempo', 'jatuh_tempo'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Hampir', 'hampir'),
                ),
              ],
            ),
          ),

          // ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIK...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            if (_currentTab == 'menunggak') {
                              _filterTunggakan();
                            } else if (_currentTab == 'jatuh_tempo') {
                              _filterJatuhTempo();
                            } else {
                              _filterHampirJatuhTempo();
                            }
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
                if (_currentTab == 'menunggak') {
                  _filterTunggakan();
                } else if (_currentTab == 'jatuh_tempo') {
                  _filterJatuhTempo();
                } else {
                  _filterHampirJatuhTempo();
                }
              },
            ),
          ),

          // ===== FILTER CHIPS (Hanya untuk Menunggak) =====
          if (_currentTab == 'menunggak')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusOptions.map((status) {
                    Color color;
                    switch (status) {
                      case 'ringan': color = Colors.orange; break;
                      case 'sedang': color = const Color(0xFFFF6B35); break;
                      case 'kritis': color = Colors.red; break;
                      default: color = Colors.grey;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status == 'semua'
                            ? 'Semua'
                            : status == 'ringan'
                                ? 'Ringan'
                                : status == 'sedang'
                                    ? 'Sedang'
                                    : 'Kritis'),
                        selected: _filterStatus == status,
                        selectedColor: color.withOpacity(0.2),
                        onSelected: (selected) {
                          setState(() => _filterStatus = status);
                          _filterTunggakan();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // ===== STATS CARDS (Hanya untuk Menunggak) =====
          if (_currentTab == 'menunggak')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Tunggakan',
                      NumberFormatter.formatRupiah(_totalTunggakan),
                      Icons.money_off,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Jumlah Kritis',
                      '$_totalKritis anggota',
                      Icons.warning,
                      Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),

          // ===== ERROR MESSAGE =====
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // ===== LIST =====
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentTab == 'menunggak'
                    ? _buildTunggakanList()
                    : _currentTab == 'jatuh_tempo'
                        ? _buildJatuhTempoList()
                        : _buildHampirJatuhTempoList(),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD TAB BUTTON ====================
  Widget _buildTabButton(String label, String tab) {
    final isSelected = _currentTab == tab;
    Color selectedColor;
    switch (tab) {
      case 'menunggak':
        selectedColor = Colors.red;
        break;
      case 'jatuh_tempo':
        selectedColor = Colors.orange;
        break;
      case 'hampir':
        selectedColor = Colors.green;
        break;
      default:
        selectedColor = Colors.blue;
    }
    
    return GestureDetector(
      onTap: () => _switchTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==================== BUILD LIST TUNGGAKAN ====================
  Widget _buildTunggakanList() {
    if (_filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage != null ? Icons.error_outline : Icons.check_circle,
              size: 64,
              color: _errorMessage != null ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage != null 
                  ? _errorMessage!
                  : 'Tidak ada anggota yang menunggak',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage == null)
              const Text(
                'Semua angsuran berjalan lancar 🎉',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final tunggakan = _filteredList[index];
        return TunggakanCard(
          tunggakan: tunggakan,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPinjamanPage(
                  pinjaman: Pinjaman(
                    id: tunggakan.pinjamanId,
                    anggotaId: tunggakan.anggotaId,
                    jumlah: tunggakan.jumlahPinjaman,
                    bunga: 0,
                    tenor: 0,
                    tanggalPinjam: DateTime.now(),
                    status: 'aktif',
                    sisaPinjaman: tunggakan.sisaPinjaman,
                    namaAnggota: tunggakan.namaAnggota,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== BUILD LIST JATUH TEMPO HARI INI ====================
  Widget _buildJatuhTempoList() {
    if (_filteredJatuhTempoList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Tidak ada jatuh tempo hari ini'),
            Text('Semua angsuran aman 🎉'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredJatuhTempoList.length,
      itemBuilder: (context, index) {
        final data = _filteredJatuhTempoList[index];
        return HampirJatuhTempoCard(
          data: data,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPinjamanPage(
                  pinjaman: Pinjaman(
                    id: data.pinjamanId,
                    anggotaId: data.anggotaId,
                    jumlah: 0,
                    bunga: 0,
                    tenor: 0,
                    tanggalPinjam: DateTime.now(),
                    status: 'aktif',
                    sisaPinjaman: 0,
                    namaAnggota: data.namaAnggota,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== BUILD LIST HAMPIR JATUH TEMPO ====================
  Widget _buildHampirJatuhTempoList() {
    if (_filteredHampirList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thumb_up, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Tidak ada yang hampir jatuh tempo'),
            Text('Semua angsuran aman 🎉'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredHampirList.length,
      itemBuilder: (context, index) {
        final data = _filteredHampirList[index];
        return HampirJatuhTempoCard(
          data: data,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPinjamanPage(
                  pinjaman: Pinjaman(
                    id: data.pinjamanId,
                    anggotaId: data.anggotaId,
                    jumlah: 0,
                    bunga: 0,
                    tenor: 0,
                    tanggalPinjam: DateTime.now(),
                    status: 'aktif',
                    sisaPinjaman: 0,
                    namaAnggota: data.namaAnggota,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== STAT CARD ====================
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==================== TUNGGAKAN CARD WIDGET ====================
class TunggakanCard extends StatelessWidget {
  final Tunggakan tunggakan;
  final VoidCallback onTap;

  const TunggakanCard({
    super.key,
    required this.tunggakan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: tunggakan.statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tunggakan.statusColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tunggakan.namaAnggota,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tunggakan.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tunggakan.statusDisplay,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NIK', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(tunggakan.nik, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('No HP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(tunggakan.noHp, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tunggakan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          NumberFormatter.formatRupiah(tunggakan.totalTunggakan),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tunggakan.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bulan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${tunggakan.jumlahBulanTunggakan} bulan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sisa Pinjaman', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(NumberFormatter.formatRupiah(tunggakan.sisaPinjaman)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Denda', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(NumberFormatter.formatRupiah(tunggakan.dendaTotal)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Jatuh tempo terakhir: ${DateFormatter.formatDate(tunggakan.tanggalJatuhTempoTerakhir)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}