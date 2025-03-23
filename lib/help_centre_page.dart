// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'home_page.dart';
import 'community_page.dart';
import 'product_page.dart';
import 'education_page.dart';
import 'settings_page.dart';

class HelpCentrePage extends StatefulWidget {
  const HelpCentrePage({Key? key}) : super(key: key);

  @override
  _HelpCentrePageState createState() => _HelpCentrePageState();
}

class _HelpCentrePageState extends State<HelpCentrePage> {
  final int _selectedIndex = 4;

  Future<String?> _getUid() async {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? (await SharedPreferences.getInstance()).getString('uid');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.colors['background'],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Help Centre",
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
              _buildSectionTitle("Common Questions"),
              const SizedBox(height: 16),
              _buildFAQSection(),
              const SizedBox(height: 16),
              _buildContactSupport(),
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
            elevation: 0,
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
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              "Welcome to Help Centre",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Find answers to common questions or reach out to our support team for assistance.",
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.colors['accent2'],
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<Map<String, String>> faqs = [
      {
        "question": "How do I connect with a community?",
        "answer": "Navigate to the 'Community' tab to discover and join support groups, participate in discussions, and connect with others who share similar experiences."
      },
      {
        "question": "How do I update my profile?",
        "answer": "Go to Settings > Profile to update your personal information, preferences, and privacy settings. You can also customize your notification preferences here."
      },
      {
        "question": "How can I report an issue?",
        "answer": "If you encounter any problems or concerns, tap the three dots (...) menu in any screen and select 'Report Issue'. You can also contact our support team directly through the Help Centre."
      },
      {
        "question": "Is my information secure?",
        "answer": "Yes, we use industry-standard encryption and security measures to protect your personal information. You can review our privacy policy in the Settings section."
      },
    ];

    return Column(
      children: faqs.map((faq) => _buildFAQCard(faq["question"]!, faq["answer"]!)).toList(),
    );
  }

  Widget _buildFAQCard(String question, String answer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
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
                child: const Icon(Icons.question_answer_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.colors['primary'],
                  height: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // Implement contact support functionality
        },
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
                child: const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Need more help?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Contact our support team",
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
