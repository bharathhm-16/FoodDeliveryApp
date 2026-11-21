import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  List categories = [];
  String? _selectedCategoryId;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // Backend inda categories (Main Course, Burgers) na thegoluvudu
  Future<void> fetchCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/manager/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
          if (categories.isNotEmpty) {
            _selectedCategoryId = categories[0]['id'].toString();
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Hosa item na save maduvudu
  Future<void> saveItem() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedCategoryId == null) {
      Fluttertoast.showToast(msg: "Please fill Name, Price and Category", backgroundColor: Colors.red);
      return;
    }

    setState(() => isSaving = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/manager/menu/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'price': _priceController.text.trim(),
          'description': _descController.text.trim(),
          'categoryId': _selectedCategoryId,
          'imageUrl': _imageUrlController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: "Item Added Successfully! 🎉", 
          backgroundColor: Colors.green, 
          textColor: Colors.white
        );
        if (mounted) Navigator.pop(context); // Success aadmele vapas hogutte
      } else {
        Fluttertoast.showToast(msg: "Failed to add item", backgroundColor: Colors.red, textColor: Colors.white);
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
        title: Text("Add New Food Item", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Food Name (e.g. Chicken Biryani)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 15),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: categories.map<DropdownMenuItem<String>>((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['id'].toString(),
                          child: Text(cat['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: isSaving ? null : saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text("Save Item", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}