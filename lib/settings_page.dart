import 'package:flutter/material.dart';
import 'home_page.dart';
import 'community_page.dart';
import 'education_page.dart';
import 'product_page.dart';
import 'package:voices_unheard/app_colors.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.grey,
      ),
      body: Center(
        child: Text(
          "Settings Page",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        
        selectedItemColor: AppColors.colors['accent2'],
        unselectedItemColor: AppColors.colors['primary'],
        backgroundColor: Colors.white,
        currentIndex: 4,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
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
      )
        );
  }
      
  
}