import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'community_page.dart';
import 'product_page.dart';
import 'home_page.dart';
import 'education_page.dart';
import 'settings_page.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
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
          automaticallyImplyLeading: true,
          title: Text(
            "Terms & Conditions",
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
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              ..._buildTermsSections(),
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

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              "Welcome to Voices Unheard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please review our terms and conditions before engaging with the platform.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.colors['primary'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTermsSections() {
    final sections = [
      {
        'icon': Icons.gavel_rounded,
        'title': '1. Acceptance of Terms',
        'content':
            'By using Voices Unheard, you agree to abide by our terms and conditions. Violation of these terms may result in account suspension or removal from the platform.',
      },
      {
        'icon': Icons.security_rounded,
        'title': '2. Privacy & Security',
        'content':
            'We prioritize your privacy and security. Your personal data will not be shared without consent. We use encryption and security protocols to protect user information.',
      },
      {
        'icon': Icons.people_rounded,
        'title': '3. Community Guidelines',
        'content':
            'To maintain a respectful community, users must avoid hate speech, harassment, or any form of discrimination. Violations may lead to immediate action.',
      },
      {
        'icon': Icons.article_rounded,
        'title': '4. Content Responsibility',
        'content':
            'Users are responsible for the content they post. Any content violating our guidelines will be removed, and necessary action will be taken against repeat offenders.',
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '5. Contact & Support',
        'content':
            'For any queries or disputes, contact us at:\n📧 voicesunheard@gmail.com\n📞 +91 98765 43210',
      },
    ];

    return sections.map((section) {
      return Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Icon(section['icon'] as IconData,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    section['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section['content'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colors['primary'],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }
}