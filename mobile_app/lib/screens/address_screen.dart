import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  // Backend inda address thegoluvudu
  Future<void> fetchAddresses() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/addresses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          addresses = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Address Delete maduvudu
  Future<void> deleteAddress(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/api/addresses/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Address Deleted", backgroundColor: Colors.red, textColor: Colors.white);
        fetchAddresses();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting address", backgroundColor: Colors.red);
    }
  }

  // Hosa Address Add madalu BottomSheet thorsuvudu
  void showAddAddressSheet() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final pincodeController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add New Address", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: labelController,
                    decoration: InputDecoration(labelText: 'Label (e.g. Home, Work)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address Line (House No, Street)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cityController,
                    decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Pincode', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: isSaving ? null : () async {
                      if (addressController.text.isEmpty || cityController.text.isEmpty) {
                        Fluttertoast.showToast(msg: "Please fill address and city", backgroundColor: Colors.red);
                        return;
                      }
                      setStateSheet(() => isSaving = true);
                      try {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        String? token = prefs.getString('token');

                        final response = await http.post(
                          Uri.parse('http://10.0.2.2:8080/api/addresses'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token'
                          },
                          body: jsonEncode({
                            'label': labelController.text.trim(),
                            'addressLine': addressController.text.trim(),
                            'city': cityController.text.trim(),
                            'postalCode': pincodeController.text.trim(),
                            'isDefault': addresses.isEmpty // Modala address idre default maduvudu
                          }),
                        );

                        if (response.statusCode == 201) {
                          Fluttertoast.showToast(msg: "Address Added! 🎉", backgroundColor: Colors.green);
                          // ignore: use_build_context_synchronously
                          if (mounted) Navigator.pop(context); // Sheet close maduvudu
                          fetchAddresses();
                        }
                      } catch (e) {
                        Fluttertoast.showToast(msg: "Server Error", backgroundColor: Colors.red);
                      } finally {
                        setStateSheet(() => isSaving = false);
                      }
                    },
                    child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text("Save Address", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Addresses", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6B35),
        onPressed: showAddAddressSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Add Address", style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? Center(child: Text("No addresses saved!", style: GoogleFonts.poppins(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          address['label'] == 'Work' ? Icons.work : Icons.home, 
                          color: const Color(0xFFFF6B35)
                        ),
                        title: Text(address['label'] ?? 'Address', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${address['addressLine']}, ${address['city']} - ${address['postalCode'] ?? ''}", 
                          style: GoogleFonts.poppins(fontSize: 12)
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteAddress(address['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}