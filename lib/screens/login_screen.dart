import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/user_session.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // These control the text the user types in the email and password fields
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // If true, the password shows as dots (hidden). If false, it's visible.
  bool _obscurePassword = true;
  // If true, the login button shows a loading spinner instead
  bool _isLoading = false;

  // These handle the slide-in animations when the page first opens
  late AnimationController _entryController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    // Set how long the entry animation takes (1.4 seconds total)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Create 5 slide animations — each one starts a little later than the previous
    // This makes items appear one by one (staggered effect)
    _slideAnims = List.generate(5, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(i * 0.12, 0.6 + i * 0.08, curve: Curves.easeOutCubic),
      ));
    });

    // Create 5 fade animations that match the slide animations above
    _fadeAnims = List.generate(5, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(i * 0.12, 0.6 + i * 0.08),
        ),
      );
    });

    // Start playing the animation as soon as the screen opens
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Wraps any widget with a slide + fade animation using the index to pick the right animation
  Widget _animated(int idx, Widget child) {
    return SlideTransition(
      position: _slideAnims[idx],
      child: FadeTransition(opacity: _fadeAnims[idx], child: child),
    );
  }

  // This runs when the user taps the "Sign In" button
  Future<void> _handleLogin() async {
    // Stop if the form has errors (empty fields, invalid email, etc.)
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Send the email and password to our server and wait for the result
      final result = await ApiService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // ✅ Register FCM token right after successful login
        await _registerFcmToken();

        // Go to the Dashboard and remove the Login screen from the history
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DashboardScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        // Login failed — show an error message at the bottom of the screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Wrong email or password. Please try again.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.deepCaramel,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Something unexpected went wrong (e.g., no internet) — show a generic error
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Something went wrong. Please try again.',
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

  // Gets this phone's unique notification token and sends it to our server
  // This allows us to send push notifications to this specific device
  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      debugPrint('📱 FCM Token: $fcmToken');
      await ApiService.registerDevice(
        fcmToken: fcmToken,
        platform: 'Android',
      );
    } catch (e) {
      debugPrint('FCM registration failed: $e');
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
                height: size.height * 0.42,
                decoration: const BoxDecoration(
                  gradient: AppTheme.chocolateGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _DotPatternPainter()),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 56, left: 28, right: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Logo row ───────────────────────
                          Row(
                            children: [
                              // Real logo in rounded square container
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/images/bakeshop_logo.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
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

              // White form card — floats over the brown banner and holds the login fields
              Positioned(
                top: size.height * 0.36,
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

                        // Email input field — only accepts valid email format
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

                        // Password input field — hides the text and has a show/hide toggle
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

                        // Sign In button — shows a spinner while logging in
                        _animated(
                          4,
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              // Disable the button while loading so the user can't tap it twice
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.chocolate,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppTheme.chocolate.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              // Show a spinner if loading, otherwise show "Sign In"
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

                        // "Don't have an account?" — tapping "Create one" goes to Register screen
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

// Draws a grid of tiny dots on the brown banner for a decorative background effect
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
