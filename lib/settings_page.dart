import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'community_page.dart';
import 'education_page.dart';
import 'home_page.dart';
import 'product_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);
  final int _selectedIndex = 4;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.colors['background'],
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            "Settings",
            style: TextStyle(
              color: AppColors.colors['accent2'],
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: AppColors.colors['accent2'],
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingsCard(
                title: 'User Profile',
                subtitle: 'View and edit your profile details',
                icon: Icons.person_outline_rounded,
                routeName: '/userProfile',
                context: context,
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                title: 'Help Centre',
                subtitle: 'Get support and answers to your questions',
                icon: Icons.help_outline_rounded,
                routeName: '/helpCentre',
                context: context,
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                title: 'Terms & Conditions',
                subtitle: 'Read our terms of service and policies',
                icon: Icons.description_outlined,
                routeName: '/termsAndConditions',
                context: context,
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                title: 'About Us',
                subtitle: 'Learn more about Voices Unheard',
                icon: Icons.diversity_3_rounded,
                routeName: '/aboutUs',
                context: context,
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.colors['background']!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                label: 'Product',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_sharp),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.house_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books_rounded),
                label: 'Education',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.colors['accent2'],
            unselectedItemColor: AppColors.colors['primary'],
            backgroundColor: Colors.white,
            elevation: 5,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              Widget page;
              switch (index) {
                case 0:
                  page = ProductPage();
                  break;
                case 1:
                  page = CommunityPage();
                  break;
                case 2:
                  page = HomePage();
                  break;
                case 3:
                  page = EducationPage();
                  break;
                case 4:
                  page = SettingsPage();
                  break;
                default:
                  return;
              }
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => page,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String routeName,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, routeName),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.colors['accent2']!,
                      AppColors.colors['accent1']!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.colors['primary'],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.colors['primary'],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}