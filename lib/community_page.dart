// Copyright (c) 2025 [Your Name or Team Name]
// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voices_unheard/app_colors.dart';
import 'product_page.dart';
import 'home_page.dart';
import 'education_page.dart';
import 'settings_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunitiesPageState createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController communityNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController requisitesController = TextEditingController();
  List<Map<String, dynamic>> communities = [];
  String? userId;
  int _selectedIndex = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
void initState() {
  super.initState();
  userId = supabase.auth.currentUser?.id;
  _fetchCommunities();

  _controller = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeIn),
  );

  _controller.forward();
}

  Future<void> _fetchCommunities() async {
    try {
      final response = await supabase.from('communities').select();
      setState(() {
        communities = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackBar('Error fetching communities: ${e.toString()}');
    }
  }

  Future<void> _createCommunity() async {
  if (communityNameController.text.isEmpty) return;

    try {
    final response = await supabase.from('communities').insert({
      'name': communityNameController.text,
      'description': descriptionController.text, 
      'admin_id': supabase.auth.currentUser?.id,
      'requisites': requisitesController.text,
    }).select('id');

    final communityId = response.first['id'];

    await supabase.from('community_members').insert({
      'community_id': communityId,
      'user_id': userId,
      'role': 'admin',
    });

    _showSnackBar('Community created successfully!');
  } catch (e) {
    _showSnackBar('Error creating community: ${e.toString()}');
  } finally {
    // ✅ Always clear input fields and refresh communities
    communityNameController.text = "";
    requisitesController.text = "";
    descriptionController.text = "";

    // ✅ Refresh the list without shifting focus
    _fetchCommunities();
  }
}


  Future<void> _requestToJoin(String communityId) async {
  try {
    await supabase.from('join_requests').insert({
      'community_id': communityId,
      'user_id': userId,
      'role': 'member',
    });

    _showSnackBar('Request sent to admin!');
  } catch (e) {
    debugPrint('Supabase error: ${e.toString()}'); // Logs error to debug console
    _showSnackBar('Error sending request: ${e.toString()}');
  }
}


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });

  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProductPage()),
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CommunityPage()),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      break;
    case 3:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EducationPage()),
      );
      break;
    case 4:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
      break;
  }
}

  @override
  void dispose() {
    _controller.dispose();
    communityNameController.dispose();
    descriptionController.dispose();
    requisitesController.dispose();
    super.dispose();
  }

  void _showCreateCommunityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.colors['background'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Create New Community",
            style: TextStyle(
              color: AppColors.colors['accent2'],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: communityNameController,
                  label: "Community Name",
                  hint: "Enter community name",
                  icon: Icons.group,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: requisitesController,
                  label: "Requisites",
                  hint: "Enter joining requirements",
                  icon: Icons.check_circle_outline,
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: "Description",
                  hint: "Describe your community",
                  icon: Icons.description,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppColors.colors['primary']),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.colors['accent2']!,
                    AppColors.colors['accent1']!,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createCommunity();
                },
                child: Text(
                  "Create",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.colors['accent2']),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
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
            "Communities",
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
          onRefresh: _fetchCommunities,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.colors['accent2']!.withOpacity(0.1),
                            AppColors.colors['accent1']!.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome to Our Communities",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.colors['accent2'],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Join existing communities or create your own to connect with others.",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.colors['primary'],
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.colors['accent2']!,
                                  AppColors.colors['accent1']!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.colors['accent2']!.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton.icon(
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text(
                                "Create New Community",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _showCreateCommunityDialog,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final community = communities[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                AppColors.colors['background']!.withOpacity(0.5),
                              ],
                            ),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              community['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.colors['accent2'],
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              community['description'] ?? "No description available",
                              style: TextStyle(color: AppColors.colors['primary']),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (community['requisites'] != null)
                                      Text(
                                        "Requirements: ${community['requisites']}",
                                        style: TextStyle(
                                          color: AppColors.colors['primary'],
                                        ),
                                      ),
                                    SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.colors['accent2']!,
                                            AppColors.colors['accent1']!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TextButton(
                                        onPressed: () => _requestToJoin(community['id'].toString()),
                                        child: Text(
                                          "Request to Join",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: communities.length,
                  ),
                ),
              ],
            ),
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
                offset: Offset(0, -2),
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}