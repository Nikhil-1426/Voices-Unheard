// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_colors.dart';
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

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isEditing = false;
  final int _selectedIndex = 4;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        userProfile = response ?? {};
        if (response != null) {
          _nameController.text = response['name'] ?? "";
          _genderController.text = response['gender'] ?? "";
          _ageController.text = response['age']?.toString() ?? "";
          _phoneController.text = response['phone'] ?? "";
          _locationController.text = response['location'] ?? "";
        }
        isLoading = false;
      });
      _runAnimation();
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() => isLoading = false);
      _showFeedback('Failed to load profile data', false);
    }
  }

  void _runAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _saveUserProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profileData = {
      'id': user.id,
      'name': _nameController.text.trim(),
      'gender': _genderController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('profiles').upsert(profileData);
      setState(() {
        userProfile = profileData;
        isEditing = false;
        isLoading = false;
      });
      _showFeedback('Profile updated successfully', true);
      _runAnimation();
    } catch (e) {
      setState(() => isLoading = false);
      _showFeedback('Failed to update profile', false);
    }
  }

  void _showFeedback(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.colors['accent2'] : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userEmail = supabase.auth.currentUser?.email ?? '';
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.colors['accent1']!,
                            AppColors.colors['accent2']!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          userProfile?['name']?.isNotEmpty == true
                              ? userProfile!['name'].substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.colors['accent2'],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isEditing)
                    GestureDetector(
                      onTap: () => setState(() => isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.colors['accent2'],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                userProfile?['name'] ?? 'Your Profile',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userEmail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.colors['primary']!.withOpacity(0.7),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (userProfile != null && userProfile!['updated_at'] != null)
                Text(
                  'Last updated: ${_formatDate(userProfile!['updated_at'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.colors['primary']!.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildInfoSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.colors['accent2'],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colors['primary'],
                    ),
                  ),
                ],
              ),
            ),
            _buildInfoCard(
              title: 'Name',
              value: userProfile?['name'] ?? 'Not set',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Gender',
              value: userProfile?['gender'] ?? 'Not set',
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Age',
              value: userProfile?['age']?.toString() ?? 'Not set',
              icon: Icons.calendar_today_outlined,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.contact_phone,
                    color: AppColors.colors['accent2'],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Contact Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colors['primary'],
                    ),
                  ),
                ],
              ),
            ),
            _buildInfoCard(
              title: 'Phone',
              value: userProfile?['phone'] ?? 'Not set',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Location',
              value: userProfile?['location'] ?? 'Not set',
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isEmpty = value == 'Not set';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => setState(() => isEditing = true),
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.colors['accent2']!.withOpacity(0.1),
        highlightColor: AppColors.colors['accent2']!.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEmpty 
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [
                        AppColors.colors['accent2']!,
                        AppColors.colors['accent1']!,
                      ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isEmpty 
                        ? Colors.grey.withOpacity(0.2)
                        : AppColors.colors['accent2']!.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEmpty 
                          ? Colors.grey[500]
                          : AppColors.colors['primary'],
                        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isEmpty 
                  ? Colors.grey[400]
                  : AppColors.colors['primary']!.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: AppColors.colors['accent2'],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Edit Profile Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.colors['primary'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEditField(
                    title: 'Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hintText: 'Enter your full name',
                  ),
                  _buildEditField(
                    title: 'Gender',
                    controller: _genderController,
                    icon: Icons.people_outline,
                    hintText: 'Enter your gender',
                  ),
                  _buildEditField(
                    title: 'Age',
                    controller: _ageController,
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    hintText: 'Enter your age',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  _buildEditField(
                    title: 'Phone',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    hintText: 'Enter your phone number',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  _buildEditField(
                    title: 'Location',
                    controller: _locationController,
                    icon: Icons.location_on_outlined,
                    hintText: 'Enter your location',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.colors['primary'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colors['accent2'],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $title';
          }
          return null;
        },
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: title,
          hintText: hintText,
          labelStyle: TextStyle(
            color: AppColors.colors['primary']!.withOpacity(0.6),
          ),
          prefixIcon: Icon(icon, color: AppColors.colors['accent2']),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.colors['primary']!.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.colors['accent2']!,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Column(
      children: [
        _buildSkeletonHeader(),
        const SizedBox(height: 24),
        _buildSkeletonSection("Personal Information"),
        ...List.generate(3, (index) => _buildSkeletonCard()),
        const SizedBox(height: 16),
        _buildSkeletonSection("Contact Information"),
        ...List.generate(2, (index) => _buildSkeletonCard()),
      ],
    );
  }

  Widget _buildSkeletonHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 150,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust UI based on screen width
          final bool isTablet = constraints.maxWidth > 600;
          
          return Scaffold(
            appBar: AppBar(
              title: Text(
                "User Profile",
                style: TextStyle(
                  color: AppColors.colors['accent2'],
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              actions: [
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.colors['accent2'],
              onRefresh: _fetchUserProfile,
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  children: [
                    if (isLoading)
                      _buildSkeletonLoading()
                    else ...[
                      _buildProfileHeader(),
                      SizedBox(height: isTablet ? 32.0 : 24.0),
                      if (isEditing)
                        _buildEditForm()
                      else
                        _buildInfoSection(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            floatingActionButton: !isLoading && !isEditing
                ? FloatingActionButton(
                    onPressed: () => setState(() => isEditing = true),
                    backgroundColor: AppColors.colors['accent2'],
                    child: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Edit Profile',
                  )
                : null,
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
                showUnselectedLabels: true,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                onTap: (index) {
                  if (index == _selectedIndex) return;
                  
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
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}