import 'package:flutter/material.dart';
import 'package:laporin_app/home_page.dart';
import 'package:laporin_app/services/auth_storage.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<String?>? _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = AuthStorage.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laporin App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ================= Login Page =================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  final _api = ApiService(baseUrl: 'http://127.0.0.1:8001/api');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final ok = res['success'] == true;
      final msg =
          (res['message'] as String?) ??
          (ok ? 'Login berhasil' : 'Login gagal');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (ok && mounted) {
        final token = res['token'] as String?;
        if (token != null) {
          await AuthStorage.saveToken(token); // simpan token
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              api: ApiService(
                baseUrl: 'http://127.0.0.1:8001/api',
                token: token,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    );
    if (!emailRegex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LaporIn Aja')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Masuk',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          onFieldSubmitted: (_) => _onLoginPressed(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _onLoginPressed,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun? "),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= Register Page =================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  final _api = ApiService(baseUrl: 'http://127.0.0.1:8001/api'); // Ganti URL

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _passwordC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  String? _vName(String? v) =>
      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null;
  String? _vEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final r = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    if (!r.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _vPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) return 'Masukkan 10–15 digit';
    return null;
  }

  String? _vAddress(String? v) =>
      v == null || v.trim().length < 10 ? 'Alamat terlalu singkat' : null;
  String? _vPassword(String? v) =>
      v == null || v.length < 6 ? 'Minimal 6 karakter' : null;
  String? _vConfirm(String? v) =>
      v != _passwordC.text ? 'Password tidak sama' : null;

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.register(
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
        phone: _phoneC.text.trim(),
        address: _addressC.text.trim(),
        password: _passwordC.text.trim(),
      );
      final msg = res['success'] == true
          ? 'Registrasi berhasil'
          : (res['data']['message'] ?? 'Registrasi gagal');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (res['success'] == true && mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registrasi gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameC,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                      ),
                      validator: _vName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _vEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneC,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Nomor HP'),
                      validator: _vPhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressC,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Alamat'),
                      validator: _vAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordC,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure1 = !_obscure1),
                          icon: Icon(
                            _obscure1 ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: _vPassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmC,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                          icon: Icon(
                            _obscure2 ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: _vConfirm,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _onRegister,
                        child: _isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : const Text('Buat Akun'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
