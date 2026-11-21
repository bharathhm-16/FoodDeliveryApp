import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _nameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool isSaving = false;

  Future<void> saveRestaurant() async {
    if (_nameController.text.isEmpty || _cuisineController.text.isEmpty || _addressController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill Name, Cuisine and Address", backgroundColor: Colors.red);
      return;
    }

    setState(() => isSaving = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/admin/restaurants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'cuisineType': _cuisineController.text.trim(),
          'addressLine': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'imageUrl': _imageUrlController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: "Restaurant Added Successfully! 🎉", 
          backgroundColor: Colors.green, 
          textColor: Colors.white
        );
        if (mounted) Navigator.pop(context); // Success aadmele vapas hogutte
      } else {
        Fluttertoast.showToast(msg: "Failed to add restaurant", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Server Error", backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Restaurant", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Restaurant Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _cuisineController,
                decoration: InputDecoration(labelText: 'Cuisine Type (e.g. Indian, Chinese)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address Line', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isSaving ? null : saveRestaurant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text("Save Restaurant", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}