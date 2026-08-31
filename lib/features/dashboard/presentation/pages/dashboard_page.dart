import 'dart:io';
import 'dart:convert';
import 'package:Koperasi/features/laporan/presentation/pages/laporan_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/core/services/api_service.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/core/services/sync_service.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/arisan/pages/arisan_page.dart';
import 'package:Koperasi/features/profile/domain/entities/profile.dart';
import 'package:Koperasi/features/auth/presentation/bloc/login_bloc.dart';
import 'package:Koperasi/features/auth/presentation/bloc/login_event.dart';
import 'package:Koperasi/features/anggota/presentation/pages/anggota_page.dart';
import 'package:Koperasi/features/profile/presentation/pages/profile_page.dart';
import 'package:Koperasi/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:Koperasi/features/simpanan/presentation/pages/simpanan_page.dart';
import 'package:Koperasi/features/pinjaman/presentation/pages/pinjaman_page.dart';
import 'package:Koperasi/features/angsuran/presentation/pages/angsuran_page.dart';
import 'package:Koperasi/features/tunggakan/presentation/pages/tunggakan_page.dart';
import 'package:Koperasi/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:Koperasi/features/notifikasi/presentation/pages/notifikasi_page.dart';
import 'package:Koperasi/features/profile/data/datasources/profile_local_datasource.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _unreadNotifikasiCount = 0;
  DashboardData? _dashboardData;
  bool _isLoading = true;
  Profile _profile = Profile(nama: 'Administrator', email: 'admin@bms.com');

  final List<Widget> _pages = [
    const DashboardContent(),
    const AnggotaPage(),
    const SimpananPage(),
    const PinjamanPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Anggota',
    'Simpanan',
    'Pinjaman',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkUnreadNotifikasi();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfile();
  }
  Future<void> _loadProfile() async {
    try {
      final profileSource = ProfileLocalDataSource(DatabaseService());
      final newProfile = await profileSource.getProfile();
      setState(() {
        _profile = newProfile;
      });
      
      print('✅ Profile loaded: ${_profile.nama}');
    } catch (e) {
      print('⚠️ Error load profile: $e');
    }
  }

  // ===== TEST API CONNECTION =====
  // Future<void> _testApiConnection() async {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Row(
  //         children: [
  //           SizedBox(
  //             width: 20,
  //             height: 20,
  //             child: CircularProgressIndicator(strokeWidth: 2),
  //           ),
  //           SizedBox(width: 12),
  //           Text('Mencoba koneksi ke server...'),
  //         ],
  //       ),
  //       duration: Duration(seconds: 5),
  //     ),
  //   );

  //   try {
  //     // 🔴 PAKAI ApiService.baseUrl (bukan hardcode)
  //     final response = await http.get(
  //       Uri.parse('${ApiService.baseUrl}/anggota'),
  //       headers: {'Content-Type': 'application/json'},
  //     );

  //     print('📡 Response status: ${response.statusCode}');
  //     print('📡 Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       _showTestResultDialog(
  //         success: true,
  //         message: '✅ Koneksi ke server BERHASIL!',
  //         detail: 'Data anggota: ${data['data']?.length ?? 0} data\n'
  //                 'Response: ${response.body.substring(0, 200)}...',
  //       );
  //     } else {
  //       _showTestResultDialog(
  //         success: false,
  //         message: '❌ Koneksi gagal!',
  //         detail: 'Status: ${response.statusCode}\n'
  //                 'Response: ${response.body}',
  //       );
  //     }
  //   } catch (e) {
  //     print('❌ Error: $e');
  //     _showTestResultDialog(
  //       success: false,
  //       message: '❌ Error koneksi!',
  //       detail: 'Error: $e\n\n'
  //               'Pastikan:\n'
  //               '1. Server berjalan (docker ps)\n'
  //               '2. IP benar\n'
  //               '3. Flutter terhubung ke jaringan yang sama',
  //     );
  //   }
  // }

  Future<void> _checkUnreadNotifikasi() async {
    try {
      final db = await DatabaseService().database;
      final result = await db.query(
        'notifikasi',
        where: 'dibaca = 0 AND dihapus = 0',
      );
      setState(() {
        _unreadNotifikasiCount = result.length;
      });
    } catch (e) {
      print('⚠️ Error cek notifikasi: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final result = await sl<GetDashboardData>().execute();
    result.fold(
      (failure) => _showError('Gagal load dashboard: ${failure.message}'),
      (data) => setState(() {
        _dashboardData = data;
        _isLoading = false;
      }),
    );
  }

  // ===== SYNC DATA =====
  // Future<void> _syncData() async {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Row(
  //         children: [
  //           SizedBox(
  //             width: 20,
  //             height: 20,
  //             child: CircularProgressIndicator(strokeWidth: 2),
  //           ),
  //           SizedBox(width: 12),
  //           Text('Menyinkronkan data...'),
  //         ],
  //       ),
  //       duration: Duration(seconds: 10),
  //     ),
  //   );

  //   try {
  //     final syncService = SyncService(DatabaseService());
  //     final results = await syncService.syncAllData();

  //     _showSyncResultDialog(results);
  //   } catch (e) {
  //     print('❌ Error sync: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('❌ Error sync: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.cloud_download),
          //   onPressed: _syncData,
          //   tooltip: 'Sinkronisasi Data',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.cloud_upload),
          //   onPressed: _testApiConnection,
          //   tooltip: 'Test Koneksi ke Server',
          // ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifikasiCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifikasiCount > 9 ? '9+' : '$_unreadNotifikasiCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              _showNotificationDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
                if (result == true) {
                  await _loadProfile();  // Refresh profile
                  await _loadDashboardData();  // Refresh dashboard
                  setState(() {});  // Force rebuild
                }
              }
                 else if (value == 'change_password') {
                _showChangePasswordDialog();
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset),
                    SizedBox(width: 10),
                    Text('Ganti Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Anggota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Simpanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Pinjaman',
          ),
        ],
      ),
    );
  }

  // ===== BUILD SYNC RESULT ROW =====
  Widget _buildSyncResultRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count data',
            style: TextStyle(
              color: count > 0 ? Colors.green : Colors.grey,
              fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔴 FOTO PROFILE
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    backgroundImage: _profile.fotoPath != null && _profile.fotoPath!.isNotEmpty
                        ? FileImage(File(_profile.fotoPath!))
                        : null,
                    child: _profile.fotoPath == null || _profile.fotoPath!.isEmpty
                        ? Text(
                            _profile.nama.isNotEmpty ? _profile.nama[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _profile.nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _profile.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Anggota',
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          _buildDrawerItem(
            icon: Icons.savings,
            title: 'Simpanan',
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          _buildDrawerItem(
            icon: Icons.credit_card,
            title: 'Pinjaman',
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
          ),
          _buildDrawerItem(
            icon: Icons.payment,
            title: 'Angsuran',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AngsuranPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.groups,
            title: 'Arisan',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArisanPage()),
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.warning,
            title: 'Monitoring Tunggakan',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TunggakanPage()),
              );
            },
            color: Colors.orange,
          ),
          _buildDrawerItem(
            icon: Icons.receipt,
            title: 'Laporan Keuangan',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LaporanPage()),
              );
            },
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Profil Admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔴 FOTO PROFILE DI DIALOG
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _profile.fotoPath != null && _profile.fotoPath!.isNotEmpty
                ? FileImage(File(_profile.fotoPath!))
                : null,
            child: _profile.fotoPath == null || _profile.fotoPath!.isEmpty
                ? Text(
                    _profile.nama.isNotEmpty ? _profile.nama[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text('Nama: ${_profile.nama}'),
          Text('Email: ${_profile.email}'),
          Text('Role: Super Admin'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blue),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showTestResultDialog({
    required bool success,
    required String message,
    required String detail,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Sukses!' : 'Gagal!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: TextStyle(
                  color: success ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detail,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (success)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnggotaPage()),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Lihat Data'),
            ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  void _showSyncResultDialog(Map<String, int> results) {
    final total = results.values.reduce((a, b) => a + b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              total > 0 ? Icons.cloud_done : Icons.cloud_off,
              color: total > 0 ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(total > 0 ? 'Sync Berhasil!' : 'Tidak Ada Data Baru'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncResultRow('Anggota', results['anggota'] ?? 0),
            const Divider(),
            _buildSyncResultRow('Simpanan', results['simpanan'] ?? 0),
            const Divider(),
            _buildSyncResultRow('Pinjaman', results['pinjaman'] ?? 0),
            const Divider(),
            _buildSyncResultRow('Angsuran', results['angsuran'] ?? 0),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Data Baru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadDashboardData();
            },
            child: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_dashboardData != null) ...[
              if (_dashboardData!.totalTunggakan > 0)
                Text('• ${_dashboardData!.totalTunggakan} anggota menunggak'),
              if (_dashboardData!.tunggakanKritis > 0)
                Text('• ${_dashboardData!.tunggakanKritis} anggota tunggakan kritis'),
              if (_dashboardData!.nominalTunggakan > 0)
                Text('• Total tunggakan: ${NumberFormatter.formatRupiah(_dashboardData!.nominalTunggakan)}'),
              if (_dashboardData!.hampirJatuhTempo > 0)
                Text('• ${_dashboardData!.hampirJatuhTempo} anggota hampir jatuh tempo (1-3 hari)'),
              if (_dashboardData!.jatuhTempoHariIni > 0)
                Text('• ${_dashboardData!.jatuhTempoHariIni} anggota jatuh tempo hari ini'),
              if (_dashboardData!.jatuhTempoMingguIni > 0)
                Text('• ${_dashboardData!.jatuhTempoMingguIni} anggota jatuh tempo minggu ini (4-7 hari)'),
              if (_dashboardData!.totalTunggakan == 0 &&
                  _dashboardData!.hampirJatuhTempo == 0 &&
                  _dashboardData!.jatuhTempoHariIni == 0 &&
                  _dashboardData!.jatuhTempoMingguIni == 0)
                const Text('• ✅ Semua angsuran berjalan lancar'),
            ],
            if (_dashboardData == null) const Text('• Tidak ada notifikasi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
              );
            },
            child: const Text('Lihat Semua'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Lama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diubah'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LoginBloc>().add(LogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// DASHBOARD CONTENT
// ============================================
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  DashboardData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await sl<GetDashboardData>().execute();
    result.fold(
      (failure) => _showError('Gagal load data: ${failure.message}'),
      (data) => setState(() {
        _data = data;
        _isLoading = false;
      }),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? const Center(child: Text('Gagal memuat data'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'Ringkasan Koperasi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            title: 'Jatuh Tempo',
                            value: '${_data!.jatuhTempoHariIni} Anggota',
                            icon: Icons.today,
                            color: Colors.red,
                            change: '${_data!.hampirJatuhTempo} hampir jatuh tempo',
                          ),
                          _buildStatCard(
                            title: 'Total Anggota',
                            value: '${_data!.totalAnggota}',
                            icon: Icons.people,
                            color: Colors.blue,
                            change: '+${_data!.anggotaBaruBulanIni} bulan ini',
                          ),
                          _buildStatCard(
                            title: 'Total Simpanan',
                            value: NumberFormatter.formatRupiah(_data!.totalSimpanan),
                            icon: Icons.savings,
                            color: Colors.green,
                            change: 'Simpanan bulan ini',
                          ),
                          _buildStatCard(
                            title: 'Pinjaman Aktif',
                            value: NumberFormatter.formatRupiah(_data!.totalPinjamanAktif),
                            icon: Icons.credit_card,
                            color: Colors.orange,
                            change: '${_data!.jumlahPinjamanAktif} pinjaman',
                          ),
                          _buildStatCard(
                            title: 'Tunggakan',
                            value: '${_data!.totalTunggakan} Anggota',
                            icon: Icons.warning,
                            color: Colors.orange,
                            change: '${NumberFormatter.formatRupiah(_data!.nominalTunggakan)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_data!.totalTunggakan > 0) ...[
                        const Text(
                          'Peringatan Tunggakan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: Colors.red.shade50,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TunggakanPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_data!.totalTunggakan} Anggota Menunggak',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        if (_data!.tunggakanKritis > 0)
                                          Text(
                                            '${_data!.tunggakanKritis} anggota tunggakan kritis (>3 bulan)',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        Text(
                                          'Total tunggakan: ${NumberFormatter.formatRupiah(_data!.nominalTunggakan)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const Text(
                        'Transaksi Terbaru',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _data!.transaksiTerbaru.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('Belum ada transaksi'),
                                ),
                              )
                            : Column(
                                children: _data!.transaksiTerbaru.map((transaksi) {
                                  return Column(
                                    children: [
                                      _buildTransactionTile(transaksi),
                                      if (transaksi != _data!.transaksiTerbaru.last)
                                        const Divider(height: 0),
                                    ],
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 163, 210, 243),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand,
                color: Colors.blue,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi Koperasi BMS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Selamat Datang',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: change.contains('+') || change.contains('bulan')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change.length > 20 ? change.substring(0, 20) : change,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: change.contains('+') || change.contains('bulan')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransaksiTerbaru transaksi) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transaksi.jenisColor.withOpacity(0.2),
        child: Icon(
          transaksi.jenisIcon,
          size: 20,
          color: transaksi.jenisColor,
        ),
      ),
      title: Text(transaksi.judul),
      subtitle: Text(transaksi.subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            NumberFormatter.formatRupiah(transaksi.nominal),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaksi.jenis == 'pinjaman' ? Colors.red : Colors.green,
            ),
          ),
          Text(
            DateFormatter.formatDate(transaksi.tanggal),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}