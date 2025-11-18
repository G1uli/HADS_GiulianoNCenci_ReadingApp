import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _resetSuccessful = false;
  String _message = '';

  Future<void> _requestPasswordReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = 'Please enter your email address';
      });
      return;
    }

    if (!_emailController.text.endsWith('@gmail.com')) {
      setState(() {
        _message = 'Please enter a valid Gmail address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final success = await _authService.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (success) {
        setState(() {
          _resetSuccessful = true;
          _message =
              'Password reset email sent! Check your inbox for the new temporary password.';
        });
      } else {
        setState(() {
          _resetSuccessful = false;
          _message =
              'Email not found or error sending email. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _resetSuccessful = false;
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forgot your password?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address and we\'ll send you a new temporary password.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            if (!_resetSuccessful) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your-email@gmail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              if (_message.isNotEmpty && !_resetSuccessful)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestPasswordReset,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Send Reset Email'),
                      ),
                    ),
            ] else ...[
              // Show confirmed message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Password Reset Email Sent!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _message,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Check your email inbox (and spam folder) for the temporary password',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back to Login'),
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (!_resetSuccessful)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
          ],
        ),
      ),
    );
  }
}
