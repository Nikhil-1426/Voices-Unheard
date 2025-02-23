import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Create New Community",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.colors['accent2'],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.colors['primary'],
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildTextField(
                  controller: communityNameController,
                  label: "Community Name",
                  hint: "Enter a unique name for your community",
                  icon: Icons.group,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: requisitesController,
                  label: "Requirements",
                  hint: "What are the requirements to join?",
                  icon: Icons.check_circle_outline,
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: "Description",
                  hint: "Describe what your community is about",
                  icon: Icons.description,
                  maxLines: 3,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.colors['primary'],
                          fontSize: 16,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: () {
                          // Implement community creation
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Create",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.colors['primary'],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppColors.colors['accent2']),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                community['name'].toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.colors['accent2'],
                ),
              ),
              SizedBox(height: 4),
              Text(
                community['description']?.toString() ?? "No description available",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.colors['primary'],
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (community['requisites'] != null) ...[
                    Text(
                      "Requirements:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.colors['primary'],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      community['requisites'].toString(),
                      style: TextStyle(
                        color: AppColors.colors['primary'],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.colors['accent2']!,
                          AppColors.colors['accent1']!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _requestToJoin(community['id'].toString()),
                        child: Center(
                          child: Text(
                            "Request to Join",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        //
      ),
      Expanded(
        child: selectedCommunityId == null
            ? _buildCommunityList()
            : _buildChatSection(),
      ),
    ],
  );
}

Widget _buildCommunityList() {
  return Container(
    color: Colors.grey[50],
    child: ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: userCommunities.length,
      itemBuilder: (context, index) {
        final community = userCommunities[index]['communities'];
        final role = userCommunities[index]['role'];
        final isCurrentUserAdmin = role == 'admin';
        final memberCount = community['member_count'] ?? 0; // Assuming you have this field

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  selectedCommunityId = community['id'];
                  isAdmin = isCurrentUserAdmin;
                });
                _fetchCommunityMessages(community['id']);
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.colors['accent2']!.withOpacity(0.1),
                                AppColors.colors['accent1']!.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              community['name'][0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colors['accent2'],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.colors['accent2'],
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: AppColors.colors['primary']?.withOpacity(0.7),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '$memberCount members',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.colors['primary']?.withOpacity(0.7),
                                    ),
                                  ),
                                  if (isCurrentUserAdmin) ...[
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.colors['accent2']?.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.colors['accent2'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.colors['primary']?.withOpacity(0.5),
                        ),
                      ],
                    ),
                    if (community['description'] != null && community['description'].isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(
                        community['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colors['primary'],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.chat_bubble_outline,
                          label: 'Messages',
                          value: community['message_count']?.toString() ?? '0',
                        ),
                        SizedBox(width: 16),
                        _buildStatItem(
                          icon: Icons.calendar_today,
                          label: 'Events',
                          value: community['event_count']?.toString() ?? '0',
                        ),
                        SizedBox(width: 16),
                        _buildStatItem(
                          icon: Icons.volunteer_activism,
                          label: 'Donations',
                          value: community['donation_count']?.toString() ?? '0',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildStatItem({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: AppColors.colors['primary']?.withOpacity(0.7),
      ),
      SizedBox(width: 4),
      Text(
        '$value $label',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.colors['primary']?.withOpacity(0.7),
        ),
      ),
    ],
  );
}
  Widget _buildChatSection() {
  return Column(
    children: [
      AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.colors['accent2']),
          onPressed: () {
            setState(() {
              selectedCommunityId = null;
            });
          },
        ),
        title: Text(
          'Community Chat',
          style: TextStyle(
            color: AppColors.colors['accent2'],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.colors['accent2']),
            onPressed: () {
              // Add chat options menu
            },
          ),
        ],
      ),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
          ),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: communityMessages.length,
            itemBuilder: (context, index) {
              final message = communityMessages[index];
              final isMyMessage = message['user_id'] == userId;
              return _buildMessageBubble(message, isMyMessage);
            },
          ),
        ),
      ),
      _buildMessageInput(),
    ],
  );
}

 Widget _buildMessageBubble(Map<String, dynamic> message, bool isMyMessage) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMyMessage)
          Padding(
            padding: EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              message['users']['email'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.colors['primary']?.withOpacity(0.7),
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.only(
            left: isMyMessage ? 64 : 0,
            right: isMyMessage ? 0 : 64,
          ),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isMyMessage
                      ? LinearGradient(
                          colors: [
                            AppColors.colors['accent2']!,
                            AppColors.colors['accent1']!,
                          ],
                        )
                      : null,
                  color: isMyMessage ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(isMyMessage ? 20 : 4),
                    bottomRight: Radius.circular(isMyMessage ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message['message'],
                  style: TextStyle(
                    color: isMyMessage ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildMessageInput() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined),
                  color: AppColors.colors['primary'],
                  onPressed: () {
                    // Add emoji picker
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: AppColors.colors['primary']?.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.attach_file),
                  color: AppColors.colors['primary'],
                  onPressed: () {
                    // Add attachment options
                  },
                ),
              ],
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
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(14),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

 

Widget _buildFeedTab() {
  return Stack(
    children: [
      Container(
        color: Colors.grey[50],
        child: ListView.builder(
          padding: EdgeInsets.only(
            top: AppStyles.spacing,
            bottom: isAdmin ? 80 : AppStyles.spacing,
            left: AppStyles.spacing,
            right: AppStyles.spacing,
          ),
          itemCount: communityPosts.length,
          itemBuilder: (context, index) => _buildPostCard(communityPosts[index]),
        ),
      ),
      if (isAdmin)
        Positioned(
          bottom: AppStyles.spacing,
          right: AppStyles.spacing,
          child: _buildFloatingActionButton(),
        ),
    ],
  );
}

Widget _buildFloatingActionButton() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.colors['accent2']!,
          AppColors.colors['accent1']!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: AppColors.colors['accent2']!.withOpacity(0.3),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _showPostOptionsDialog,
        child: Padding(
          padding: EdgeInsets.all(AppStyles.spacing),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    ),
  );
}


Widget _buildPostCard(Map<String, dynamic> post) {
  final isEvent = post['type'] == 'event';
  final communityName = post['communities']?['name'] ?? 'Unknown Community';
  final userName = post['users']?['name'] ?? 'Unknown User';
  final userEmail = post['users']?['email'] ?? 'No Email';

  return Card(
    margin: EdgeInsets.all(AppStyles.smallSpacing),
    elevation: AppStyles.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPostHeader(post, communityName, userName, userEmail),
        _buildPostContent(post),
        if (isEvent)
          _buildEventDetails(post)
        else
          _buildDonationDetails(post),
        _buildActionBar(),
      ],
    ),
  );
}

Widget _buildPostHeader(
  Map<String, dynamic> post,
  String communityName,
  String userName,
  String userEmail,
) {
  return Padding(
    padding: EdgeInsets.all(AppStyles.spacing),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.colors['accent2']!.withOpacity(0.1),
          child: Text(
            userName[0].toUpperCase(),
            style: TextStyle(color: AppColors.colors['accent2']),
          ),
        ),
        SizedBox(width: AppStyles.spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['title'] ?? 'No Title', style: AppStyles.titleStyle),
              SizedBox(height: AppStyles.smallSpacing / 2),
              Text(
                '$communityName • $userName',
                style: AppStyles.subtitleStyle,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppStyles.smallSpacing,
            vertical: AppStyles.smallSpacing / 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.colors['accent2']!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.borderRadius / 2),
          ),
          child: Text(
            post['type'].toUpperCase(),
            style: TextStyle(
              color: AppColors.colors['accent2'],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPostContent(Map<String, dynamic> post) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppStyles.spacing),
    child: Text(
      post['content'] ?? 'No Content',
      style: AppStyles.bodyStyle,
    ),
  );
}

Widget _buildEventDetails(Map<String, dynamic> post) {
  return Padding(
    padding: EdgeInsets.all(AppStyles.spacing),
    child: Column(
      children: [
        _buildDetailRow(
          Icons.location_on,
          post['venue'] ?? 'No Venue',
          AppColors.colors['accent1']!,
        ),
        SizedBox(height: AppStyles.smallSpacing),
        _buildDetailRow(
          Icons.calendar_today,
          post['event_date'] != null
              ? DateFormat('MMM d, y • h:mm a')
                  .format(DateTime.parse(post['event_date']))
              : 'No Date',
          AppColors.colors['accent2']!,
        ),
      ],
    ),
  );
}

Widget _buildDonationDetails(Map<String, dynamic> post) {
  return Padding(
    padding: EdgeInsets.all(AppStyles.spacing),
    child: Row(
      children: [
        Expanded(
          child: _buildDetailRow(
            Icons.monetization_on,
            'Goal: \$${post['donation_goal'] ?? 0}',
            AppColors.colors['accent1']!,
          ),
        ),
        ElevatedButton(
          onPressed: () => _showDonationDialog(post),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colors['accent2'],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppStyles.spacing,
              vertical: AppStyles.smallSpacing,
            ),
          ),
          child: Text(
            'Donate Now',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(IconData icon, String text, Color color) {
  return Row(
    children: [
      Icon(icon, color: color, size: 20),
      SizedBox(width: AppStyles.smallSpacing),
      Expanded(
        child: Text(
          text,
          style: AppStyles.bodyStyle.copyWith(color: Colors.grey[800]),
        ),
      ),
    ],
  );
}

Widget _buildActionBar() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppStyles.smallSpacing),
    child: Row(
      children: [
        _buildActionButton(Icons.thumb_up_outlined, 'Like'),
        _buildActionButton(Icons.comment_outlined, 'Comment'),
        _buildActionButton(Icons.share, 'Share'),
      ],
    ),
  );
}

Widget _buildActionButton(IconData icon, String label) {
  return Expanded(
    child: TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20, color: Colors.grey[700]),
      label: Text(
        label,
        style: TextStyle(color: Colors.grey[700], fontSize: 14),
      ),
    ),
  );
}

  void _showPostOptionsDialog() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: EdgeInsets.all(AppStyles.largeSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyles.borderRadius * 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppStyles.largeSpacing),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildOptionButton(
            icon: Icons.event,
            title: 'Create Event',
            onTap: () {
              Navigator.pop(context);
              _showEventDialog();
            },
          ),
          SizedBox(height: AppStyles.smallSpacing),
          _buildOptionButton(
            icon: Icons.monetization_on,
            title: 'Start Donation Drive',
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

Widget _buildOptionButton({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppStyles.spacing,
          horizontal: AppStyles.largeSpacing,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.colors['accent2']),
            SizedBox(width: AppStyles.spacing),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.colors['primary'],
              ),
            ),
          ],
        ),
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

class AppStyles {
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
    height: 1.2,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    height: 1.5,
  );
}