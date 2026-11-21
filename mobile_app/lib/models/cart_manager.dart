class CartManager {
  static List<Map<String, dynamic>> cartItems = [];

  static void addItem(Map<String, dynamic> item, int restaurantId) {
    int index = cartItems.indexWhere((element) => element['id'] == item['id']);
    
    // Price na double ge convert madthidivi (String idre number ge change aagutte)
    double parsedPrice = double.tryParse(item['price'].toString()) ?? 0.0;

    if (index >= 0) {
      cartItems[index]['quantity'] += 1;
    } else {
      cartItems.add({
        'id': item['id'],
        'name': item['name'],
        'price': parsedPrice, // Illi Double price save aagutte
        'quantity': 1,
        'restaurantId': restaurantId,
      });
    }
  }

  static void decreaseQuantity(int id) {
    int index = cartItems.indexWhere((element) => element['id'] == id);
    if (index >= 0) {
      if (cartItems[index]['quantity'] > 1) {
        cartItems[index]['quantity'] -= 1;
      } else {
        cartItems.removeAt(index);
      }
    }
  }

  static int getQuantity(int id) {
    int index = cartItems.indexWhere((element) => element['id'] == id);
    if (index >= 0) {
      return cartItems[index]['quantity'];
    }
    return 0;
  }

  static void removeItem(int id) {
    cartItems.removeWhere((element) => element['id'] == id);
  }

  static double getTotal() {
    double total = 0;
    for (var item in cartItems) {
      // Illi math sari aagi work aagutte
      total += ((item['price'] as double) * (item['quantity'] as int));
    }
    return total;
  }
  
  static void clearCart() {
    cartItems.clear();
  }
}