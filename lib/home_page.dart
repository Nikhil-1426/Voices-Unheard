import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'education_page.dart';
import 'community_page.dart';
import 'product_page.dart';
import 'settings_page.dart';
import 'package:voices_unheard/app_colors.dart';
// Matching color palette from auth page


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController postController = TextEditingController();
  
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredPosts = [];
  List<Map<String, dynamic>> posts = [];
  
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final List<dynamic> response = await supabase
          .from('posts')
          .select()
          .order('timestamp', ascending: false);

      setState(() {
        posts = response.map((post) => Map<String, dynamic>.from(post)).toList();
        filteredPosts = posts; // Initially, filtered posts = all posts
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading posts: ${e.toString()}'),
          backgroundColor: AppColors.colors['error'],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  void _filterPosts(String query) {
  setState(() {
    if (query.isEmpty) {
      filteredPosts = posts;
    } else {
      filteredPosts = posts.where((post) {
        final content = post['content']?.toString().toLowerCase() ?? '';
        final userId = post['user_id']?.toString().toLowerCase() ?? '';
        return content.contains(query.toLowerCase()) ||
            userId.contains(query.toLowerCase());
      }).toList();
    }
  });
}
   void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EducationPage()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _createPost() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.colors['background'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Share Your Voice",
            style: TextStyle(
              color: AppColors.colors['accent2'],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
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
              controller: postController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                onPressed: () async {
                  if (postController.text.isNotEmpty) {
                    final userId = supabase.auth.currentUser?.id;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please log in first.'),
                          backgroundColor: AppColors.colors['error'],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    await supabase.from('posts').insert({
                      'user_id': userId,
                      'content': postController.text,
                      'timestamp': DateTime.now().toIso8601String(),
                      'likes': 0,
                    });

                    postController.clear();
                    Navigator.of(context).pop();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Your voice has been shared!'),
                        backgroundColor: AppColors.colors['accent3'],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    
                    await _fetchPosts();
                  }
                },
                child: Text(
                  "Share",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Like a post
  Future<void> _likePost(int postId, int currentLikes) async {
    await supabase.from('posts').update({'likes': currentLikes + 1}).match({'id': postId});
    _fetchPosts();
  }

  /// Share a post
  void _sharePost(String content) {
    Share.share(content);
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
          "Voices Unheard",
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
        onRefresh: _fetchPosts,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.colors['accent2']!.withOpacity(0.1),
                            AppColors.colors['accent1']!.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: _filterPosts,
                        decoration: InputDecoration(
                          hintText: "Search stories...",
                          prefixIcon: Icon(Icons.search, color: AppColors.colors['accent2']),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.colors['accent2']!,
                          AppColors.colors['accent1']!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.colors['accent2']!.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: _createPost,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredPosts.isEmpty && searchController.text.isNotEmpty
                  ? Center(
                      child: Text("No results found"),
                    )
                  : posts.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.colors['accent2']!,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchController.text.isEmpty
                              ? posts.length
                              : filteredPosts.length,
                          padding: EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final post = searchController.text.isEmpty
                                ? posts[index]
                                : filteredPosts[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.colors['accent2'],
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),
                                    title: Text(
                                      post['user_id'] ?? "Anonymous",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      "Shared a story",
                                      style: TextStyle(color: AppColors.colors['primary']),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      post['content'] ?? "",
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.favorite_border,
                                          label: "${post['likes'] ?? 0}",
                                          onPressed: () => _likePost(
                                            post['id'],
                                            post['likes'] ?? 0,
                                          ),
                                        ),
                                        _buildActionButton(
                                          icon: Icons.comment_outlined,
                                          label: "Comment",
                                          onPressed: () {},
                                        ),
                                        _buildActionButton(
                                          icon: Icons.share_outlined,
                                          label: "Share",
                                          onPressed: () => _sharePost(post['content']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(
        icon,
        size: 20,
        color: AppColors.colors['accent2'],
      ),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.colors['primary'],
        ),
      ),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}