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
  TextEditingController communityNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController requisitesController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  TextEditingController eventTitleController = TextEditingController();
  TextEditingController eventDescriptionController = TextEditingController();
  TextEditingController eventVenueController = TextEditingController();
  TextEditingController donationTitleController = TextEditingController();
  TextEditingController donationDescriptionController = TextEditingController();
  TextEditingController donationGoalController = TextEditingController();
  
  List<Map<String, dynamic>> communities = [];
  List<Map<String, dynamic>> userCommunities = [];
  List<Map<String, dynamic>> communityPosts = [];
  List<Map<String, dynamic>> communityMessages = [];
  String userId = '';
  int _selectedIndex = 1;
  int _selectedTabIndex = 0;
  String? selectedCommunityId;
  bool isAdmin = false;
  
  late TabController _tabController;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    userId = supabase.auth.currentUser?.id ?? '';
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _tabController.addListener(_handleTabChange);
    _controller.forward();
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();  
    _controller.dispose();
    communityNameController.dispose();
    descriptionController.dispose();
    requisitesController.dispose();
    messageController.dispose();
    eventTitleController.dispose();
    eventDescriptionController.dispose();
    eventVenueController.dispose();
    donationTitleController.dispose();
    donationDescriptionController.dispose();
    donationGoalController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _loadTabData(_tabController.index);
    }
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchCommunities(),
      _fetchUserCommunities(),
      _fetchCommunityPosts(),
    ]);
  }

  Future<void> _loadTabData(int index) async {
    switch (index) {
      case 0:
        await _fetchCommunities();
        break;
      case 1:
        await _fetchUserCommunities();
        if (selectedCommunityId != null) {
          await _fetchCommunityMessages(selectedCommunityId!);
        }
        break;
      case 2:
        await _fetchCommunityPosts();
        break;
    }
  }

  Future<void> _fetchUserCommunities() async {
    try {
      final response = await supabase
          .from('community_members')
          .select('community_id, role, communities(*)')
          .eq('user_id', userId);
      setState(() {
        userCommunities = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackBar('Error fetching your communities: ${e.toString()}');
    }
  }

  Future<void> _fetchCommunityMessages(String communityId) async {
    try {
      final response = await supabase
          .from('community_messages')
          .select(', auth.users!inner()')
          .eq('community_id', communityId)
          .order('sent_at', ascending: true);
      setState(() {
        communityMessages = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackBar('Error fetching messages: ${e.toString()}');
    }
  }

  Future<void> _fetchCommunityPosts() async {
  try {
    // 1. Fetch basic community_posts data
    final postsResponse = await supabase
        .from('community_posts')
        .select('id, community_id, admin_id, type, title, content, event_date, venue, donation_goal, created_at')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> fetchedPosts = List<Map<String, dynamic>>.from(postsResponse);

    // 2. Fetch related data (communities and users)
    for (var post in fetchedPosts) {
      // Fetch community data
      final communityResponse = await supabase
          .from('communities')
          .select('*')
          .eq('id', post['community_id'])
          .maybeSingle();

      post['communities'] = communityResponse;

      // Fetch user data
      final userResponse = await supabase
          .from('profiles')
          .select('*')
          .eq('id', post['admin_id'])
          .maybeSingle();

      post['users'] = userResponse;
    }

    setState(() {
      communityPosts = fetchedPosts;
    });
  } catch (e) {
    _showSnackBar('Error fetching posts: ${e.toString()}');
    print('Error fetching posts: ${e.toString()}');
  }
}

  Future<void> _sendMessage() async {
    if (messageController.text.isEmpty || selectedCommunityId == null) return;

    try {
      await supabase.from('community_messages').insert({
        'community_id': selectedCommunityId,
        'user_id': userId,
        'message': messageController.text,
      });

      messageController.clear();
      await _fetchCommunityMessages(selectedCommunityId!);
    } catch (e) {
      _showSnackBar('Error sending message: ${e.toString()}');
    }
  }

  Future<void> _createEvent() async {
    if (selectedCommunityId == null) return;

    try {
      await supabase.from('community_posts').insert({
        'community_id': selectedCommunityId,
        'admin_id': userId,
        'type': 'event',
        'title': eventTitleController.text,
        'content': eventDescriptionController.text,
        'venue': eventVenueController.text,
        'event_date': DateTime.now().toIso8601String(), // Add date picker in UI
      });

      _clearEventControllers();
      await _fetchCommunityPosts();
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error creating event: ${e.toString()}');
    }
  }

  Future<void> _createDonationDrive() async {
    if (selectedCommunityId == null) return;

    try {
      await supabase.from('community_posts').insert({
        'community_id': selectedCommunityId,
        'admin_id': userId,
        'type': 'donation',
        'title': donationTitleController.text,
        'content': donationDescriptionController.text,
        'donation_goal': double.parse(donationGoalController.text),
      });

      _clearDonationControllers();
      await _fetchCommunityPosts();
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error creating donation drive: ${e.toString()}');
    }
  }

  void _clearEventControllers() {
    eventTitleController.clear();
    eventDescriptionController.clear();
    eventVenueController.clear();
  }

  void _clearDonationControllers() {
    donationTitleController.clear();
    donationDescriptionController.clear();
    donationGoalController.clear();
  }

  Future<void> _fetchCommunities() async {
    try {
      final response = await supabase
          .from('communities')
          .select()
          .order('created_at', ascending: false);
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.colors['accent2'],
      ),
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

  Widget _buildWelcomeSection() {
    return Padding(
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
              width: double.infinity,
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
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
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
            community['name'].toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.colors['accent2'],
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            community['description']?.toString() ?? "No description available",
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
  }

  Widget _buildJoinCreateTab() {
    return RefreshIndicator(
      onRefresh: _fetchCommunities,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildWelcomeSection(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCommunityCard(communities[index]),
              childCount: communities.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: selectedCommunityId == null
              ? _buildCommunityList()
              : _buildChatSection(),
        ),
      ],
    );
  }

  Widget _buildCommunityList() {
    return ListView.builder(
      itemCount: userCommunities.length,
      itemBuilder: (context, index) {
        final community = userCommunities[index]['communities'];
        return ListTile(
          title: Text(community['name']),
          subtitle: Text(community['description'] ?? ''),
          onTap: () {
            setState(() {
              selectedCommunityId = community['id'];
              isAdmin = userCommunities[index]['role'] == 'admin';
            });
            _fetchCommunityMessages(community['id']);
          },
        );
      },
    );
  }

  Widget _buildChatSection() {
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                selectedCommunityId = null;
              });
            },
          ),
          title: Text('Community Chat'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: communityMessages.length,
            itemBuilder: (context, index) {
              final message = communityMessages[index];
              final isMyMessage = message['user_id'] == userId;
              return _buildMessageBubble(message, isMyMessage);
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMyMessage) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMyMessage ? AppColors.colors['accent2'] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMessage)
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
                color: isMyMessage ? Colors.white : Colors.black,
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
              controller: messageController,
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
            onPressed: _sendMessage,
            color: AppColors.colors['accent2'],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return Stack(
      children: [
        ListView.builder(
          itemCount: communityPosts.length,
          itemBuilder: (context, index) => _buildPostCard(communityPosts[index]),
        ),
        if (isAdmin)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showPostOptionsDialog,
              child: Icon(Icons.add),
              backgroundColor: AppColors.colors['accent2'],
            ),
          ),
      ],
    );
  }

 Widget _buildPostCard(Map<String, dynamic> post) {
  final isEvent = post['type'] == 'event';
  final communityName = post['communities']?['name'] ?? 'Unknown Community';
  final userName = post['users']?['name'] ?? 'Unknown User'; // Assuming 'name' exists in profiles
  final userEmail = post['users']?['email'] ?? 'No Email'; // Assuming 'email' exists in profiles

  return Card(
    margin: EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(post['title'] ?? 'No Title'),
          subtitle: Text('$communityName - $userName ($userEmail)'),
          trailing: Text(post['type'].toUpperCase()),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(post['content'] ?? 'No Content'),
        ),
        if (isEvent) ...[
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text(post['venue'] ?? 'No Venue'),
            subtitle: Text(post['event_date'] != null ? DateTime.parse(post['event_date']).toString() : 'No Date'),
          ),
        ] else ...[
          ListTile(
            leading: Icon(Icons.monetization_on),
            title: Text('Goal: \$${post['donation_goal'] ?? 0}'),
            trailing: ElevatedButton(
              onPressed: () => _showDonationDialog(post),
              child: Text('Donate Now'),
            ),
          ),
        ],
        ButtonBar(
          children: [
            IconButton(
              icon: Icon(Icons.thumb_up_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.comment_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
  );
}

  void _showPostOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.event),
              title: Text('Post an Event'),
              onTap: () {
                Navigator.pop(context);
                _showEventDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.monetization_on),
              title: Text('Start a Donation Drive'),
              onTap: () {
                Navigator.pop(context);
                _showDonationDriveDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventTitleController,
                decoration: InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                controller: eventDescriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: eventVenueController,
                decoration: InputDecoration(labelText: 'Venue'),
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
            onPressed: _createEvent,
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDonationDriveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Donation Drive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: donationTitleController,
                decoration: InputDecoration(labelText: 'Donation Title'),
              ),
              TextField(
                controller: donationDescriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: donationGoalController,
                decoration: InputDecoration(labelText: 'Goal Amount (\$)'),
                keyboardType: TextInputType.number,
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
            onPressed: _createDonationDrive,
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDonationDialog(Map<String, dynamic> post) {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Make a Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Donation for: ${post['title']}'),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount (\$)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement Razorpay integration
              // For now, just store the donation
              try {
                await supabase.from('donations').insert({
                  'community_post_id': post['id'],
                  'user_id': userId,
                  'amount': double.parse(amountController.text),
                  'transaction_id': 'dummy_transaction_${DateTime.now().millisecondsSinceEpoch}',
                });
                Navigator.pop(context);
                _showSnackBar('Donation recorded successfully!');
              } catch (e) {
                _showSnackBar('Error recording donation: ${e.toString()}');
              }
            },
            child: Text('Donate'),
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
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Join/Create'),
              Tab(text: 'Chat'),
              Tab(text: 'Feed'),
            ],
            labelColor: AppColors.colors['accent2'],
            unselectedLabelColor: AppColors.colors['primary'],
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