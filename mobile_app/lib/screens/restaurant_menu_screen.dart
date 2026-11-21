import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_manager.dart';
import 'cart_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const RestaurantMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  Map<String, dynamic>? restaurantData;
  bool isLoading = true;

  // Prathi single item ge 100% UNIQUE photo (Yaavude picture repeat aagalla)
  final Map<String, List> restaurantMenus = {
    'idli': [
      {
        'name': 'South Indian Tiffin',
        'items': [
          {
            'id': 101,
            'name': 'Mallige Idli (2 Pcs)',
            'price': 50.0,
            'imageUrl': 'https://images.pexels.com/photos/4331490/pexels-photo-4331490.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 102,
            'name': 'Masala Dosa',
            'price': 85.0,
            'imageUrl': 'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 103,
            'name': 'Medu Vada (2 Pcs)',
            'price': 60.0,
            'imageUrl': 'https://images.pexels.com/photos/20422138/pexels-photo-20422138.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 104,
            'name': 'Filter Coffee',
            'price': 35.0,
            'imageUrl': 'https://images.pexels.com/photos/312418/pexels-photo-312418.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'fish': [
      {
        'name': 'Seafood Specials',
        'items': [
          {
            'id': 201,
            'name': 'Classic Fish & Chips',
            'price': 320.0,
            'imageUrl': 'https://images.pexels.com/photos/12312104/pexels-photo-12312104.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 202,
            'name': 'Grilled Lemon Butter Prawns',
            'price': 380.0,
            'imageUrl': 'https://images.pexels.com/photos/725992/pexels-photo-725992.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 203,
            'name': 'Crispy Calamari Rings',
            'price': 260.0,
            'imageUrl': 'https://images.pexels.com/photos/6941010/pexels-photo-6941010.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'kebab': [
      {
        'name': 'Tandoor & Kebabs',
        'items': [
          {
            'id': 301,
            'name': 'Chicken Seekh Kebab',
            'price': 240.0,
            'imageUrl': 'https://images.pexels.com/photos/5410400/pexels-photo-5410400.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 302,
            'name': 'Paneer Tikka',
            'price': 210.0,
            'imageUrl': 'https://images.pexels.com/photos/3928854/pexels-photo-3928854.png?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 303,
            'name': 'Tandoori Chicken (Half)',
            'price': 280.0,
            'imageUrl': 'https://images.pexels.com/photos/2673353/pexels-photo-2673353.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'juice': [
      {
        'name': 'Fresh Juices & Smoothies',
        'items': [
          {
            'id': 401,
            'name': 'Fresh Orange Juice',
            'price': 90.0,
            'imageUrl': 'https://images.pexels.com/photos/158053/fresh-orange-juice-squeezed-refreshing-citrus-158053.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 402,
            'name': 'Watermelon Mint Cooler',
            'price': 80.0,
            'imageUrl': 'https://images.pexels.com/photos/1337825/pexels-photo-1337825.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 403,
            'name': 'Alphonso Mango Smoothie',
            'price': 130.0,
            'imageUrl': 'https://images.pexels.com/photos/4955257/pexels-photo-4955257.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'paratha': [
      {
        'name': 'Stuffed Parathas & Lassi',
        'items': [
          {
            'id': 501,
            'name': 'Aloo Cheese Paratha',
            'price': 110.0,
            'imageUrl': 'https://images.pexels.com/photos/12737912/pexels-photo-12737912.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 502,
            'name': 'Paneer Butter Paratha',
            'price': 130.0,
            'imageUrl': 'https://images.pexels.com/photos/2474661/pexels-photo-2474661.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 503,
            'name': 'Punjabi Sweet Lassi',
            'price': 70.0,
            'imageUrl': 'https://images.pexels.com/photos/892649/pexels-photo-892649.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'brownie': [
      {
        'name': 'Desserts & Brownies',
        'items': [
          {
            'id': 601,
            'name': 'Sizzling Walnut Brownie',
            'price': 190.0,
            'imageUrl': 'https://images.pexels.com/photos/3026804/pexels-photo-3026804.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 602,
            'name': 'Belgian Chocolate Truffle',
            'price': 150.0,
            'imageUrl': 'https://images.pexels.com/photos/291528/pexels-photo-291528.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 603,
            'name': 'Nutella Cheesecake Jar',
            'price': 180.0,
            'imageUrl': 'https://images.pexels.com/photos/1126359/pexels-photo-1126359.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'noodle': [
      {
        'name': 'Asian Bowls & Noodles',
        'items': [
          {
            'id': 701,
            'name': 'Chilli Garlic Hakka Noodles',
            'price': 160.0,
            'imageUrl': 'https://images.pexels.com/photos/2347311/pexels-photo-2347311.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 702,
            'name': 'Spicy Chicken Ramen Bowl',
            'price': 260.0,
            'imageUrl': 'https://images.pexels.com/photos/884600/pexels-photo-884600.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 703,
            'name': 'Veg Manchurian Dry',
            'price': 150.0,
            'imageUrl': 'https://images.pexels.com/photos/699953/pexels-photo-699953.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'pizza': [
      {
        'name': 'Wood-Fired Pizzas',
        'items': [
          {
            'id': 801,
            'name': 'Margherita Cheese Pizza',
            'price': 220.0,
            'imageUrl': 'https://images.pexels.com/photos/825661/pexels-photo-825661.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 802,
            'name': 'Farmhouse Veggie Pizza',
            'price': 290.0,
            'imageUrl': 'https://images.pexels.com/photos/1146760/pexels-photo-1146760.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 803,
            'name': 'Pepperoni Feast Pizza',
            'price': 340.0,
            'imageUrl': 'https://images.pexels.com/photos/4109111/pexels-photo-4109111.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'biryani': [
      {
        'name': 'Royal Dum Biryanis',
        'items': [
          {
            'id': 901,
            'name': 'Hyderabadi Chicken Dum Biryani',
            'price': 260.0,
            'imageUrl': 'https://images.pexels.com/photos/7394819/pexels-photo-7394819.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 902,
            'name': 'Paneer Tikka Biryani',
            'price': 230.0,
            'imageUrl': 'https://images.pexels.com/photos/9609838/pexels-photo-9609838.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 903,
            'name': 'Mutton Zafrani Biryani',
            'price': 340.0,
            'imageUrl': 'https://images.pexels.com/photos/12737656/pexels-photo-12737656.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
    'burger': [
      {
        'name': 'Gourmet Burgers & Fries',
        'items': [
          {
            'id': 1001,
            'name': 'Crispy Chicken Zinger Burger',
            'price': 180.0,
            'imageUrl': 'https://images.pexels.com/photos/1639557/pexels-photo-1639557.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 1002,
            'name': 'Double Cheese Veggie Burger',
            'price': 150.0,
            'imageUrl': 'https://images.pexels.com/photos/1199957/pexels-photo-1199957.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
          {
            'id': 1003,
            'name': 'Peri Peri French Fries',
            'price': 99.0,
            'imageUrl': 'https://images.pexels.com/photos/1583884/pexels-photo-1583884.jpeg?auto=compress&cs=tinysrgb&w=500',
          },
        ]
      }
    ],
  };

  // Fallback unique pool if any unknown restaurant comes from backend
  final List<String> fallbackUniqueImages = [
    'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=500',
    'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg?auto=compress&cs=tinysrgb&w=500',
    'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg?auto=compress&cs=tinysrgb&w=500',
    'https://images.pexels.com/photos/461198/pexels-photo-461198.jpeg?auto=compress&cs=tinysrgb&w=500',
    'https://images.pexels.com/photos/1099680/pexels-photo-1099680.jpeg?auto=compress&cs=tinysrgb&w=500',
    'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=500',
  ];

  @override
  void initState() {
    super.initState();
    fetchMenu();
  }

  void fetchMenu() async {
    String restName = widget.restaurantName.trim().toLowerCase();

    for (var entry in restaurantMenus.entries) {
      if (restName.contains(entry.key)) {
        final formattedCategories = entry.value.map((cat) {
          final itemsList = (cat['items'] as List).map((item) {
            final img = item['imageUrl'];
            return {
              ...item,
              'images': [
                {'imageUrl': img}
              ],
            };
          }).toList();
          return {
            'name': cat['name'],
            'items': itemsList,
          };
        }).toList();

        setState(() {
          restaurantData = {'categories': formattedCategories};
          isLoading = false;
        });
        return;
      }
    }

    // Backend API fallback (assigns a different image per index so nothing repeats)
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/restaurants/${widget.restaurantId}/menu'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        int imgIndex = 0;
        if (decoded['categories'] != null) {
          for (var cat in decoded['categories']) {
            if (cat['items'] != null) {
              for (var item in cat['items']) {
                String uniqueImg = fallbackUniqueImages[imgIndex % fallbackUniqueImages.length];
                imgIndex++;
                item['imageUrl'] = uniqueImg;
                item['images'] = [
                  {'imageUrl': uniqueImg}
                ];
              }
            }
          }
        }
        setState(() {
          restaurantData = decoded;
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
    int totalItems = CartManager.cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
    double totalPrice = CartManager.getTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurantData == null || restaurantData!['categories'].isEmpty
              ? const Center(child: Text("Menu not available."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: restaurantData!['categories'].length,
                  itemBuilder: (context, catIndex) {
                    final category = restaurantData!['categories'][catIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...category['items'].map<Widget>((item) {
                          // Direct item map alli iruva unique imageUrl thagolutthe
                          String imgUrl = item['imageUrl'] ??
                              'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=500';
                          int currentQty = CartManager.getQuantity(item['id']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imgUrl,
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 65,
                                      height: 65,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                item['name'],
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                "₹${item['price']}",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF6B35),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: currentQty == 0
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B35),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          CartManager.addItem(item, widget.restaurantId);
                                        });
                                      },
                                      child: const Text("Add", style: TextStyle(color: Colors.white)),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                CartManager.decreaseQuantity(item['id']);
                                              });
                                            },
                                          ),
                                          Text(
                                            "$currentQty",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                CartManager.addItem(item, widget.restaurantId);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
      bottomNavigationBar: totalItems > 0
          ? SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$totalItems Items",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          "₹${totalPrice.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartScreen()),
                        ).then((_) {
                          setState(() {});
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            "View Cart",
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          : null,
    );
  }
}