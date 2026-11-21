import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'restaurant_menu_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'address_screen.dart'; // Address screen import
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List allRestaurants = [];
  List filteredRestaurants = [];
  List favoriteIds = [];

  bool isLoading = true;
  String errorMessage = "";
  String searchQuery = "";
  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "North Indian",
    "Fast Food",
    "Pizza",
    "Chinese",
    "South Indian",
    "Desserts"
  ];

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
    fetchFavorites();
  }

  void fetchRestaurants() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:8080/api/restaurants'));

      if (response.statusCode == 200) {
        setState(() {
          allRestaurants = jsonDecode(response.body);
          filteredRestaurants = allRestaurants;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Server returned: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Network Error. Is the backend running?";
      });
    }
  }

  void fetchFavorites() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List favs = jsonDecode(response.body);
        setState(() {
          favoriteIds = favs.map((f) => f['restaurantId']).toList();
        });
      }
    } catch (e) {
      print("Favorite fetch error");
    }
  }

  void toggleFavorite(int restaurantId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'restaurantId': restaurantId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchFavorites();
        Fluttertoast.showToast(
            msg: "Favorites Updated! ❤️",
            backgroundColor: Colors.pink,
            textColor: Colors.white);
      }
    } catch (e) {
      print("Toggle error");
    }
  }

  void filterData() {
    setState(() {
      filteredRestaurants = allRestaurants.where((rest) {
        final name = rest['name'].toString().toLowerCase();
        final cuisine = (rest['cuisineType'] ?? '').toString().toLowerCase();

        bool matchesSearch = name.contains(searchQuery.toLowerCase()) ||
            cuisine.contains(searchQuery.toLowerCase());
        bool matchesCategory = selectedCategory == "All" ||
            cuisine.contains(selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // CLICK MADIDRE ADDRESS GE HOGUVA LOGIC
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressScreen()),
            ).then((_) => setState(() {}));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Deliver to",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFFFF6B35), size: 16),
                  const SizedBox(width: 4),
                  Text("Mumbai, India",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFFFF6B35), size: 20),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.purple),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : CustomScrollView(
                  slivers: [
                    // SEARCH BAR
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          onChanged: (val) {
                            searchQuery = val;
                            filterData();
                          },
                          decoration: InputDecoration(
                            hintText: "Search for restaurants or dishes...",
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFFFF6B35)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                    ),

                    // CATEGORIES
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = selectedCategory == cat;

                            return GestureDetector(
                              onTap: () {
                                selectedCategory = cat;
                                filterData();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF6B35)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.grey.shade300),
                                ),
                                child: Center(
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // TOP RATED
                    if (searchQuery.isEmpty && selectedCategory == "All") ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("Top Rated Near You",
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(
                                left: 16, top: 10, bottom: 10),
                            itemCount: allRestaurants.take(5).length,
                            itemBuilder: (context, index) {
                              final rest = allRestaurants[index];
                              return _buildHorizontalCard(rest);
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    ],

                    // ALL RESTAURANTS Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                            selectedCategory == "All"
                                ? "All Restaurants"
                                : "$selectedCategory Restaurants",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // ALL RESTAURANTS List
                    filteredRestaurants.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text("No restaurants found.",
                                    style:
                                        GoogleFonts.poppins(color: Colors.grey)),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final rest = filteredRestaurants[index];
                                return _buildVerticalCard(rest);
                              },
                              childCount: filteredRestaurants.length,
                            ),
                          ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen()))
                .then((_) => setState(() {}));
          }
          if (index == 2) {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FavoritesScreen()))
                .then((_) => fetchFavorites());
          }
          if (index == 3) {
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CartScreen()))
                .then((_) => setState(() {}));
          }
        },
      ),
    );
  }

  // Horizontal Card (Top Rated)
  Widget _buildHorizontalCard(Map<String, dynamic> rest) {
    bool isFav = favoriteIds.contains(rest['id']);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RestaurantMenuScreen(
                    restaurantId: rest['id'],
                    restaurantName: rest['name']))).then((_) => setState(() {}));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    rest['imageUrl'] ??
                        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
                    height: 90,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 90,
                        width: 160,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant,
                            size: 30, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => toggleFavorite(rest['id']),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.pink : Colors.grey,
                          size: 16),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(rest['name'],
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(rest['cuisineType'] ?? 'Multi-Cuisine',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 2),
                        Text("4.2",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Vertical Card (List alli)
  Widget _buildVerticalCard(Map<String, dynamic> rest) {
    bool isFav = favoriteIds.contains(rest['id']);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RestaurantMenuScreen(
                    restaurantId: rest['id'],
                    restaurantName: rest['name']))).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    rest['imageUrl'] ??
                        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant,
                                size: 40, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text("Image unavailable",
                                style: GoogleFonts.poppins(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => toggleFavorite(rest['id']),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.pink : Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text("30-40 mins",
                        style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(rest['name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(rest['cuisineType'] ?? 'Multi-Cuisine',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text("4.5",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}