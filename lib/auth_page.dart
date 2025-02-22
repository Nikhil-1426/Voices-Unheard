import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

final supabase = Supabase.instance.client;

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isSignUp = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Vibrant color palette celebrating diversity
  final Map<String, Color> colors = {
    'primary': Color(0xFF6B6B),    // Vibrant coral
    'secondary': Color(0xFF4ECDC4),   // Turquoise
    'accent1': Color(0xFFFFBE0B),     // Golden yellow
    'accent2': Color(0xFF7209B7),     // Deep purple
    'accent3': Color(0xFF06D6A0),     // Emerald
    'background': Color(0xFFFFF1E6),  // Warm cream
    'error': Color(0xFFFF4858),       // Bright red
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
      );
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to our diverse community! Please verify your email.'),
            backgroundColor: colors['accent2'],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: colors['error'],
        ),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: colors['error'],
        ),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: colors['background'],
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors['background']!,
                colors['background']!.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 40),
                        // Decorative pattern
                        Container(
                          height: 80,
                          child: CustomPaint(
                            painter: PatternPainter(colors: [
                              colors['accent1']!,
                              colors['accent2']!,
                              colors['accent3']!,
                            ]),
                          ),
                        ),
                        SizedBox(height: 32),
                        // Welcome header with cultural patterns
                        Text(
                          isSignUp ? 'Join Our Diverse Community' : 'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors['accent2'],
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          isSignUp
                              ? 'Create your space in our inclusive community'
                              : 'Continue your journey with us',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors['accent2']!.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 48),
                        // Email field with custom decoration
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                colors['background']!.withOpacity(0.5),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined, color: colors['accent2']),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: [AutofillHints.email],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Password field with custom decoration
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                colors['background']!.withOpacity(0.5),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(Icons.lock_outline, color: colors['accent2']),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (isSignUp && value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: [AutofillHints.password],
                          ),
                        ),
                        SizedBox(height: 32),
                        // Animated submit button
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                colors['accent2']!,
                                colors['accent1']!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors['accent2']!.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : (isSignUp ? signUp : signIn),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    isSignUp ? 'Join Community' : 'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Toggle button with animation
                        TextButton(
                          onPressed: () => setState(() {
                            isSignUp = !isSignUp;
                            _controller.reset();
                            _controller.forward();
                          }),
                          child: Text(
                            isSignUp
                                ? 'Already part of our community? Sign In'
                                : 'New to our community? Join Us',
                            style: TextStyle(
                              color: colors['accent2'],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for decorative pattern
class PatternPainter extends CustomPainter {
  final List<Color> colors;

  PatternPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create abstract shapes representing diversity
    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i].withOpacity(0.7);
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.3), size.height * 0.5),
        20 + i * 5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}