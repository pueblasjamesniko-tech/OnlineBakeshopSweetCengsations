import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import 'login_screen.dart';

// This is the Sign Up screen where new users create their account.
// Like filling out a form to join a bakery rewards club!
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // A key that lets us check if all form fields are filled in correctly
  // Text controllers — each one holds what the user typed in one input box
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); // ← NEW
  final _passwordController = TextEditingController();

  bool _obscurePassword = true; // True = password is hidden (shows dots)
  bool _isLoading = false; // True = form is being submitted, show spinner
  bool _agreed = false; // True = user checked the Terms & Conditions box

  // These control the slide-and-fade animation when the screen first opens
  late AnimationController _entryController;
  late List<Animation<Offset>> _slides; // Controls sliding up into place
  late List<Animation<double>> _fades; // Controls fading in from invisible

  // Runs when the screen opens — sets up the entry animations
  @override
  void initState() {
    super.initState();
    // The animation plays over 1.5 seconds total
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Create 7 slide animations, each starting a little later than the previous
    // This makes each field slide in one after another, like a staircase effect
    _slides = List.generate(7, (i) {
      return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(i * 0.10, 0.55 + i * 0.07, curve: Curves.easeOutCubic),
      ));
    });
    // Create 7 fade animations that match the slide animations
    _fades = List.generate(7, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(i * 0.10, 0.55 + i * 0.07),
        ),
      );
    });
    _entryController.forward();
  }

  // Clean up the animation controller and text controllers when the screen closes
  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose(); // ← NEW
    _passwordController.dispose();
    super.dispose();
  }

  // Shortcut helper that wraps any widget with a slide + fade animation.
  // "i" is which animation slot (0–6) to use.
  Widget _a(int i, Widget child) => SlideTransition(
        position: _slides[i],
        child: FadeTransition(opacity: _fades[i], child: child),
      );

  // Runs when the user taps "Create Account".
  // Validates the form, checks the checkbox, then sends data to the server.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    // Stop if the user hasn't agreed to the Terms & Conditions
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to our Terms & Conditions'),
          backgroundColor: AppTheme.deepCaramel,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // Show the spinner, disable the button

    // Send the user's details to the server to create their account
    final result = await ApiService.registerUser(
      fullname: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      contactno: _phoneController.text.trim(),
      address: _addressController.text.trim(), // ← NEW
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Registration worked! Show a 🎉 success popup
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 12),
                const Text(
                  'Account Created!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkChoco,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to Sweet Cengsations!\nEnjoy your first order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.chocolate.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.chocolate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Go to Login'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Registration failed — show the error message from the server
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // A reusable helper that builds one styled text input field with animation.
  // "idx" tells it which slide/fade animation to use.
  Widget _buildField({
    required int idx,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false, // True = hide the text (for passwords)
    bool hasToggle = false, // True = show the eye icon to show/hide password
    VoidCallback? onToggle, // What happens when the eye icon is tapped
    int maxLines = 1,
    String? Function(String?)? validator, // Checks if the input is valid
  }) {
    return _a(
      idx,
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, color: AppTheme.caramel.withOpacity(0.7), size: 20),
          // Show the eye toggle button only for password fields
          suffixIcon: hasToggle
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppTheme.caramel.withOpacity(0.7),
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: CustomScrollView(
        slivers: [
          // Collapsible top banner with the app name and a decorative dot pattern
          SliverAppBar(
            expandedHeight: 200,
            pinned: true, // Stays visible when scrolled up
            backgroundColor: AppTheme.chocolate,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.chocolateGradient,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _DotPainter()),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 24, bottom: 30, top: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Join the\nSweetness 🍰',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Create your Sweet Cengsations account',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
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

          // The registration form inside a white rounded card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.chocolate.withOpacity(0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey, // Connects the form to our validation key
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _a(
                        0,
                        const Text(
                          'Personal Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkChoco,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _a(
                        0,
                        Text(
                          'Fill in the details below to get started',
                          style: TextStyle(
                            color: AppTheme.chocolate.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Field 1: Full Name
                      _buildField(
                        idx: 1,
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Email Address — checks for "@" symbol
                      _buildField(
                        idx: 2,
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field 3: Phone Number
                      _buildField(
                        idx: 3,
                        controller: _phoneController,
                        label: 'Contact No.',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Phone is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Field 4: Address — allows 2 lines of text
                      _buildField(
                        idx: 4,
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Field 5: Password — hidden by default, has show/hide toggle
                      _buildField(
                        idx: 5,
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        hasToggle: true,
                        onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Password is required';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Checkbox: user must agree to Terms & Conditions to register
                      _a(
                        6,
                        Row(
                          children: [
                            Checkbox(
                              value: _agreed,
                              onChanged: (v) =>
                                  setState(() => _agreed = v ?? false),
                              activeColor: AppTheme.caramel,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: AppTheme.chocolate.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                  children: const [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(
                                        color: AppTheme.caramel,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppTheme.caramel,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // "Create Account" button — disabled while loading, shows spinner
                      _a(
                        6,
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // "Already have an account? Sign In" link at the bottom
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Sign In',
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
          ),
        ],
      ),
    );
  }
}

// A custom painter that draws a subtle grid of tiny dots in the header background.
// Like a polka dot wallpaper — purely decorative!
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.05);
    const s = 22.0;
    // Loop across the whole area and draw a small circle every 22 pixels
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.5, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
