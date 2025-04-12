import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barn_air_monitor/screens/auth/signup_screen.dart';
import 'package:barn_air_monitor/screens/dashboard_screen.dart';
import 'package:barn_air_monitor/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _usePhoneAuth = false;
  String? _verificationId;
  String _otpCode = '';
  bool _showOtpField = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen(barnId: 'default_barn')),
          );
        }
      } on FirebaseAuthException catch (e) {
        _showError('Sign-in Error: ${e.message}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _authService.sendOTP(
        _phoneController.text.trim(),
        // Verification completed callback
            (AuthCredential credential) async {
          final user = (await FirebaseAuth.instance.signInWithCredential(credential)).user;
          if (user != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen(barnId: 'default_barn')),
            );
          }
        },
        // Verification failed callback
            (FirebaseAuthException e) => _showError('OTP Error: ${e.message}'),
        // Code sent callback
            (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _showOtpField = true;
            _isLoading = false;
          });
        },
        // Auto-retrieval timeout callback (this is the missing 5th argument)
            (String verificationId) {
          // Usually you can just store the verification ID here
          // or show a message that auto-verification timed out
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      _showError('OTP Send Error: ${e.toString()}');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6 || _verificationId == null) return;

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCode,
      );

      final user = (await FirebaseAuth.instance.signInWithCredential(credential)).user;
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen(barnId: 'default_barn')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError('Verification Error: ${e.message}');
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and title
                  Icon(
                    Icons.eco,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BarnAir Monitor',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitor your barn\'s air quality',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 48),

                  // Toggle between email and phone auth
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _usePhoneAuth = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_usePhoneAuth
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            foregroundColor: !_usePhoneAuth
                                ? Colors.white
                                : Colors.black87,
                          ),
                          child: const Text('Email'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _usePhoneAuth = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _usePhoneAuth
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            foregroundColor: _usePhoneAuth
                                ? Colors.white
                                : Colors.black87,
                          ),
                          child: const Text('Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email login form
                  if (!_usePhoneAuth) ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Phone login form
                  if (_usePhoneAuth) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                            hintText: '+1234567890',
                          ),
                          keyboardType: TextInputType.phone,
                          enabled: !_showOtpField,
                        ),
                        const SizedBox(height: 16),
                        if (_showOtpField) ...[
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'OTP Code',
                              prefixIcon: Icon(Icons.pin),
                              hintText: '6-digit code',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onChanged: (value) {
                              _otpCode = value;
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOTP,
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Verify OTP'),
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendOTP,
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Send OTP'),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Sign up option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}