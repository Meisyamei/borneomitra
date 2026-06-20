import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Future<bool> isConnected() async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    // Di versi 6.x, checkConnectivity() juga mengembalikan List
    return result != ConnectivityResult.none && result.isNotEmpty;
  }
  
  Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
    // Sekarang mengembalikan Stream<List<ConnectivityResult>>
  }
  
  // Helper method untuk cek koneksi dari list result
  bool hasConnection(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi) ||
           results.contains(ConnectivityResult.mobile) ||
           results.contains(ConnectivityResult.ethernet);
  }
}