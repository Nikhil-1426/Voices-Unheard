// Copyright (c) 2025 [Your Name or Team Name]
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voices_unheard/app_colors.dart';
import 'education_page.dart';
import 'community_page.dart';
import 'product_page.dart';
import 'settings_page.dart';
import 'home_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isEditing = false;
  int _selectedIndex = 4; // Default to Settings page

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // Avoids error if no data exists

      if (response == null) {
        setState(() {
          userProfile = {};
          isLoading = false;
        });
      } else {
        setState(() {
          userProfile = response;
          _nameController.text = response['name'] ?? "";
          _genderController.text = response['gender'] ?? "";
          _ageController.text = response['age']?.toString() ?? "";
          _phoneController.text = response['phone'] ?? "";
          _locationController.text = response['location'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profileData = {
      'id': user.id,
      'name': _nameController.text.trim(),
      'gender': _genderController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
    };

    try {
      await supabase.from('profiles').upsert(profileData);
      setState(() {
        userProfile = profileData;
        isEditing = false;
      });
    } catch (e) {
      print("Error saving profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFF6A3DE8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isEditing ? _buildEditForm() : _buildProfileView(),
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
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        TextField(
          controller: _genderController,
          decoration: const InputDecoration(labelText: "Gender"),
        ),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(labelText: "Age"),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: "Phone"),
          keyboardType: TextInputType.phone,
        ),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: "Location"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6A3DE8)),
          onPressed: _saveUserProfile,
          child: const Text("Save Profile", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

 Widget _buildProfileView() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      CircleAvatar(
        radius: 60,
        backgroundImage: AssetImage('assets/profile_placeholder.png'),
      ),
      const SizedBox(height: 16),
      Text(
        userProfile!['name'] ?? "N/A",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10),
      _buildProfileDetail(Icons.person, userProfile!['gender'] ?? "N/A"),
      _buildProfileDetail(Icons.calendar_today, userProfile!['age']?.toString() ?? "N/A"),
      _buildProfileDetail(Icons.phone, userProfile!['phone'] ?? "N/A"),
      _buildProfileDetail(Icons.location_on, userProfile!['location'] ?? "N/A"),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A3DE8),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          setState(() {
            isEditing = true;
          });
        },
        icon: Icon(Icons.edit, color: Colors.white),
        label: Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
    ],
  );
}

Widget _buildProfileDetail(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
}