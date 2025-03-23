// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'education_page.dart';
import 'community_page.dart';
import 'product_page.dart';
import 'settings_page.dart';
import 'package:voices_unheard/app_colors.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController postController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredPosts = [];
  List<Map<String, dynamic>> posts = [];
  String? _imageUrl;

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
          .select('id, user_id, user_name, content, timestamp, likes, image_url')
          .order('timestamp', ascending: false);

      if (mounted) {
        setState(() {
          posts = response.map((post) {
            return Map<String, dynamic>.from(post);
          }).toList();
          filteredPosts = posts;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading posts: ${e.toString()}'),
          backgroundColor: AppColors.colors['error'],
        ),
      );
    }
  }

  Future<void> _addComment(int postId, String commentText) async {
    if (commentText.isEmpty) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to comment.'),
            backgroundColor: AppColors.colors['error'],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final userProfile = await supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();

      final userName = userProfile['name'] ?? 'Anonymous';

      await supabase.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'user_name': userName,
        'comment': commentText,
        'image_url': _imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added!'),
          backgroundColor: AppColors.colors['accent3'],
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: ${e.toString()}'),
          backgroundColor: AppColors.colors['error'],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addImageUrl() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Image URL"),
          content: TextField(
            controller: imageUrlController,
            decoration: InputDecoration(
              hintText: "Enter image URL...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _imageUrl = imageUrlController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Image URL added! Ready to post.'),
                    backgroundColor: AppColors.colors['accent3'],
                  ),
                );
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    try {
      DateTime postTime = DateTime.parse(timestamp).toLocal();
      Duration difference = DateTime.now().difference(postTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y HH:mm').format(postTime);
      }
    } catch (e) {
      return 'Invalid date';
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

  void _showCommentDialog(int postId) {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add a Comment"),
          content: TextField(
            controller: commentController,
            decoration: InputDecoration(hintText: "Write a comment..."),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Post"),
              onPressed: () {
                _addComment(postId, commentController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
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
            IconButton(
              icon: Icon(Icons.image, color: AppColors.colors['accent2']),
              onPressed: _addImageUrl,
            ),
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

                    final userProfile = await supabase
                        .from('profiles')
                        .select('name')
                        .eq('id', userId)
                        .single();

                    final userName = userProfile['name'] ?? 'Anonymous';

                    await supabase.from('posts').insert({
                      'user_id': userId,
                      'user_name': userName,
                      'content': postController.text,
                      'image_url': _imageUrl,
                      'timestamp': DateTime.now().toIso8601String(),
                      'likes': 0,
                    });

                    postController.clear();
                    imageUrlController.clear();
                    _imageUrl = null;
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

  Future<void> _likePost(int postId, int currentLikes) async {
    await supabase.from('posts').update({'likes': currentLikes + 1}).match({'id': postId});
    _fetchPosts();
  }

  void _sharePost(Map<String, dynamic> post) async {
  final String userName = post['user_name'] ?? 'Anonymous';
  final String content = post['content'] ?? '';
  final String timestamp = _formatTimestamp(post['timestamp']);
  
  // Create a formatted share text
  final String shareText = '''
From $userName on Voices Unheard
Posted $timestamp

$content

#VoicesUnheard
''';

  try {
    // If there's an image, share both text and image
    if (post['image_url'] != null) {
      await Share.share(
        shareText,
        subject: 'Check out this post from Voices Unheard',
      );
      // Note: share_plus doesn't support sharing both text and image in a single share action
      // If you need this functionality, you'll need to use platform-specific implementations
    } else {
      // Share just the text
      await Share.share(
        shareText,
        subject: 'Check out this post from Voices Unheard',
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to share post: ${e.toString()}'),
        backgroundColor: AppColors.colors['error'],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
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
                              itemCount: searchController.text.isEmpty ? posts.length : filteredPosts.length,
                              padding: EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final post = searchController.text.isEmpty ? posts[index] : filteredPosts[index];
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
                                          post['user_name'] ?? "Anonymous",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          _formatTimestamp(post['timestamp']),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Text(
                                          post['content'] ?? "",
                                          style: TextStyle(fontSize: 16, height: 1.4),
                                        ),
                                      ),
                                      if (post['image_url'] != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              post['image_url'].toString(),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 200,
                                                  color: Colors.grey[300],
                                                  child: Center(
                                                    child: Text('Failed to load image'),
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  height: 200,
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      if (post['comments'] != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: (post['comments'] as List<dynamic>).map<Widget>((comment) {
                                              return Padding(
                                                padding: EdgeInsets.only(top: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.comment, size: 16, color: Colors.grey),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        "${comment['user_name']}: ${comment['comment']}",
                                                        style: TextStyle(fontSize: 14, color: Colors.black87),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
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
                                              onPressed: () => _likePost(post['id'], post['likes'] ?? 0),
                                            ),
                                            _buildActionButton(
                                              icon: Icons.comment_outlined,
                                              label: "Comment",
                                              onPressed: () => _showCommentDialog(post['id']),
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
