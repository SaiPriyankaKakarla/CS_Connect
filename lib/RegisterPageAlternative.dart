import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPageAlternative extends StatefulWidget {
  const RegisterPageAlternative({super.key});
  @override
  _RegisterPageAlternativeState createState() =>
      _RegisterPageAlternativeState();
}

class _RegisterPageAlternativeState extends State<RegisterPageAlternative> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      Navigator.pop(context); // Go back to login page
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset('assets/register_bg.png', fit: BoxFit.cover),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.app_registration_rounded,
                    size: 80, color: Color(0xFF7A5EF7)),
                const SizedBox(height: 16),
                const Text("Register",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292D32))),
                const SizedBox(height: 8),
                const Text("Create a new account",
                    style: TextStyle(fontSize: 14, color: Color(0xFF6E6E6E))),
                const SizedBox(height: 32),
                _buildInput(_emailCtrl, "Email", Icons.email_outlined),
                const SizedBox(height: 16),
                _buildInput(_passCtrl, "Password", Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 16),
                _buildInput(
                    _confirmPassCtrl, "Confirm Password", Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 28),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Register",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text("Login",
                          style: TextStyle(
                              color: Color(0xFF7A5EF7),
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildInput(TextEditingController ctl, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: ctl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7A5EF7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7A5EF7), width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7A5EF7), width: 2)),
      ),
    );
  }
}
