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
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _authService.getAllAccounts();
    _currentUserEmail = await _authService.getCurrentUserEmail();

    if (mounted) {
      setState(() {
        _accounts = accounts;
      });
    }
  }

  Future<void> _switchAccount(String email) async {
    final success = await _authService.switchAccount(email);
    if (success && mounted) {
      _currentUserEmail = await _authService.getCurrentUserEmail();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to switch account'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount(String email) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text(
            'Are you sure you want to delete $email? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _authService.deleteAccount(email);
                if (success && mounted) {
                  await _loadAccounts();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Account $email deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete account'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registered Accounts')),
      body: _accounts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
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
                final isCurrentUser = account.email == _currentUserEmail;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentUser
                          ? Colors.blue
                          : Colors.grey,
                      child: Text(
                        account.name.isNotEmpty
                            ? account.name[0].toUpperCase()
                            : account.email[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name.isNotEmpty ? account.name : 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          account.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Birth Date: ${_formatDate(account.birthDate)}'),
                        Text(
                          'Registered: ${_formatDate(account.registrationDate)}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (!isCurrentUser) ...[
                          IconButton(
                            icon: const Icon(Icons.switch_account),
                            onPressed: () => _switchAccount(account.email),
                            tooltip: 'Switch to this account',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteAccount(account.email),
                            tooltip: 'Delete account',
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
