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

class _CommunitiesPageState extends State<CommunityPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController communityNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController requisitesController = TextEditingController();
  List<Map<String, dynamic>> communities = [];
  String? userId;
  int _selectedIndex = 1; // Set the index for the Community page

  @override
  void initState() {
    super.initState();
    userId = supabase.auth.currentUser?.id;
    _fetchCommunities();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        backgroundColor: AppColors.colors['primary'],
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: communityNameController,
                  decoration: InputDecoration(
                    labelText: "Community Name",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.colors['primary']!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: requisitesController,
                  decoration: InputDecoration(
                    labelText: "Requisites (Optional)",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.colors['primary']!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description (Optional)",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.colors['primary']!),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colors['accent2'],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  onPressed: _createCommunity,
                  child: const Text("Create Community", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCommunities,
            child: ListView.builder(
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      community['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("Admin: ${community['admin_id']}"),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.colors['primary'],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _requestToJoin(community['id'].toString()),
                      child: const Text("Request to Join", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
          ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.colors['accent2'],
        unselectedItemColor: AppColors.colors['primary'],
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
 
