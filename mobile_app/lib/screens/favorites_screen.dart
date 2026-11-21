import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'restaurant_menu_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  // Backend inda favorites list thegoluvudu
  Future<void> fetchFavorites() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          favorites = jsonDecode(response.body);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("My Favorites", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Center(child: Text("No favorites yet!", style: GoogleFonts.poppins(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final rest = favorites[index]['restaurant']; // Favorite object olage restaurant ide
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(rest['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text(rest['cuisineType'] ?? 'Multi-Cuisine', style: GoogleFonts.poppins(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Restaurant Menu ge hoguvudu
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantMenuScreen(
                                restaurantId: rest['id'],
                                restaurantName: rest['name'],
                              ),
                            ),
                          ).then((_) => fetchFavorites()); // Vapas bandmele refresh maduvudu
                        },
                      ),
                    );
                  },
                ),
    );
  }
}