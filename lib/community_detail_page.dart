import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voices_unheard/app_colors.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityId;

  const CommunityDetailPage({Key? key, required this.communityId}) : super(key: key);

  @override
  _CommunityDetailPageState createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> joinRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchJoinRequests();
  }

  Future<void> _fetchJoinRequests() async {
    try {
      final response = await supabase
          .from('join_requests')
          .select()
          .eq('community_id', widget.communityId);

      setState(() {
        joinRequests = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching join requests: ${e.toString()}')),
      );
    }
  }

  

  Future<void> _approveRequest(String userId) async {
    try {
      await supabase.from('community_members').insert({
        'community_id': widget.communityId,
        'user_id': userId,
        'role': 'member',
      });

      await supabase
          .from('join_requests')
          .delete()
          .eq('community_id', widget.communityId)
          .eq('user_id', userId);

      _fetchJoinRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: joinRequests.length,
              itemBuilder: (context, index) {
                final request = joinRequests[index];
                return ListTile(
                  title: Text('User ID: ${request['user_id']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () => _approveRequest(request['user_id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}