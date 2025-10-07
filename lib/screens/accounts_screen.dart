import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AuthService _authService = AuthService();
  List<UserAccount> _accounts = [];
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _authService.getAllAccounts();
    final currentEmail = await _authService.getEmail();
    
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _currentEmail = currentEmail;
      });
    }
  }

  Future<void> _switchAccount(UserAccount account) async {
    final success = await _authService.switchAccount(account.email);
    if (success && mounted) {
      setState(() {
        _currentEmail = account.email;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${account.email}')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Accounts'),
      ),
      body: _accounts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No accounts registered yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final isCurrent = account.email == _currentEmail;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isCurrent ? Colors.blue[50] : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? Colors.blue : Colors.grey,
                      child: Text(
                        account.name.isNotEmpty ? account.name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      account.name,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.email),
                        Text(
                          'Registered: ${_formatDate(account.registrationDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Birth Date: ${_formatDate(account.birthDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: isCurrent
                        ? const Chip(
                            label: Text('Current'),
                            backgroundColor: Colors.blue,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: () => _switchAccount(account),
                            child: const Text('Switch'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}