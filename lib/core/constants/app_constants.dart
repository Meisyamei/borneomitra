class AppConstants {
  static const String appName = 'Koperasi';
  static const String appVersion = '1.0.0';
  
  // Limit & Rules
  static const double maxPinjaman = 50000000; // Rp50.000.000
  static const double dendaPerBulan = 50000; // Rp50.000
  static const double biayaAdmin = 25000; // Rp25.000
  static const double defaultBunga = 25.0; // 25% per tahun

  // Database
  static const String dbName = 'bms_koperasi.db';
  static const int dbVersion = 6;
  
  // SharedPreferences Keys
  static const String tokenKey = 'auth_token';
  static const String isLoggedInKey = 'is_logged_in';
  
  // AES Key
  static const String aesKeyStorage = 'aes_key_256';
}