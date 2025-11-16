import 'package:reading_app/services/email_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

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

    // Store account credentials separately
    final credentialsJson = prefs.getStringList('account_credentials') ?? [];

    // Check if account already exists
    if (credentialsJson.any((credentialJson) {
      final credential = _jsonDecode(credentialJson);
      return credential['email'] == email;
    })) {
      return false; // Account already exists
    }

    // Add new credentials
    final newCredential = {
      'email': email,
      'password': password,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
    };
    credentialsJson.add(_jsonEncode(newCredential));
    await prefs.setStringList('account_credentials', credentialsJson);

    // Store account info (without password) for accounts screen
    final accountsJson = prefs.getStringList('user_accounts') ?? [];
    final newAccount = UserAccount(
      email: email,
      name: name,
      birthDate: birthDate,
      registrationDate: DateTime.now(),
    );

    accountsJson.add(_jsonEncode(newAccount.toMap()));
    await prefs.setStringList('user_accounts', accountsJson);

    // Set as current session
    await prefs.setString('current_email', email);
    await prefs.setString('current_password', password);
    await prefs.setString('current_name', name);
    await prefs.setString('current_birthDate', birthDate.toIso8601String());
    await prefs.setBool('isLoggedIn', true);

    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Get stored credentials
    final credentialsJson = prefs.getStringList('account_credentials') ?? [];

    for (final credentialJson in credentialsJson) {
      final credential = _jsonDecode(credentialJson);
      if (credential['email'] == email && credential['password'] == password) {
        // Set current session
        await prefs.setString('current_email', email);
        await prefs.setString('current_password', password);
        await prefs.setString('current_name', credential['name'] ?? '');
        await prefs.setString(
          'current_birthDate',
          credential['birthDate'] ?? '',
        );
        await prefs.setBool('isLoggedIn', true);
        return true;
      }
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
    await prefs.remove('current_email');
    await prefs.remove('current_password');
    await prefs.remove('current_name');
    await prefs.remove('current_birthDate');
    debugPrint('Logged out. Registered accounts preserved.');
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
    final credentialsJson = prefs.getStringList('account_credentials') ?? [];

    for (final credentialJson in credentialsJson) {
      final credential = _jsonDecode(credentialJson);
      if (credential['email'] == email) {
        // Update current account info
        await prefs.setString('current_email', email);
        await prefs.setString('current_password', credential['password'] ?? '');
        await prefs.setString('current_name', credential['name'] ?? '');
        await prefs.setString(
          'current_birthDate',
          credential['birthDate'] ?? '',
        );
        await prefs.setBool('isLoggedIn', true);
        return true;
      }
    }

    return false;
  }

  // Delete a specific account
  Future<bool> deleteAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove from credentials
    final credentialsJson = prefs.getStringList('account_credentials') ?? [];
    final updatedCredentials = credentialsJson.where((credentialJson) {
      final credential = _jsonDecode(credentialJson);
      return credential['email'] != email;
    }).toList();

    // Remove from accounts list
    final accountsJson = prefs.getStringList('user_accounts') ?? [];
    final updatedAccounts = accountsJson.where((accountJson) {
      final account = UserAccount.fromMap(_jsonDecode(accountJson));
      return account.email != email;
    }).toList();

    if (updatedCredentials.length < credentialsJson.length) {
      await prefs.setStringList('account_credentials', updatedCredentials);
      await prefs.setStringList('user_accounts', updatedAccounts);

      // If the deleted account is the currently logged-in one, logout
      final currentEmail = prefs.getString('current_email');
      if (currentEmail == email) {
        await logout();
      }

      return true;
    }

    return false;
  }

  Future<bool> requestPasswordReset(String email) async {
    debugPrint('Password reset requested for: $email');

    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getStringList('account_credentials') ?? [];

    debugPrint('Total accounts in storage: ${credentialsJson.length}');

    // Check if email exists
    bool accountExists = false;
    for (final credentialJson in credentialsJson) {
      final credential = _jsonDecode(credentialJson);
      debugPrint('Checking account: ${credential['email']}');
      if (credential['email'] == email) {
        accountExists = true;
        debugPrint('Account found!');
        break;
      }
    }

    if (!accountExists) {
      debugPrint('Account not found in storage');
      return false; // Email not found
    }

    debugPrint('Account exists, generating new password...');

    // Generate a new temporary password
    final newPassword = _generateTemporaryPassword();
    debugPrint('New password generated: $newPassword');

    // Send reset email
    debugPrint('Attempting to send email...');
    final emailSent = await EmailService().sendPasswordResetEmail(
      email,
      newPassword,
    );

    if (emailSent) {
      debugPrint('Email sent successfully, updating storage...');

      // Update the password in storage
      final updatedCredentials = credentialsJson.map((credentialJson) {
        final credential = _jsonDecode(credentialJson);
        if (credential['email'] == email) {
          credential['password'] = newPassword;
          return _jsonEncode(credential);
        }
        return credentialJson;
      }).toList();

      await prefs.setStringList('account_credentials', updatedCredentials);
      debugPrint('Password updated in storage');
      return true;
    }

    debugPrint('Failed to send email');
    return false;
  }

  Future<bool> resetPasswordWithToken(
    String email,
    String token,
    String newPassword,
  ) async {
    // For a more secure implementation, you'd validate the token here
    // For now, we'll implement a simple version that just updates the password

    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getStringList('account_credentials') ?? [];

    final updatedCredentials = credentialsJson.map((credentialJson) {
      final credential = _jsonDecode(credentialJson);
      if (credential['email'] == email) {
        credential['password'] = newPassword;
        return _jsonEncode(credential);
      }
      return credentialJson;
    }).toList();

    await prefs.setStringList('account_credentials', updatedCredentials);
    return true;
  }

  String _generateTemporaryPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Map<String, dynamic> _jsonDecode(String jsonString) {
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

        final cleanKey = key.replaceAll('"', '');
        final cleanValue = value.replaceAll('"', '');

        result[cleanKey] = cleanValue;
      }
    }

    return result;
  }

  String _jsonEncode(Map<String, dynamic> map) {
    final entries = map.entries.map(
      (entry) => '"${entry.key}": "${entry.value}"',
    );
    return '{${entries.join(', ')}}';
  }
}
