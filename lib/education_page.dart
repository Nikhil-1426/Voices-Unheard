import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_colors.dart';
import 'community_page.dart';
import 'home_page.dart';
import 'product_page.dart';
import 'settings_page.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  _EducationPageState createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  List<Map<String, dynamic>> resources = [];
  bool isLoading = true;
  final int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    fetchEducationResources();
  }

  Future<void> fetchEducationResources() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.188.60:5000/fetch_resources"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("error")) {
          print("API Error: ${data['error']}");
        } else {
          setState(() {
            resources = [
              {
                'title': 'Scholarship & Grants',
                'icon': Icons.school,
                'color': AppColors.colors['accent2'],
                'bgColor': AppColors.colors['cardBg2'] ?? Color(0xFFD1D1F7),
                'description': 'Find financial aid opportunities tailored for you',
                'count': '${data["Scholarship & Grants"]?.length ?? 50}+ opportunities',
                'details': data["Scholarship & Grants"] ?? [],
              },
              {
                'title': 'Career Opportunities',
                'icon': Icons.work,
                'color': AppColors.colors['accent1'],
                'bgColor': AppColors.colors['cardBg1'] ?? Color(0xFFD1F7E0),
                'description': 'Explore jobs and internships in your field',
                'count': '${data["Career Opportunities"]?.length ?? 100}+ listings',
                'details': data["Career Opportunities"] ?? [],
              },
              {
                'title': 'Mentorship Program',
                'icon': Icons.people,
                'color': AppColors.colors['accent4'] ?? AppColors.colors['accent2'],
                'bgColor': AppColors.colors['cardBg3'] ?? Color(0xFFFFF4D1),
                'description': 'Connect with experienced professionals',
                'count': '${data["Mentorship Programs"]?.length ?? 50}+ mentors',
                'details': data["Mentorship Programs"] ?? [],
              },
              {
                'title': 'Skill Development',
                'icon': Icons.trending_up,
                'color': AppColors.colors['accent3'] ?? AppColors.colors['accent1'],
                'bgColor': AppColors.colors['cardBg4'] ?? Color(0xFFFFE4E1),
                'description': 'Free courses and training resources',
                'count': '${data["Skill Development"]?.length ?? 100}+ courses',
                'details': data["Skill Development"] ?? [],
              },
            ];
          });
        }
      } else {
        print("Failed to fetch data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
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
          automaticallyImplyLeading: false,
          title: Text(
            "Education Hub",
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
          onRefresh: () async {
            await fetchEducationResources();
          },
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.colors['accent2']))
              : resources.isEmpty
                  ? Center(child: Text("No resources available"))
                  : Column(
                      children: [
                        // Banner container with gradient background
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.colors['accent2']!.withOpacity(0.1),
                                AppColors.colors['accent1']!.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.colors['accent2']!.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.colors['accent2']!,
                                      AppColors.colors['accent1']!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Empowering through",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.colors['primary'],
                                      ),
                                    ),
                                    Text(
                                      "Education & Opportunities",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.colors['accent2'],
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Resource cards in a scrollable list
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: resources.length,
                            itemBuilder: (context, index) {
                              final resource = resources[index];
                              return _buildEnhancedCard(
                                context: context,
                                title: resource['title'],
                                icon: resource['icon'],
                                color: resource['color'],
                                bgColor: resource['bgColor'],
                                description: resource['description'],
                                count: resource['count'],
                                details: resource['details'],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
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
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
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

  Widget _buildEnhancedCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String description,
    required String count,
    required List<dynamic> details,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showResourceDetails(context, title, details);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.colors['primary'],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResourceDetails(BuildContext context, String title, List<dynamic> details) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 550, maxWidth: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.colors['accent2'],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Get guidance and mentorship from experienced professionals.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final item = details[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            item['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.colors['primary'],
                            ),
                          ),
                          subtitle: Text(
                            item['description'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item['deadline'] != null) _buildInfoRow('Deadline', item['deadline']),
                                  if (item['amount'] != null) _buildInfoRow('Amount', item['amount']),
                                  if (item['location'] != null) _buildInfoRow('Location', item['location']),
                                  if (item['type'] != null) _buildInfoRow('Type', item['type']),
                                  if (item['duration'] != null) _buildInfoRow('Duration', item['duration']),
                                  if (item['format'] != null) _buildInfoRow('Format', item['format']),
                                  if (item['level'] != null) _buildInfoRow('Level', item['level']),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.colors['accent2'],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      // Implement apply/learn more functionality
                                    },
                                    child: Text('Learn More', style: TextStyle(color: Colors.white)),
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
        );
      },
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.colors['primary'],
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}







// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// https://mozilla.org/MPL/2.0/.
// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'community_page.dart';
// import 'product_page.dart';
// import 'settings_page.dart';
// import 'package:voices_unheard/app_colors.dart';


// class EducationPage extends StatelessWidget {
//   final List<Map<String, dynamic>> resources = [
//     {
//       'title': 'Scholarship & Grants',
//       'icon': Icons.school,
//       'color': AppColors.colors['accent2'],
//       'bgColor': AppColors.colors['cardBg2'],
//       'description': 'Find financial aid opportunities tailored for you',
//       'count': '250+ opportunities',
//       'details': 'Explore various scholarships and grants to support your education.',
//     },
//     {
//       'title': 'Career Opportunities',
//       'icon': Icons.work,
//       'color': AppColors.colors['accent1'],
//       'bgColor': AppColors.colors['cardBg1'],
//       'description': 'Explore jobs and internships in your field',
//       'count': '1000+ listings',
//       'details': 'Find internships and job openings in various industries.',
//     },
//     {
//       'title': 'Mentorship Program',
//       'icon': Icons.people,
//       'color': AppColors.colors['accent4'],
//       'bgColor': AppColors.colors['cardBg3'],
//       'description': 'Connect with experienced professionals',
//       'count': '50+ mentors',
//       'details': 'Get guidance and mentorship from experienced professionals.',
//     },
//     {
//       'title': 'Skill Development',
//       'icon': Icons.trending_up,
//       'color': AppColors.colors['accent3'],
//       'bgColor': AppColors.colors['cardBg4'],
//       'description': 'Free courses and training resources',
//       'count': '100+ courses',
//       'details': 'Enhance your skills with various free and paid courses.',
//     },
//   ];


//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: AppColors.colors['background'],
//       ),
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: Text(
//             "Education Hub",
//             style: TextStyle(
//               color: AppColors.colors['accent2'],
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: Colors.white,
//           elevation: 0,
//         ),
//         body: Column(
//           children: [
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.colors['accent2']!.withOpacity(0.1),
//                     AppColors.colors['accent1']!.withOpacity(0.1),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: AppColors.colors['accent2']!.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           AppColors.colors['accent2']!,
//                           AppColors.colors['accent1']!,
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Icon(
//                       Icons.school_rounded,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Empowering through",
//                           style: TextStyle(
//                             fontSize: 15,
//                             color: AppColors.colors['primary'],
//                           ),
//                         ),
//                         Text(
//                           "Education & Opportunities",
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.colors['accent2'],
//                             height: 1.2,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           Expanded(
//             child: ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: resources.length,
//               itemBuilder: (context, index) {
//                 final resource = resources[index];
//                 return _buildEnhancedCard(
//                     context: context, // Pass the BuildContext
//                     title: resource['title'],
//                     icon: resource['icon'],
//                     color: resource['color'],
//                     bgColor: resource['bgColor'],
//                     description: resource['description'],
//                     count: resource['count'],
//                     details: resource['details'], // Ensure this exists
//                     onTap: () {
//                       // Navigate to detailed view
//                     },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_cart_rounded),
//             label: 'Product',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people_alt_sharp),
//             label: 'Community',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.house_rounded),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.library_books_rounded),
//             label: 'Education',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//           ],
//           selectedItemColor: AppColors.colors['accent2'],
//           unselectedItemColor: AppColors.colors['primary'],
//           backgroundColor: Colors.white,
//           currentIndex: 3,
//           type: BottomNavigationBarType.fixed,
//           elevation: 0,
//           onTap: (index) {
//             Widget page;
//             switch (index) {
//               case 0:
//                 page = ProductPage();
//                 break;
//               case 1:
//                 page = CommunityPage();
//                 break;
//               case 2:
//                 page = HomePage();
//                 break;
//               case 3:
//                 page = EducationPage();
//                 break;
//               case 4:
//                 page = SettingsPage();
//                 break;
//               default:
//                 return;
//             }
//             Navigator.pushReplacement(
//               context,
//               PageRouteBuilder(
//                 pageBuilder: (context, animation, secondaryAnimation) => page,
//                 transitionsBuilder: (context, animation, secondaryAnimation, child) {
//                   return FadeTransition(opacity: animation, child: child);
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     ),
//     );
//   }

//   Widget _buildEnhancedCard({
//   required BuildContext context,
//   required String title,
//   required IconData icon,
//   required Color color,
//   required Color bgColor,
//   required String description,
//   required String count,
//   required String details,
//   required VoidCallback onTap,
// }) {
//   return Container(
//     margin: EdgeInsets.only(bottom: 16),
//     child: Material(
//       color: bgColor,
//       borderRadius: BorderRadius.circular(20),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: () {
//           _showPopup(context, title, details);
//           onTap(); // Ensures additional tap functionality if needed
//         },
//         child: Padding(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       icon,
//                       color: color,
//                       size: 32,
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.colors['primary'],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           description,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   count,
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

//    void _showPopup(BuildContext context, String title, String details) {
//     // Define content for each category
// final Map<String, List<Map<String, dynamic>>> categoryContent = {
//   'Scholarship & Grants': [
//     {
//       'name': 'Fulbright Scholarship',
//       'description': 'Prestigious international exchange program funding graduate studies',
//       'deadline': 'October 15, 2025',
//       'amount': '\$50,000',
//       'eligibility': 'Undergraduate degree holders, strong academic record',
//       'requirements': [
//         'Bachelor\'s degree',
//         'English proficiency',
//         'Research proposal',
//         'Letters of recommendation'
//       ],
//       'website': 'www.fulbright.org',
//       'status': 'Open'
//     },
//     {
//       'name': 'Gates Millennium Scholars',
//       'description': 'Comprehensive scholarship for minority students in STEM',
//       'deadline': 'January 15, 2026',
//       'amount': 'Full tuition + living expenses',
//       'eligibility': 'Underrepresented minorities in STEM fields',
//       'requirements': [
//         'GPA 3.3 or higher',
//         'Leadership experience',
//         'Community service',
//         'FAFSA completion'
//       ],
//       'website': 'www.gmsp.org',
//       'status': 'Opening Soon'
//     },
//     {
//       'name': 'Hispanic Scholarship Fund',
//       'description': 'Supporting Hispanic students in higher education',
//       'deadline': 'March 30, 2026',
//       'amount': '\$5,000',
//       'eligibility': 'Hispanic heritage, US citizen/permanent resident',
//       'requirements': [
//         'GPA 3.0 or higher',
//         'FAFSA/DREAM Act application',
//         'Enrollment verification',
//         'Personal statement'
//       ],
//       'website': 'www.hsf.net',
//       'status': 'Opening Soon'
//     }
//   ],
  
//   'Career Opportunities': [
//     {
//       'name': 'Google STEP Internship',
//       'description': 'First and second-year student internship program',
//       'location': 'Multiple US locations',
//       'type': 'Summer Internship',
//       'duration': '12 weeks',
//       'salary': '\$7,000-\$8,500/month',
//       'benefits': [
//         'Housing stipend',
//         'Transportation assistance',
//         'Meals provided',
//         'Technical training'
//       ],
//       'requirements': [
//         'First or second year student',
//         'CS or related major',
//         'Programming experience',
//         'Strong problem-solving skills'
//       ],
//       'applicationDeadline': 'December 1, 2025'
//     },
//     {
//       'name': 'Microsoft New Technologists',
//       'description': 'Early career program for diverse tech talent',
//       'location': 'Redmond, WA (Hybrid)',
//       'type': 'Full-time Entry Level',
//       'duration': 'Permanent',
//       'salary': 'Competitive + Benefits',
//       'benefits': [
//         'Health insurance',
//         'Stock options',
//         'Professional development',
//         'Mentorship program'
//       ],
//       'requirements': [
//         'Bachelor\'s degree',
//         'Technical background',
//         'Leadership potential',
//         'Innovation mindset'
//       ],
//       'applicationDeadline': 'Rolling basis'
//     }
//   ],

//   'Mentorship Program': [
//     {
//       'name': 'Women in Tech Mentorship',
//       'description': 'One-on-one mentoring with industry leaders',
//       'duration': '6 months',
//       'format': 'Virtual meetings',
//       'commitment': '2 hours/week',
//       'benefits': [
//         'Career guidance',
//         'Network building',
//         'Skill development',
//         'Industry insights'
//       ],
//       'mentorProfile': [
//         'Senior tech professionals',
//         '5+ years experience',
//         'Different specializations',
//         'Diverse backgrounds'
//       ],
//       'applicationProcess': [
//         'Online application',
//         'Goal statement',
//         'Interview',
//         'Matching process'
//       ],
//       'nextCohort': 'Starting June 2025'
//     },
//     {
//       'name': 'First Generation Professionals',
//       'description': 'Support network for first-gen students and professionals',
//       'duration': '12 months',
//       'format': 'Hybrid (online + in-person)',
//       'commitment': '4 hours/month',
//       'benefits': [
//         'Professional development',
//         'Cultural navigation',
//         'Resource access',
//         'Community support'
//       ],
//       'programComponents': [
//         'Group mentoring',
//         'Workshop series',
//         'Networking events',
//         'Resource library'
//       ],
//       'eligibility': 'First-generation college students/graduates',
//       'nextCohort': 'Rolling admissions'
//     }
//   ],

//   'Skill Development': [
//     {
//       'name': 'Full Stack Web Development',
//       'description': 'Comprehensive web development bootcamp',
//       'duration': '12 weeks',
//       'level': 'Beginner to Intermediate',
//       'format': 'Online, self-paced',
//       'topics': [
//         'HTML/CSS',
//         'JavaScript',
//         'React',
//         'Node.js',
//         'Database Management'
//       ],
//       'includes': [
//         'Video lectures',
//         'Practice projects',
//         'Code reviews',
//         'Career support'
//       ],
//       'certification': 'Yes',
//       'cost': 'Free for eligible participants'
//     },
//     {
//       'name': 'Data Science Fundamentals',
//       'description': 'Essential data science and analytics training',
//       'duration': '8 weeks',
//       'level': 'Beginner',
//       'format': 'Online, instructor-led',
//       'topics': [
//         'Python Programming',
//         'Data Analysis',
//         'Statistics',
//         'Machine Learning Basics'
//       ],
//       'includes': [
//         'Live sessions',
//         'Hands-on projects',
//         'Mentoring',
//         'Job placement assistance'
//       ],
//       'certification': 'Industry-recognized certificate',
//       'cost': 'Scholarship available'
//     },
//     {
//       'name': 'Cloud Computing Essentials',
//       'description': 'AWS and cloud infrastructure training',
//       'duration': '10 weeks',
//       'level': 'Intermediate',
//       'format': 'Hybrid',
//       'topics': [
//         'AWS Services',
//         'Cloud Architecture',
//         'Security',
//         'DevOps'
//       ],
//       'includes': [
//         'Lab access',
//         'Practice exams',
//         'Industry projects',
//         'Certification prep'
//       ],
//       'certification': 'AWS Certification eligible',
//       'cost': 'Partial scholarships available'
//     }
//   ]
// }; showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Container(
//           constraints: BoxConstraints(maxHeight: 550, maxWidth: 700),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: AppColors.colors['accent2'],
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 19,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close, color: Colors.white),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   details,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: categoryContent[title]?.length ?? 0,
//                   itemBuilder: (context, index) {
//                     final item = categoryContent[title]![index];
//                     return Card(
//                       margin: EdgeInsets.only(bottom: 12),
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ExpansionTile(
//                         title: Text(
//                           item['name'] ?? '',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.colors['primary'],
//                           ),
//                         ),
//                         subtitle: Text(
//                           item['description'] ?? '',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 if (item['deadline'] != null) _buildInfoRow('Deadline', item['deadline']!),
//                                 if (item['amount'] != null) _buildInfoRow('Amount', item['amount']!),
//                                 if (item['location'] != null) _buildInfoRow('Location', item['location']!),
//                                 if (item['type'] != null) _buildInfoRow('Type', item['type']!),
//                                 if (item['duration'] != null) _buildInfoRow('Duration', item['duration']!),
//                                 if (item['format'] != null) _buildInfoRow('Format', item['format']!),
//                                 if (item['level'] != null) _buildInfoRow('Level', item['level']!),
//                                 SizedBox(height: 8),
//                                 ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: AppColors.colors['accent2'],
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   onPressed: () {
//                                     // Implement apply/learn more functionality
//                                   },
//                                   child: Text('Learn More', style: TextStyle(color: Colors.white),),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

// Widget _buildInfoRow(String label, String value) {
//   return Padding(
//     padding: EdgeInsets.only(bottom: 8),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '$label: ',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: AppColors.colors['primary'],
//           ),
//         ),
//         Expanded(
//           child: Text(
//             value,
//             style: TextStyle(
//               color: Colors.grey[700],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }