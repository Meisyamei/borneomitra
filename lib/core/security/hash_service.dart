import 'package:bcrypt/bcrypt.dart';

class HashService {
  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
  }
  
  static bool verifyPassword(String password, String hashed) {
    return BCrypt.checkpw(password, hashed);
  }
  
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
}