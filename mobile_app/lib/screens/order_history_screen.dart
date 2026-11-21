import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'tracking_screen.dart'; 
import 'add_review_screen.dart'; 
import 'cart_screen.dart'; // Cart import
import '../models/cart_manager.dart'; // Cart Manager import

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  void fetchOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/orders/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // HOSA: Reorder Logic (Hale order na cart ge add maduvudu)
  void reorder(Map<String, dynamic> order) {
    CartManager.clearCart(); // Modalu hale cart na khali maduvudu
    
    int restaurantId = order['restaurant']['id'];
    List items = order['items'];

    for (var item in items) {
      Map<String, dynamic> cartItem = {
        'id': item['foodItemId'],
        'name': item['itemName'],
        'price': item['unitPrice']
      };
      
      // Quantity yashtu itthu, ashtu salla add maduvudu
      for (int i = 0; i < item['quantity']; i++) {
        CartManager.addItem(cartItem, restaurantId);
      }
    }

    Fluttertoast.showToast(msg: "Items added to cart! 🛒", backgroundColor: Colors.green);
    
    // Direct aagi Cart ge hoguvudu
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text("No orders yet!", style: GoogleFonts.poppins()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          // Order Details (Click madidre Map open aagutte)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrackingScreen(orderData: order),
                                ),
                              );
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15),
                              title: Text(
                                order['restaurant']['name'],
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text("Order ID: ${order['orderNumber']}", style: GoogleFonts.poppins(fontSize: 12)),
                                  Text("Items: ${order['items'].length}", style: GoogleFonts.poppins(fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: order['status'] == 'DELIVERED' 
                                          ? Colors.green.withValues(alpha: 0.2) 
                                          : Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      order['status'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12, 
                                        color: order['status'] == 'DELIVERED' ? Colors.green[800] : Colors.orange[800], 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                "₹${order['totalAmount']}",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFFF6B35), fontSize: 16),
                              ),
                            ),
                          ),
                          
                          // HOSA: REORDER BUTTON & RATE BUTTON
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                            child: Row(
                              children: [
                                // Reorder Button (Yava order ge beku aadru thorsutte)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35), size: 18),
                                    label: Text("Reorder", style: GoogleFonts.poppins(color: const Color(0xFFFF6B35))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFFF6B35)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => reorder(order),
                                  ),
                                ),
                                
                                // Rate Button (Delivered aadmele matra thorsutte)
                                if (order['status'] == 'DELIVERED') ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.star, color: Colors.white, size: 18),
                                      label: Text("Rate", style: GoogleFonts.poppins(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddReviewScreen(
                                              orderId: order['id'],
                                              restaurantName: order['restaurant']['name'],
                                            ),
                                          ),
                                        ).then((_) => fetchOrders());
                                      },
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}