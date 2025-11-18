import 'package:flutter/material.dart';
import 'package:reading_app/screens/password_reset_screen.dart';
import 'package:reading_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _name = '';
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 18));

  int _failedAttempts = 0;
  DateTime? _lastFailedAttempt;

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    final hasAccount = await _authService.hasAccount();
    setState(() {
      _isLogin = hasAccount;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (_isLogin && _failedAttempts >= 5) {
      final now = DateTime.now();
      if (_lastFailedAttempt != null &&
          now.difference(_lastFailedAttempt!) < const Duration(minutes: 1)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tentativas excedidas, bloqueio de 1 minuto para tentativas',
              ),
            ),
          );
        }
        return;
      } else {
        // Reset counter if block time has passed
        _failedAttempts = 0;
      }
    }

    if (_isLogin) {
      final success = await _authService.login(_email, _password);
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _failedAttempts++;
          _lastFailedAttempt = DateTime.now();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha ou email inválidos')),
          );
        }
      }
    } else {
      final success = await _authService.register(
        _email,
        _password,
        _name,
        _birthDate,
      );
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Apenas contas gmails')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!_isLogin) ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if (value == null || value.length < 5) {
                      return 'Nome deve possuir 5 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Coloque um email válido';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Senha deve ter 6 digitos';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Data de Nascimento: ${_birthDate.toLocal()}'.split(' ')[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _birthDate = date);
                    }
                  },
                ),
              ],
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordResetScreen(),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? 'Ainda não possue conta? Registre aqui'
                      : 'Já possue uma conta? Faça login aqui',
                ),
              ),
              if (_isLogin) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Feature de recuperação de senha inativa',
                        ),
                      ),
                    );
                  },
                  child: const Text('Esqueceu a senha?'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
