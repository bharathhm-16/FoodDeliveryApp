import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cart_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isPlacingOrder = false;
  String _selectedPaymentMethod = 'CASH_ON_DELIVERY';
  
  // Coupon ge bekuva variables
  final TextEditingController _couponController = TextEditingController();
  double _discountAmount = 0.0;
  String? _appliedCouponCode;
  bool _isApplyingCoupon = false;

  // 1. Coupon Apply Maduva Logic
  Future<void> applyCoupon() async {
    if (_couponController.text.isEmpty) return;
    setState(() => _isApplyingCoupon = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/orders/validate-coupon'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'code': _couponController.text.trim(),
          'subtotal': CartManager.getTotal(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _discountAmount = double.parse(data['discountAmount'].toString());
          _appliedCouponCode = _couponController.text.trim();
        });
        Fluttertoast.showToast(msg: data['message'], backgroundColor: Colors.green, textColor: Colors.white);
      } else {
        Fluttertoast.showToast(msg: data['message'], backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error applying coupon", backgroundColor: Colors.red);
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  // 2. Order Place Maduva Logic
  Future<void> placeOrder() async {
    if (CartManager.cartItems.isEmpty) return;

    setState(() => isPlacingOrder = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'restaurantId': CartManager.cartItems[0]['restaurantId'],
          'items': CartManager.cartItems,
          'totalAmount': CartManager.getTotal(),
          'paymentMethod': _selectedPaymentMethod,
          'couponCode': _appliedCouponCode, // Coupon code kalsuvudu
        }),
      );

      if (response.statusCode == 201) {
        CartManager.clearCart();
        Fluttertoast.showToast(
          msg: "Order Placed Successfully! 🎉", 
          backgroundColor: Colors.green,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
        );
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: "Failed to place order", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Server Error", backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      setState(() => isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bill Calculations
    double subtotal = CartManager.getTotal();
    double deliveryFee = 40.0;
    double finalTotal = (subtotal + deliveryFee) - _discountAmount;
    if (finalTotal < 0) finalTotal = 0; // Discount jasthi aadre total negative aagabardu

    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: CartManager.cartItems.isEmpty
          ? Center(child: Text("Your cart is empty!", style: GoogleFonts.poppins(fontSize: 16)))
          : Column(
              children: [
                // 1. CART ITEMS LIST
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: CartManager.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = CartManager.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Text("Qty: ${item['quantity']} x ₹${item['price']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                CartManager.removeItem(item['id']);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // 2. BOTTOM SHEET (Coupon, Payment, Bill)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HOSA COUPON UI ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: "Enter Coupon Code (e.g. WELCOME50)",
                                hintStyle: GoogleFonts.poppins(fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isApplyingCoupon ? null : applyCoupon,
                            child: _isApplyingCoupon 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : Text("Apply", style: GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ],
                      ),
                      
                      if (_appliedCouponCode != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Coupon '$_appliedCouponCode' applied! 🎉", style: GoogleFonts.poppins(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      
                      const Divider(height: 30),

                      // --- PAYMENT METHODS ---
                      Text("Payment Method", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      RadioListTile<String>(
                        title: Text("Cash on Delivery", style: GoogleFonts.poppins(fontSize: 14)),
                        value: 'CASH_ON_DELIVERY',
                        // ignore: deprecated_member_use
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color(0xFFFF6B35),
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                      ),
                      
                      RadioListTile<String>(
                        title: Text("UPI (Test Mode)", style: GoogleFonts.poppins(fontSize: 14)),
                        value: 'UPI',
                        // ignore: deprecated_member_use
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color(0xFFFF6B35),
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                      ),

                      const Divider(),
                      
                      // --- BILL SUMMARY ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Subtotal:", style: GoogleFonts.poppins(fontSize: 14)),
                          Text("₹$subtotal", style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Delivery Fee:", style: GoogleFonts.poppins(fontSize: 14)),
                          Text("₹$deliveryFee", style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Discount:", style: GoogleFonts.poppins(fontSize: 14, color: Colors.green)),
                            Text("-₹$_discountAmount", style: GoogleFonts.poppins(fontSize: 14, color: Colors.green)),
                          ],
                        ),
                      ],
                      const Divider(),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total:", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("₹${finalTotal.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B35))),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isPlacingOrder ? null : placeOrder,
                        child: isPlacingOrder 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : Text("Place Order", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}