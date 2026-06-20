import 'package:Koperasi/features/arisan/pages/arisan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:Koperasi/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:Koperasi/features/auth/presentation/bloc/login_bloc.dart';
import 'package:Koperasi/features/auth/presentation/bloc/login_event.dart';
import 'package:Koperasi/features/anggota/presentation/pages/anggota_page.dart';
import 'package:Koperasi/features/simpanan/presentation/pages/simpanan_page.dart';
import 'package:Koperasi/features/pinjaman/presentation/pages/pinjaman_page.dart';
import 'package:Koperasi/features/angsuran/presentation/pages/angsuran_page.dart';
import 'package:Koperasi/features/tunggakan/presentation/pages/tunggakan_page.dart';
import 'package:Koperasi/features/laporan/presentation/pages/laporan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  DashboardData? _dashboardData;
  bool _isLoading = true;

  final List<Widget> _pages = [
    const DashboardContent(),
    const AnggotaPage(),
    const SimpananPage(),
    const PinjamanPage(),
  ];

  final List<String> _titles = [
    'Dashboard Borneo Mitra Senjaya',
    'Manajemen Anggota',
    'Manajemen Simpanan',
    'Manajemen Pinjaman',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showNotificationDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _showProfileDialog();
              } else if (value == 'change_password') {
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
                    Text('Profil'),
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'admin@bms.com',
                    style: TextStyle(
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
              Text('• Total tunggakan: ${NumberFormatter.formatRupiah(_dashboardData!.nominalTunggakan)}'),
            ],
            const Text('• 5 anggota akan jatuh tempo minggu ini'),
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

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Admin'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: admin'),
            Text('Nama: Administrator'),
            Text('Role: Super Admin'),
            Text('Bergabung: 01 Januari 2024'),
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

// Dashboard Content Widget
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
                      // Welcome Card
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),

                      // Stats Cards
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
                            color: const Color.fromARGB(255, 255, 2, 2),
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
                            change: '${NumberFormatter.formatRupiah(_data!.simpananMasukBulanIni)} bulan ini',
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
                            color: const Color.fromARGB(255, 187, 233, 3),
                            change: '${NumberFormatter.formatRupiah(_data!.nominalTunggakan)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Alert Tunggakan
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

                      // Recent Transactions
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
                color: Colors.blue.shade50,
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
                    'Selamat Datang, Admin!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Selamat bekerja dan mengelola koperasi',
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