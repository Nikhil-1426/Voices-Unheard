import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 230, 242),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6A3DE8), // Rich purple representing diversity
                            Color(0xFF3B82F6), // Vibrant blue for inclusivity
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7209B7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildSettingsCard(
                        title: 'Help Centre',
                        subtitle: 'Get support and answers to your questions',
                        icon: Icons.help_outline_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        routeName: '/helpCentre',
                        context: context,
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsCard(
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms of service and policies',
                        icon: Icons.description_outlined,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFFFAB91)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        routeName: '/termsAndConditions',
                        context: context,
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsCard(
                        title: 'About Us',
                        subtitle: 'Learn more about Voices Unheard',
                        icon: Icons.diversity_3_rounded,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFC107), // Bright golden yellow for a rich pop
                            Color(0xFFFFA000), // Deep amber for warmth and contrast
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        routeName: '/aboutUs',
                        context: context,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6A3DE8),
          unselectedItemColor: Colors.grey[400],
          currentIndex: 4,
          elevation: 0,
          onTap: (index) {
            if (index == 0) Navigator.pushNamed(context, '/products');
            if (index == 1) Navigator.pushNamed(context, '/community');
            if (index == 2) Navigator.pushNamed(context, '/home');
            if (index == 3) Navigator.pushNamed(context, '/education');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Product'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.house_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'Education'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required String routeName,
    required BuildContext context,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A3DE8), // Rich purple representing diversity
                      Color(0xFF3B82F6), // Vibrant blue for inclusivity
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.pushNamed(context, routeName),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 213, 213, 213),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}