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

class _CommunitiesPageState extends State<CommunityPage> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late TabController _tabController;
  int _currentTab = 0;
  int _selectedIndex = 1;
  String userId='';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Controllers for creating community
  TextEditingController communityNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController requisitesController = TextEditingController();

  // Controllers for posts
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  TextEditingController venueController = TextEditingController();
  TextEditingController donationGoalController = TextEditingController();
  DateTime? selectedEventDate;

  // Data lists
  List<Map<String, dynamic>> communities = [];
  List<Map<String, dynamic>> joinedCommunities = [];
  List<Map<String, dynamic>> communityPosts = [];
  List<Map<String, dynamic>> communityMessages = [];

  @override
  void initState() {
    super.initState();
    // Fix the nullable User issue
    userId = supabase.auth.currentUser?.id ?? '';
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTab = _tabController.index);
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchCommunities(),
      _fetchJoinedCommunities(),
      _fetchCommunityPosts(),
    ]);
  }

  Future<void> _fetchCommunities() async {
    try {
      final response = await supabase.from('communities').select();
      setState(() => communities = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Error fetching communities: ${e.toString()}');
    }
  }

  Future<void> _fetchJoinedCommunities() async {
    try {
      final response = await supabase
          .from('community_members')
          .select('*, communities(*)')
          .eq('user_id', userId);
      setState(() => joinedCommunities = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Error fetching joined communities: ${e.toString()}');
    }
  }

  Future<void> _fetchCommunityPosts() async {
    try {
      final response = await supabase
          .from('community_posts')
          .select('*, communities(*), auth.users(*)')
          .order('created_at', ascending: false);
      setState(() => communityPosts = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Error fetching posts: ${e.toString()}');
    }
  }

  Future<void> _createCommunity() async {
    if (communityNameController.text.isEmpty) return;

    try {
      final response = await supabase.from('communities').insert({
        'name': communityNameController.text,
        'description': descriptionController.text,
        'admin_id': userId,
        'requisites': requisitesController.text,
      }).select('id');

      final communityId = response.first['id'];

      await supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': 'admin',
      });

      _showSnackBar('Community created successfully!');
      _clearCreateCommunityFields();
      _fetchInitialData();
    } catch (e) {
      _showSnackBar('Error creating community: ${e.toString()}');
    }
  }

  Future<void> _requestToJoin(String communityId) async {
    try {
      // Check if already a member
      final existingMember = await supabase
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .single();

      if (existingMember != null) {
        _showSnackBar('You are already a member of this community');
        return;
      }

      // Check for existing request
      final existingRequest = await supabase
          .from('join_requests')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .single();

      if (existingRequest != null) {
        _showSnackBar('You have already requested to join this community');
        return;
      }

      await supabase.from('join_requests').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': 'member',
      });

      _showSnackBar('Request sent to admin!');
    } catch (e) {
      _showSnackBar('Error sending request: ${e.toString()}');
    }
  }

  Future<void> _createPost(String communityId, String type) async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    try {
      final postData = {
        'community_id': communityId,
        'admin_id': userId,
        'type': type,
        'title': titleController.text,
        'content': contentController.text,
        if (type == 'event') ...{
          'event_date': selectedEventDate?.toIso8601String(),
          'venue': venueController.text,
        },
        if (type == 'donation') 
          'donation_goal': double.tryParse(donationGoalController.text) ?? 0,
      };

      await supabase.from('community_posts').insert(postData);
      _showSnackBar('Post created successfully!');
      _clearPostFields();
      _fetchCommunityPosts();
    } catch (e) {
      _showSnackBar('Error creating post: ${e.toString()}');
    }
  }

  Future<void> _sendMessage(String communityId, String message) async {
    try {
      await supabase.from('community_messages').insert({
        'community_id': communityId,
        'user_id': userId,
        'message': message,
      });
      _fetchMessages(communityId);
    } catch (e) {
      _showSnackBar('Error sending message: ${e.toString()}');
    }
  }

  Future<void> _fetchMessages(String communityId) async {
    try {
      final response = await supabase
          .from('community_messages')
          .select('*, auth.users(*)')
          .eq('community_id', communityId)
          .order('sent_at', ascending: true);
      setState(() => communityMessages = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackBar('Error fetching messages: ${e.toString()}');
    }
  }

  Future<void> _processDonation(String postId, double amount) async {
    try {
      // Dummy Razorpay integration
      await Future.delayed(Duration(seconds: 1));
      
      await supabase.from('donations').insert({
        'community_post_id': postId,
        'user_id': userId,
        'amount': amount,
        'transaction_id': 'dummy_${DateTime.now().millisecondsSinceEpoch}',
      });

      _showSnackBar('Donation processed successfully!');
      _fetchCommunityPosts();
    } catch (e) {
      _showSnackBar('Error processing donation: ${e.toString()}');
    }
  }

  // UI Helper Methods
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearCreateCommunityFields() {
    communityNameController.clear();
    descriptionController.clear();
    requisitesController.clear();
  }

  void _clearPostFields() {
    titleController.clear();
    contentController.clear();
    venueController.clear();
    donationGoalController.clear();
    selectedEventDate = null;
  }

  // UI Building Methods
  Widget _buildJoinCreateTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(),
        SizedBox(height: 16),
        _buildCommunitiesList(),
      ],
    );
  }

  void _showEventPostForm(String communityId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Create Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Event Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Event Date'),
                  subtitle: Text(selectedEventDate?.toString() ?? 'Not selected'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedEventDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _createPost(communityId, 'event');
                Navigator.pop(context);
              },
              child: Text('Create Event'),
            ),
          ],
        ),
      );
    }

    void _showDonationPostForm(String communityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Donation Drive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Campaign Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Campaign Description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: donationGoalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Donation Goal (\$)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _createPost(communityId, 'donation');
              Navigator.pop(context);
            },
            child: Text('Create Campaign'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
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
          _buildCreateCommunityButton(),
        ],
      ),
    );
  }

  Widget _buildCreateCommunityButton() {
    return Container(
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
        onPressed: () => _showCreateCommunityDialog(),
      ),
    );
  }

  Widget _buildCommunitiesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return _buildCommunityCard(community);
      },
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        title: Text(
          community['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.colors['accent2'],
          ),
        ),
        subtitle: Text(
          community['description'] ?? 'No description available',
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
                    style: TextStyle(color: AppColors.colors['primary']),
                  ),
                SizedBox(height: 16),
                _buildJoinButton(community['id']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(String communityId) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colors['accent2']!,
            AppColors.colors['accent1']!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: () => _requestToJoin(communityId),
        child: Text(
          "Request to Join",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

  Widget _buildChatTab() {
    return ListView.builder(
      itemCount: joinedCommunities.length,
      itemBuilder: (context, index) {
        final community = joinedCommunities[index]['communities'];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.colors['accent2'],
            child: Text(
              community['name'][0].toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
          title: Text(community['name']),
          subtitle: Text(community['description'] ?? 'No description'),
          onTap: () => _showChatRoom(community),
        );
      },
    );
  }

  void _showChatRoom(Map<String, dynamic> community) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ChatRoom(
        community: community,
        userId: userId!,
        onSendMessage: _sendMessage,
        messages: communityMessages,
        onFetchMessages: () => _fetchMessages(community['id']),
      ),
    );
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

  Widget _buildFeedTab() {
    return ListView.builder(
      itemCount: communityPosts.length,
      itemBuilder: (context, index) {
        final post = communityPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isEvent = post['type'] == 'event';
    final isDonation = post['type'] == 'donation';
    final isAdmin = post['admin_id'] == userId;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              post['title'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.colors['accent2'],
              ),
            ),
            subtitle: Text(
              'Posted in ${post['communities']['name']}',
              style: TextStyle(color: AppColors.colors['primary']),
            ),
            trailing: Text(
              DateTime.parse(post['created_at']).toString().split('.')[0],
              style: TextStyle(
                color: AppColors.colors['primary'],
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(post['content']),
          ),
          if (isEvent) _buildEventDetails(post),
          if (isDonation) _buildDonationDetails(post),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.thumb_up, 'Like'),
                _buildActionButton(Icons.comment, 'Comment'),
                _buildActionButton(Icons.share, 'Share'),
                if (isDonation)
                  _buildDonateButton(post),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(Map<String, dynamic> post) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, 
                   color: AppColors.colors['accent2'],
                   size: 16),
              SizedBox(width: 8),
              Text(
                'Date: ${DateTime.parse(post['event_date']).toString().split('.')[0]}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on,
                   color: AppColors.colors['accent2'],
                   size: 16),
              SizedBox(width: 8),
              Text(
                'Venue: ${post['venue']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationDetails(Map<String, dynamic> post) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on,
                   color: AppColors.colors['accent2'],
                   size: 16),
              SizedBox(width: 8),
              Text(
                'Goal: \$${post['donation_goal']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Add progress bar here if tracking donations
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.colors['primary']),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: AppColors.colors['primary'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDonateButton(Map<String, dynamic> post) {
    return ElevatedButton(
      onPressed: () => _showDonationDialog(post),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.colors['accent2'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text('Donate Now'),
    );
  }

  void _showDonationDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) {
        final amountController = TextEditingController();
        return AlertDialog(
          title: Text('Make a Donation'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (\$)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  _processDonation(post['id'], amount);
                  Navigator.pop(context);
                }
              },
              child: Text('Donate'),
            ),
          ],
        );
      },
    );
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

  void _showCreatePostDialog(String communityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _showEventPostForm(communityId),
              child: Text('Post an Event'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showDonationPostForm(communityId),
              child: Text('Start a Donation Drive'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Communities",
            style: TextStyle(
              color: AppColors.colors['accent2'],
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Join/Create'),
              Tab(text: 'Chat'),
              Tab(text: 'Feed'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildJoinCreateTab(),
            _buildChatTab(),
            _buildFeedTab(),
          ],
        ),
        floatingActionButton: _currentTab == 2 && communities.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreatePostDialog(communities.first['id']),
              child: Icon(Icons.add),
              backgroundColor: AppColors.colors['accent2'],
            )
          : null,
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// Chat room widget for the messaging feature
class _ChatRoom extends StatefulWidget {
  final Map<String, dynamic> community;
  final String userId;
  final Function(String, String) onSendMessage;
  final List<Map<String, dynamic>> messages;
  final Function() onFetchMessages;

  const _ChatRoom({
    required this.community,
    required this.userId,
    required this.onSendMessage,
    required this.messages,
    required this.onFetchMessages,
  });

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<_ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.onFetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          AppBar(
            title: Text(widget.community['name']),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                final isMe = message['user_id'] == widget.userId;
                return _buildMessageBubble(message, isMe);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.colors['accent2'] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message['users']['email'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            Text(
              message['message'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                widget.onSendMessage(
                  widget.community['id'],
                  _messageController.text,
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}