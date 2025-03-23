// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'community_page.dart';
import 'education_page.dart';
import 'home_page.dart';
import 'product_page.dart';
import 'settings_page.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);
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
          title: Text(
            "About Us",
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
              _buildWelcomeSection(),
              const SizedBox(height: 16),
              _buildTeamSection(),
              const SizedBox(height: 16),
              _buildMissionSection(),
              const SizedBox(height: 16),
              _buildValuesSection(),
              const SizedBox(height: 16),
              _buildContactSection(),
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

  Widget _buildSectionCard({
    required String title,
    required Widget content,
    required IconData icon,
  }) {
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
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return _buildSectionCard(
      title: "Welcome to Voices Unheard",
      icon: Icons.diversity_3_rounded,
      content: Text(
        "We're dedicated to amplifying the voices of underrepresented communities and creating positive change through connection and support.",
        style: TextStyle(
          fontSize: 16,
          color: AppColors.colors['primary'],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return _buildSectionCard(
      title: "Meet Our Team",
      icon: Icons.groups_rounded,
      content: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildTeamMember("Arnav", "Backend Developer", Icons.code),
          _buildTeamMember("Nikhil", "App Developer", Icons.design_services),
          _buildTeamMember("Aditi A", "Frontend Lead", Icons.analytics),
          _buildTeamMember("Aditi B", "UI/UX Designer", Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String role, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colors['background'],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.colors['accent2']!.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.colors['accent2']!.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppColors.colors['accent2']),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.colors['accent2'],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.colors['primary'],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return _buildSectionCard(
      title: "Our Mission",
      icon: Icons.lightbulb_outline_rounded,
      content: Text(
        "To empower underrepresented communities by providing a platform for their voices to be heard, stories to be shared, and experiences to be validated. We believe in creating a world where every voice matters and every story has the power to inspire change.",
        style: TextStyle(
          fontSize: 16,
          color: AppColors.colors['primary'],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildValuesSection() {
    return _buildSectionCard(
      title: "Our Values",
      icon: Icons.favorite_rounded,
      content: Column(
        children: [
          _buildValueItem("Inclusivity", "Creating spaces where everyone belongs"),
          _buildValueItem("Empowerment", "Supporting individual and collective growth"),
          _buildValueItem("Authenticity", "Encouraging genuine expression"),
          _buildValueItem("Community", "Building meaningful connections"),
        ],
      ),
    );
  }

  Widget _buildValueItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.colors['accent2'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
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
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.colors['primary'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSectionCard(
      title: "Get in Touch",
      icon: Icons.contact_mail_rounded,
      content: Text(
        "We'd love to hear from you! Reach out to us at:\n\n📧 voicesunheard@gmail.com\n📞 +91 98765 43210\n\nConnect with us on social media @VoicesUnheard",
        style: TextStyle(
          fontSize: 16,
          color: AppColors.colors['primary'],
          height: 1.5,
        ),
      ),
    );
  }
}
