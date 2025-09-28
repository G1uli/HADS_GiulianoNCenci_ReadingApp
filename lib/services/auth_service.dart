import 'package:shared_preferences/shared_preferences.dart';

class UserAccount {
  final String email;
  final String name;
  final DateTime birthDate;
  final DateTime registrationDate;

  UserAccount({
    required this.email,
    required this.name,
    required this.birthDate,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      email: map['email'],
      name: map['name'],
      birthDate: DateTime.parse(map['birthDate']),
      registrationDate: DateTime.parse(map['registrationDate']),
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<bool> register(
    String email,
    String password,
    String name,
    DateTime birthDate,
  ) async {
    if (!email.endsWith('@gmail.com')) {
      return false; // RNF04: Only Gmail accounts allowed
    }

    final prefs = await SharedPreferences.getInstance();

    // Store account credentials
    await prefs.setString('current_email', email);
    await prefs.setString('current_password', password);
    await prefs.setString('current_name', name);
    await prefs.setString('current_birthDate', birthDate.toIso8601String());
    await prefs.setBool('isLoggedIn', true);

    // Add to accounts list
    final accountsJson = prefs.getStringList('user_accounts') ?? [];
    final newAccount = UserAccount(
      email: email,
      name: name,
      birthDate: birthDate,
      registrationDate: DateTime.now(),
    );

    // Check if account already exists
    if (!accountsJson.any((accountJson) {
      final account = UserAccount.fromMap(_jsonDecode(accountJson));
      return account.email == email;
    })) {
      accountsJson.add(_jsonEncode(newAccount.toMap()));
      await prefs.setStringList('user_accounts', accountsJson);
    }

    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('current_email');
    final storedPassword = prefs.getString('current_password');

    if (email == storedEmail && password == storedPassword) {
      await prefs.setBool('isLoggedIn', true);
      return true;
    }

    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_email');
  }

  Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('current_email');
  }

  // Get all registered accounts
  Future<List<UserAccount>> getAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList('user_accounts') ?? [];

    return accountsJson.map((json) {
      return UserAccount.fromMap(_jsonDecode(json));
    }).toList();
  }

  // Switch to a different account
  Future<bool> switchAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList('user_accounts') ?? [];

    for (final accountJson in accountsJson) {
      final account = UserAccount.fromMap(_jsonDecode(accountJson));
      if (account.email == email) {
        // Update current account info
        await prefs.setString('current_email', account.email);
        await prefs.setString('current_name', account.name);
        await prefs.setString(
          'current_birthDate',
          account.birthDate.toIso8601String(),
        );
        await prefs.setBool('isLoggedIn', true);
        return true;
      }
    }

    return false;
  }

  // Helper methods for JSON encoding/decoding
  Map<String, dynamic> _jsonDecode(String jsonString) {
    // Simple JSON decoding for our map structure
    final Map<String, dynamic> result = {};
    final pairs = jsonString
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(', ');

    for (final pair in pairs) {
      final keyValue = pair.split(': ');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();

        // Remove quotes from key and value
        final cleanKey = key.replaceAll('"', '');
        final cleanValue = value.replaceAll('"', '');

        result[cleanKey] = cleanValue;
      }
    }

    return result;
  }

  String _jsonEncode(Map<String, dynamic> map) {
    // Simple JSON encoding for our map structure
    final entries = map.entries.map(
      (entry) => '"${entry.key}": "${entry.value}"',
    );
    return '{${entries.join(', ')}}';
  }
}
