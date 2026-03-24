import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _entryController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _slideAnims = List.generate(5, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(i * 0.12, 0.6 + i * 0.08, curve: Curves.easeOutCubic),
      ));
    });

    _fadeAnims = List.generate(5, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(i * 0.12, 0.6 + i * 0.08),
        ),
      );
    });

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _animated(int idx, Widget child) {
    return SlideTransition(
      position: _slideAnims[idx],
      child: FadeTransition(opacity: _fadeAnims[idx], child: child),
    );
  }

  Future<void> _handleLogin() async {
    try {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _isLoading = true);

      final result = await AuthService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const DashboardScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // ✅ FIX: Clear error message for wrong email/password
              content: const Text(
                '❌ Wrong email or password. Please try again.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.deepCaramel,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Incorrect email or password. Try again.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.deepCaramel,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // ── Top hero ───────────────────────────────────
              Container(
                height: size.height * 0.40,
                decoration: const BoxDecoration(
                  gradient: AppTheme.chocolateGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Stack(
                  children: [
                    // Dot pattern overlay
                    Positioned.fill(
                      child: CustomPaint(painter: _DotPatternPainter()),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 60, left: 28, right: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text('🧁',
                                    style: TextStyle(fontSize: 26)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sweet Cengsations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Online Bakeshop',
                                    style: TextStyle(
                                      color: AppTheme.gold.withOpacity(0.85),
                                      fontSize: 12,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Welcome\nBack! 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to order your favourite treats',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form card ──────────────────────────────────
              Positioned(
                top: size.height * 0.34,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.chocolate.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _animated(
                          4,
                          const Text(
                            'Login to your account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkChoco,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email
                        _animated(
                          0,
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppTheme.caramel.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Email is required';
                              if (!v.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _animated(
                          2,
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.caramel.withOpacity(0.7),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppTheme.caramel.withOpacity(0.7),
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Forgot password
                        _animated(
                          3,
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.caramel,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Login button
                        _animated(
                          4,
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const DashboardScreen()),
                                );
                              },
                              // onPressed: () async =>
                              //     _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.chocolate,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded,
                                            size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: AppTheme.roseDust.withOpacity(0.4))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: AppTheme.chocolate.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: AppTheme.roseDust.withOpacity(0.4))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Register link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppTheme.chocolate.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                child: const Text(
                                  'Create one',
                                  style: TextStyle(
                                    color: AppTheme.caramel,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Decorative dot pattern painter
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
