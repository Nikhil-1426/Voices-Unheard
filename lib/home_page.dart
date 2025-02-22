import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController postController = TextEditingController();
  List<Map<String, dynamic>> posts = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  /// Fetch all posts from Supabase
  Future<void> _fetchPosts() async {
    try {
      final List<dynamic> response = await supabase
          .from('posts')
          .select()
          .order('timestamp', ascending: false);

      debugPrint('Fetched posts: $response');

      setState(() {
        posts = response.map((post) => Map<String, dynamic>.from(post)).toList();
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  /// Create a new post and save it in Supabase
  void _createPost() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Share a Thought"),
          content: TextField(
            controller: postController,
            decoration: const InputDecoration(hintText: "What's on your mind?"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (postController.text.isNotEmpty) {
                  final userId = supabase.auth.currentUser?.id;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in first.')),
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

                  /// ✅ Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post created successfully!')),
                  );

                  /// ✅ Refresh posts
                  await _fetchPosts();
                }
              },
              child: const Text("Post"),
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voices Unheard"), backgroundColor: Colors.deepPurple),
      body: RefreshIndicator(
        onRefresh: _fetchPosts, // ✅ Pull-to-refresh
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(onPressed: () {}, child: const Text("Search")),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _createPost, child: const Text("Create a Post")),
                ],
              ),
            ),
            Expanded(
              child: posts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 20,
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(post['user_id'] ?? "Unknown User", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Text("Just now", style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(post['content'] ?? "No content", style: const TextStyle(fontSize: 16.0)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.thumb_up_alt_outlined),
                                      onPressed: () => _likePost(post['id'], post['likes'] ?? 0),
                                    ),
                                    IconButton(icon: const Icon(Icons.comment_outlined), onPressed: () {}),
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Product'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_sharp), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.house_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'Education'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
