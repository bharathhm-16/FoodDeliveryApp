import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../main.dart';
import 'add_restaurant_screen.dart'; // Hosa Screen Import

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> stats = {};
  List users = [];
  Map<String, dynamic> chartData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final statsResponse = await http.get(Uri.parse('http://10.0.2.2:8080/api/admin/stats'), headers: {'Authorization': 'Bearer $token'});
      final usersResponse = await http.get(Uri.parse('http://10.0.2.2:8080/api/admin/users'), headers: {'Authorization': 'Bearer $token'});
      final chartResponse = await http.get(Uri.parse('http://10.0.2.2:8080/api/admin/charts'), headers: {'Authorization': 'Bearer $token'});

      if (statsResponse.statusCode == 200 && usersResponse.statusCode == 200 && chartResponse.statusCode == 200) {
        setState(() {
          stats = jsonDecode(statsResponse.body);
          users = jsonDecode(usersResponse.body);
          chartData = jsonDecode(chartResponse.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin Dashboard", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: fetchAdminData),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF6B35),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Stats"),
              Tab(text: "Charts"),
              Tab(text: "Users"),
            ],
          ),
        ),
        // HOSA: FLOATING BUTTON ADD RESTAURANT GE HOGALU
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddRestaurantScreen()),
            ).then((_) => fetchAdminData()); // Vapas bandmele stats refresh maduvudu
          },
          backgroundColor: const Color(0xFFFF6B35),
          icon: const Icon(Icons.add_business, color: Colors.white),
          label: Text("Add Restaurant", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // --- TAB 1: STATISTICS ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildStatCard("Total Users", stats['totalUsers'].toString(), Icons.people, Colors.blue),
                        _buildStatCard("Total Orders", stats['totalOrders'].toString(), Icons.shopping_bag, Colors.orange),
                        _buildStatCard("Restaurants", stats['totalRestaurants'].toString(), Icons.store, Colors.green),
                        _buildStatCard("Revenue", "₹${stats['totalRevenue']}", Icons.attach_money, Colors.purple),
                      ],
                    ),
                  ),

                  // --- TAB 2: CHARTS ---
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text("Order Status", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        
                        // PIE CHART
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: Colors.blue, value: chartData['orderStatus']['placed'].toDouble(), title: 'Placed', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                PieChartSectionData(color: Colors.orange, value: chartData['orderStatus']['preparing'].toDouble(), title: 'Prep', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                PieChartSectionData(color: Colors.purple, value: chartData['orderStatus']['outForDelivery'].toDouble(), title: 'Out', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                PieChartSectionData(color: Colors.green, value: chartData['orderStatus']['delivered'].toDouble(), title: 'Done', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        Text("Revenue by Restaurant", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        
                        // BAR CHART
                        Container(
                          height: 250, 
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: (chartData['revenueByRestaurant'] as List).take(5).map((rest) { // Top 5 matra thorsodu
                              double revenue = double.tryParse(rest['revenue'].toString()) ?? 0.0;
                              double barHeight = revenue > 0 ? (revenue / 1000) * 150 : 5; 
                              if (barHeight > 150) barHeight = 150;
                              
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("₹${revenue.toInt()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 40,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: 60, 
                                    child: Text(
                                      rest['name'], 
                                      textAlign: TextAlign.center, 
                                      style: const TextStyle(fontSize: 10), 
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- TAB 3: ALL USERS ---
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user['role']).withValues(alpha: 0.2),
                            child: Icon(Icons.person, color: _getRoleColor(user['role'])),
                          ),
                          title: Text(user['fullName'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['email'], style: GoogleFonts.poppins(fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _getRoleColor(user['role']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                            child: Text(user['role'], style: GoogleFonts.poppins(fontSize: 10, color: _getRoleColor(user['role']), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN': return Colors.purple;
      case 'RESTAURANT_MANAGER': return Colors.orange;
      case 'DELIVERY_AGENT': return Colors.blue;
      default: return Colors.green;
    }
  }
}