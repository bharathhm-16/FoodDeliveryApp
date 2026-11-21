import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const foodImages = [
  'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500&q=80',
  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&q=80',
  'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
  'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
  'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&q=80',
  'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=500&q=80',
  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
  'https://images.unsplash.com/photo-1550547660-d9450f859349?w=500&q=80',
  'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=500&q=80',
  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=500&q=80'
];

const restaurantsData = [
  { 
    name: 'Spice Garden', cuisine: 'North Indian', img: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=500&q=80', 
    items: [
      'Butter Chicken', 'Paneer Tikka', 'Dal Makhani', 'Garlic Naan', 'Chicken Biryani', 'Mutton Rogan Josh', 'Chole Bhature', 'Palak Paneer', 'Kadai Chicken', 'Tandoori Roti',
      'Raita', 'Gulab Jamun', 'Samosa', 'Aloo Gobi', 'Malai Kofta', 'Chicken Tikka Masala', 'Plain Naan', 'Jeera Rice', 'Rasmalai', 'Sweet Lassi',
      'Paneer Butter Masala', 'Seekh Kebab', 'Dal Tadka', 'Veg Biryani', 'Kulfi', 'Papad', 'Mix Veg Curry', 'Egg Curry', 'Fish Curry', 'Chicken Curry'
    ]
  },
  { 
    name: 'Burger Hub', cuisine: 'Fast Food', img: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&q=80', 
    items: [
      'Classic Cheeseburger', 'Double Bacon Burger', 'Veggie Burger', 'Spicy Chicken Burger', 'French Fries', 'Curly Fries', 'Onion Rings', 'Chicken Nuggets', 'Mozzarella Sticks', 'Chicken Wings',
      'Veggie Wrap', 'Chicken Wrap', 'Vanilla Milkshake', 'Chocolate Milkshake', 'Strawberry Milkshake', 'Coca-Cola', 'Sprite', 'Pepsi', 'Hot Dog', 'Corn Dog',
      'Mac & Cheese Bites', 'Chicken Tenders', 'Grilled Cheese', 'Fish Sandwich', 'Veggie Burger Deluxe', 'BBQ Bacon Burger', 'Mushroom Swiss Burger', 'Loaded Fries', 'Apple Pie', 'Brownie'
    ]
  },
  { 
    name: 'Pizza Hut', cuisine: 'Italian', img: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80', 
    items: [
      'Margherita Pizza', 'Pepperoni Pizza', 'Garlic Bread', 'Pasta', 'Brownie', 'Farmhouse Pizza', 'Veggie Supreme', 'Chicken Supreme', 'Paneer Tikka Pizza', 'Cheese Burst Pizza',
      'Stuffed Garlic Bread', 'Chicken Wings', 'Lasagna', 'Spaghetti', 'Macaroni', 'Caesar Salad', 'Garlic Breadsticks', 'Choco Lava Cake', 'Red Velvet Pastry', 'Tiramisu',
      'Hawaiian Pizza', 'BBQ Chicken Pizza', 'Four Cheese Pizza', 'Mushroom Pizza', 'Olive Pizza', 'Jalapeno Poppers', 'Cheesy Dip', 'Pepsi', '7 Up', 'Mirinda'
    ]
  },
  { 
    name: 'Biryani House', cuisine: 'Hyderabadi', img: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80', 
    items: [
      'Chicken Dum Biryani', 'Mutton Biryani', 'Veg Biryani', 'Raita', 'Kebab', 'Egg Biryani', 'Prawn Biryani', 'Fish Biryani', 'Special Family Pack Biryani', 'Chicken 65',
      'Mutton Korma', 'Double Ka Meetha', 'Mirchi Ka Salan', 'Phirni', 'Haleem', 'Chicken Fry Piece Biryani', 'Paneer Biryani', 'Mushroom Biryani', 'Chicken Tikka Biryani', 'Mutton Keema Biryani',
      'Apollo Fish', 'Tandoori Chicken', 'Chicken Lollipop', 'Butter Naan', 'Rumali Roti', 'Gulab Jamun', 'Qubani Ka Meetha', 'Lassi', 'Masala Papad', 'Green Salad'
    ]
  },
  { 
    name: 'Chinese Wok', cuisine: 'Chinese', img: 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&q=80', 
    items: [
      'Hakka Noodles', 'Chicken Manchurian', 'Fried Rice', 'Spring Rolls', 'Chilli Chicken', 'Schezwan Noodles', 'Chilli Paneer', 'Veg Manchurian', 'Chicken Lollipop', 'Sweet and Sour Chicken',
      'Kung Pao Chicken', 'Chow Mein', 'Momos', 'Wontons', 'Hot and Sour Soup', 'Manchow Soup', 'Prawn Chips', 'Crispy Chilli Potato', 'Honey Chilli Potato', 'Peking Duck',
      'Szechuan Chicken', 'Garlic Chicken', 'Chicken Fried Rice', 'Veg Fried Rice', 'Egg Fried Rice', 'Shanghai Noodles', 'Dragon Chicken', 'Chilli Fish', 'Sesame Chicken', 'Fortune Cookies'
    ]
  },
  { 
    name: 'Dosa Corner', cuisine: 'South Indian', img: 'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?w=500&q=80', 
    items: [
      'Masala Dosa', 'Plain Dosa', 'Idli Vada', 'Filter Coffee', 'Uttapam', 'Mysore Masala Dosa', 'Rava Dosa', 'Set Dosa', 'Neer Dosa', 'Onion Dosa',
      'Ghee Roast Dosa', 'Podi Idli', 'Medu Vada', 'Sambar Vada', 'Upma', 'Pongal', 'Bisi Bele Bath', 'Curd Rice', 'Lemon Rice', 'Tomato Rice',
      'Kesari Bath', 'Poori Saagu', 'Rava Idli', 'Maddur Vada', 'Masala Vada', 'Banana Bonda', 'Filter Tea', 'Badam Milk', 'Mango Lassi', 'Payasam'
    ]
  },
  { 
    name: 'Momo Magic', cuisine: 'Tibetan', img: 'https://images.unsplash.com/photo-1625220194771-7ebdea0b70b9?w=500&q=80', 
    items: [
      'Steamed Momos', 'Fried Momos', 'Chicken Momos', 'Cheese Momos', 'Thukpa', 'Veg Pan Fried Momos', 'Chicken Pan Fried Momos', 'Tandoori Momos', 'Chilli Momos', 'Kurkure Momos',
      'Paneer Momos', 'Mushroom Momos', 'Prawn Momos', 'Jhol Momos', 'Kothey Momos', 'Veg Thukpa', 'Chicken Thukpa', 'Chilli Garlic Noodles', 'Chilli Chicken Dry', 'Hakka Noodles',
      'Chicken Steam Momos', 'Veg Steam Momos', 'Cheese Corn Momos', 'Afghani Momos', 'Gravy Momos', 'Chowmein', 'Manchurian', 'Hot & Sour Soup', 'Chicken Soup', 'Veg Clear Soup'
    ]
  },
  { 
    name: 'Tandoori Nights', cuisine: 'Mughlai', img: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=500&q=80', 
    items: [
      'Tandoori Chicken', 'Seekh Kebab', 'Rumali Roti', 'Butter Chicken', 'Lassi', 'Chicken Tikka', 'Malai Tikka', 'Afghani Chicken', 'Mutton Kebab', 'Paneer Tikka',
      'Mushroom Tikka', 'Tandoori Prawns', 'Fish Tikka', 'Chicken Wings', 'Tangdi Kebab', 'Reshmi Kebab', 'Galouti Kebab', 'Mutton Burrah', 'Naan', 'Laccha Paratha',
      'Mutton Korma', 'Chicken Changezi', 'Dal Makhani', 'Shahi Paneer', 'Mutton Biryani', 'Phirni', 'Shahi Tukda', 'Kesar Phirni', 'Masala Lemonade', 'Sweet Lassi'
    ]
  },
  { 
    name: 'Rolls & Wraps', cuisine: 'Street Food', img: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=500&q=80', 
    items: [
      'Egg Roll', 'Chicken Roll', 'Paneer Roll', 'Double Egg Roll', 'Veg Roll', 'Mutton Roll', 'Chicken Tikka Roll', 'Paneer Tikka Roll', 'Aloo Roll', 'Cheese Corn Roll',
      'Peri Peri Chicken Roll', 'Spicy Paneer Roll', 'Tandoori Chicken Roll', 'Mayo Chicken Roll', 'Schezwan Roll', 'Egg Chicken Roll', 'Egg Paneer Roll', 'Veg Cheese Roll', 'Mutton Seekh Roll', 'Fish Roll',
      'Masala Lemonade', 'Cold Coffee', 'Soft Drinks', 'Chicken Lollipop', 'French Fries', 'Chicken Nuggets', 'Momos', 'Chowmein', 'Manchurian', 'Samosa'
    ]
  },
  { 
    name: 'Pav Bhaji Adda', cuisine: 'Maharashtrian', img: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=500&q=80', 
    items: [
      'Butter Pav Bhaji', 'Cheese Pav Bhaji', 'Masala Pav', 'Tawa Pulao', 'Jalebi', 'Khada Pav Bhaji', 'Schezwan Pav Bhaji', 'Paneer Pav Bhaji', 'Mushroom Pav Bhaji', 'Kolhapuri Pav Bhaji',
      'Vada Pav', 'Misal Pav', 'Poha', 'Sabudana Khichdi', 'Kanda Bhaji', 'Thalipeeth', 'Puran Poli', 'Shrikhand', 'Sol Kadhi', 'Batata Vada',
      'Samosa', 'Bhaji', 'Extra Pav', 'Extra Butter', 'Masala Chaas', 'Kokum Sherbet', 'Tea', 'Coffee', 'Dahi Puri', 'Sev Puri'
    ]
  },
  { 
    name: 'Shawarma Nation', cuisine: 'Arabian', img: 'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=500&q=80', 
    items: [
      'Chicken Shawarma', 'Beef Shawarma', 'Falafel', 'Hummus', 'Pita Bread', 'Mutton Shawarma', 'Paneer Shawarma', 'Veg Shawarma', 'Chicken Platter', 'Mutton Platter',
      'Chicken Wings', 'Peri Peri Chicken', 'Garlic Sauce', 'Tahini Sauce', 'Fattoush Salad', 'Tabbouleh', 'Baba Ghanoush', 'Grilled Chicken', 'Chicken Kebab', 'Lamb Kebab',
      'Baklava', 'Kunafa', 'Turkish Coffee', 'Mint Lemonade', 'Arabic Tea', 'Fries', 'Chicken Popcorn', 'Spicy Chicken Shawarma', 'Cheese Shawarma', 'Special Arabian Shawarma'
    ]
  },
  { 
    name: 'Sweet Tooth', cuisine: 'Desserts', img: 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=500&q=80', 
    items: [
      'Chocolate Cake', 'Red Velvet Cake', 'Ice Cream Sundae', 'Waffle', 'Donut', 'Black Forest Cake', 'Cheesecake', 'Brownie', 'Tiramisu', 'Macarons',
      'Cupcakes', 'Pastries', 'Pudding', 'Mousse', 'Tarts', 'Cinnamon Roll', 'Croissant', 'Eclairs', 'Gelato', 'Fruit Custard',
      'Rasmalai', 'Gulab Jamun', 'Jalebi', 'Gajar Ka Halwa', 'Kulfi', 'Chocolate Truffle', 'Pineapple Cake', 'Vanilla Ice Cream', 'Chocolate Ice Cream', 'Strawberry Ice Cream'
    ]
  },
  { 
    name: 'Cafe Coffee Day', cuisine: 'Beverages', img: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=500&q=80', 
    items: [
      'Cappuccino', 'Latte', 'Cold Coffee', 'Espresso', 'Sandwich', 'Americano', 'Mocha', 'Macchiato', 'Flat White', 'Iced Latte',
      'Frappe', 'Hot Chocolate', 'Green Tea', 'Black Tea', 'Lemon Tea', 'Croissant', 'Muffin', 'Cookie', 'Brownie', 'Garlic Bread',
      'Veg Puff', 'Chicken Puff', 'Paneer Wrap', 'Chicken Wrap', 'Pasta', 'French Fries', 'Cheese Toast', 'Club Sandwich', 'Vanilla Milkshake', 'Chocolate Milkshake'
    ]
  },
  { 
    name: 'Healthy Bites', cuisine: 'Salads', img: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&q=80', 
    items: [
      'Caesar Salad', 'Greek Salad', 'Fruit Bowl', 'Quinoa Bowl', 'Smoothie', 'Chicken Salad', 'Tuna Salad', 'Egg Salad', 'Paneer Salad', 'Sprouts Salad',
      'Avocado Salad', 'Beetroot Salad', 'Corn Salad', 'Cucumber Salad', 'Kale Salad', 'Buddha Bowl', 'Hummus Bowl', 'Oats Bowl', 'Chia Pudding', 'Overnight Oats',
      'Vegan Wrap', 'Grilled Chicken Wrap', 'Veggie Sandwich', 'Protein Shake', 'Banana Smoothie', 'Berry Smoothie', 'Green Detox Juice', 'Almond Milk', 'Soy Milk', 'Peanut Butter Toast'
    ]
  },
  { 
    name: 'KFC', cuisine: 'Fast Food', img: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80', 
    items: [
      'Fried Chicken', 'Popcorn Chicken', 'Zinger Burger', 'Hot Wings', 'Pepsi', 'Chicken Bucket', 'Hot & Crispy Chicken', 'Peri Peri Chicken', 'Classic Chicken Burger', 'Veg Zinger Burger',
      'Chicken Roll', 'Veg Roll', 'French Fries', 'Chicken Nuggets', 'Chicken Strips', 'Chicken Rice Bowl', 'Popcorn Rice', 'Choco Pie', 'Choco Lava Cake', 'Mountain Dew',
      '7 Up', 'Mirinda', 'Pepsi Max', 'Lipton Ice Tea', 'Chicken Popcorn Bucket', 'Smoky Grilled Chicken', 'Double Down Burger', 'Korean Tangy Wings', 'Cheesy Fries', 'Chicken Twister'
    ]
  },
  { 
    name: 'Dominos', cuisine: 'Pizza', img: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=500&q=80', 
    items: [
      'Farmhouse Pizza', 'Peppy Paneer', 'Chicken Dominator', 'Stuffed Garlic Bread', 'Choco Lava Cake', 'Margherita Pizza', 'Double Cheese Margherita', 'Veggie Paradise', 'Mexican Green Wave', 'Deluxe Veggie',
      'Chicken Sausage', 'Pepper Barbecue Chicken', 'Chicken Golden Delight', 'Non Veg Supreme', 'Paneer Makhani', 'Cheese n Corn', 'Veg Extravaganza', 'Pasta Italiano', 'Taco Mexicana', 'Chicken Parcel',
      'Chicken Wings', 'Roasted Chicken', 'Garlic Breadsticks', 'Pasta Arrabbiata', 'Cheesy Dip', 'Tandoori Dip', 'Butterscotch Mousse', 'Red Velvet Lava Cake', 'Pepsi', '7 Up'
    ]
  },
  { 
    name: 'Barbeque Nation', cuisine: 'BBQ', img: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&q=80', 
    items: [
      'Grilled Chicken', 'Paneer Tikka', 'BBQ Prawns', 'Mutton Kebab', 'Gulab Jamun', 'Chicken Tikka', 'Tandoori Mushroom', 'Fish Grill', 'Pineapple Grill', 'Cajun Potato',
      'Crispy Corn', 'Chicken Wings', 'Seekh Kebab', 'Grilled Veggies', 'Mutton Curry', 'Chicken Biryani', 'Veg Biryani', 'Dal Makhani', 'Butter Naan', 'Brownie',
      'Ice Cream', 'Fruit Salad', 'Paan Shot', 'Rabri', 'Mutton Rogan Josh', 'Chicken Dum Biryani', 'Paneer Butter Masala', 'Tandoori Roti', 'Raita', 'Gulab Jamun with Rabri'
    ]
  },
  { 
    name: 'Pasta Street', cuisine: 'Continental', img: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=500&q=80', 
    items: [
      'Alfredo Pasta', 'Arrabbiata Pasta', 'Lasagna', 'Mac & Cheese', 'Garlic Bread', 'Pesto Pasta', 'Carbonara Pasta', 'Bolognese Pasta', 'Fusilli Pasta', 'Penne Pasta',
      'Spaghetti Meatballs', 'Ravioli', 'Tortellini', 'Risotto', 'Gnocchi', 'Mushroom Pasta', 'Chicken Pasta', 'Prawn Pasta', 'Caesar Salad', 'Bruschetta',
      'Minestrone Soup', 'Garlic Bread with Cheese', 'Cheesy Fries', 'Mozzarella Sticks', 'Tiramisu', 'Panna Cotta', 'Choco Lava Cake', 'Red Wine (Mocktail)', 'Sparkling Water', 'Lemonade'
    ]
  },
  { 
    name: 'Idli Express', cuisine: 'South Indian', img: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500&q=80', 
    items: [
      'Mini Idli', 'Ghee Podi Idli', 'Sambar Vada', 'Rava Dosa', 'Pongal', 'Idli', 'Plain Dosa', 'Masala Dosa', 'Onion Uttapam', 'Tomato Uttapam',
      'Set Dosa', 'Neer Dosa', 'Mysore Bonda', 'Medu Vada', 'Upma', 'Kesari Bath', 'Curd Rice', 'Lemon Rice', 'Tamarind Rice', 'Bisi Bele Bath',
      'Filter Coffee', 'Filter Tea', 'Badam Milk', 'Buttermilk', 'Rasam', 'Sambar', 'Coconut Chutney', 'Tomato Chutney', 'Peanut Chutney', 'Payasam'
    ]
  },
  { 
    name: 'Fish & Chips', cuisine: 'Seafood', img: 'https://images.unsplash.com/photo-1537200335158-9e11de6e2e86?w=500&q=80', 
    items: [
      'Fried Fish', 'Fish Fingers', 'Prawn Tempura', 'Calamari', 'Tartar Sauce', 'Battered Fish', 'Grilled Fish', 'Fish Tacos', 'Prawn Cocktail', 'Crab Cakes',
      'Lobster Roll', 'Oyster Platter', 'Squid Rings', 'Seafood Platter', 'Salmon Steak', 'Tuna Steak', 'Fish Burger', 'Shrimp Scampi', 'Garlic Butter Prawns', 'Chilli Prawns',
      'French Fries', 'Wedges', 'Onion Rings', 'Coleslaw', 'Garden Salad', 'Lemon Wedges', 'Mushy Peas', 'Tartare Dip', 'Lemonade', 'Cold Beer (Mocktail)'
    ]
  },
  { 
    name: 'Kebab Corner', cuisine: 'North Indian', img: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=500&q=80', 
    items: [
      'Chicken Tikka', 'Malai Kebab', 'Mutton Seekh', 'Paneer Tikka', 'Tandoori Roti', 'Tangdi Kebab', 'Reshmi Kebab', 'Galouti Kebab', 'Mutton Burrah', 'Afghani Chicken',
      'Hariyali Chicken', 'Fish Tikka', 'Mushroom Tikka', 'Soya Chaap', 'Chicken Wings', 'Mutton Chops', 'Prawn Kebab', 'Butter Chicken', 'Rogan Josh', 'Kadai Paneer',
      'Dal Makhani', 'Naan', 'Laccha Paratha', 'Rumali Roti', 'Jeera Rice', 'Mutton Biryani', 'Raita', 'Green Chutney', 'Gulab Jamun', 'Phirni'
    ]
  },
  { 
    name: 'Juice Junction', cuisine: 'Juices', img: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500&q=80', 
    items: [
      'Orange Juice', 'Mango Shake', 'Apple Juice', 'Watermelon Juice', 'Mixed Fruit', 'Pineapple Juice', 'Pomegranate Juice', 'Grape Juice', 'Sugarcane Juice', 'Lemonade',
      'Mosambi Juice', 'Carrot Juice', 'Beetroot Juice', 'Cucumber Juice', 'Lassi', 'Mango Lassi', 'Rose Milk', 'Badam Milk', 'Cold Coffee', 'Chocolate Shake',
      'Strawberry Shake', 'Banana Shake', 'Oreo Shake', 'KitKat Shake', 'Protein Shake', 'Avocado Shake', 'Tender Coconut Water', 'Jaljeera', 'Masala Chaas', 'Fruit Salad'
    ]
  },
  { 
    name: 'Paratha Plaza', cuisine: 'North Indian', img: 'https://images.unsplash.com/photo-1626777553635-4a86b17c4e2c?w=500&q=80', 
    items: [
      'Aloo Paratha', 'Paneer Paratha', 'Gobi Paratha', 'Curd', 'Pickle', 'Onion Paratha', 'Mix Veg Paratha', 'Methi Paratha', 'Mooli Paratha', 'Dal Paratha',
      'Cheese Paratha', 'Egg Paratha', 'Chicken Paratha', 'Keema Paratha', 'Lachha Paratha', 'Pudina Paratha', 'Butter Paratha', 'Tandoori Paratha', 'Malabar Paratha', 'Sweet Paratha',
      'Extra Butter', 'Green Chutney', 'Raita', 'Masala Chaas', 'Lassi', 'Tea', 'Coffee', 'Samosa', 'Gulab Jamun', 'Papad'
    ]
  },
  { 
    name: 'Sizzling Brownie', cuisine: 'Desserts', img: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500&q=80', 
    items: [
      'Sizzling Brownie', 'Hot Chocolate', 'Waffles', 'Pancakes', 'Ice Cream', 'Brownie with Ice Cream', 'Choco Lava Cake', 'Chocolate Truffle', 'Red Velvet Cake', 'Cheesecake',
      'Tiramisu', 'Blueberry Cheesecake', 'Nutella Waffle', 'Belgian Chocolate Waffle', 'Strawberry Waffle', 'Banana Pancakes', 'Chocolate Pancakes', 'Kulfi', 'Rabri', 'Rasmalai',
      'Gulab Jamun', 'Jalebi with Rabri', 'Fruit Custard', 'Mousse', 'Pudding', 'Macarons', 'Cupcakes', 'Donuts', 'Croissants', 'Muffins'
    ]
  },
  { 
    name: 'Noodle Bar', cuisine: 'Asian', img: 'https://images.unsplash.com/photo-1552611052-33e04de081de?w=500&q=80', 
    items: [
      'Pad Thai', 'Ramen', 'Udon Noodles', 'Sushi', 'Dumplings', 'Schezwan Noodles', 'Hakka Noodles', 'Chicken Teriyaki', 'Chicken Katsu', 'Tempura',
      'Miso Soup', 'Tom Yum Soup', 'Sushi Platter', 'California Roll', 'Salmon Nigiri', 'Tuna Sashimi', 'Spring Rolls', 'Vietnamese Pho', 'Korean Fried Chicken', 'Bulgogi',
      'Fried Rice', 'Chilli Garlic Noodles', 'Gyoza', 'Edamame', 'Seaweed Salad', 'Matcha Ice Cream', 'Mochi', 'Green Tea', 'Jasmine Tea', 'Bubble Tea'
    ]
  }
];

async function main() {
  await prisma.deliveryLocationHistory.deleteMany();
  await prisma.deliveryAssignment.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.order.deleteMany();
  await prisma.review.deleteMany();
  await prisma.favorite.deleteMany();
  await prisma.cartItem.deleteMany();
  await prisma.cart.deleteMany();
  await prisma.foodImage.deleteMany();
  await prisma.foodItem.deleteMany();
  await prisma.foodCategory.deleteMany();
  await prisma.restaurant.deleteMany();
  await prisma.coupon.deleteMany();

  console.log("Hale data clean aythu! 🧹");

  const adminPass = await bcrypt.hash('admin123', 10);
  await prisma.user.upsert({
    where: { email: 'admin@food.com' },
    update: {},
    create: { email: 'admin@food.com', passwordHash: adminPass, fullName: 'Admin', role: 'ADMIN' }
  });

  for (let i = 0; i < restaurantsData.length; i++) {
    const rest = restaurantsData[i];
    const lat = 19.0760 + (Math.random() * 0.1 - 0.05);
    const lng = 72.8777 + (Math.random() * 0.1 - 0.05);

    await prisma.restaurant.create({
      data: {
        name: rest.name,
        cuisineType: rest.cuisine,
        imageUrl: rest.img,
        addressLine: `${i + 1} Main Street`,
        city: 'Mumbai',
        latitude: lat,
        longitude: lng,
        categories: {
          create: [
            {
              name: 'Recommended',
              items: {
                create: rest.items.map((itemName, index) => ({
                  name: itemName,
                  price: Math.floor(Math.random() * 300) + 100, // Random price 100-400
                  description: `Delicious ${itemName} prepared with fresh ingredients.`,
                  images: {
                    create: [{ imageUrl: foodImages[index % foodImages.length] }]
                  }
                }))
              }
            }
          ]
        }
      }
    });
  }

  await prisma.coupon.upsert({
    where: { code: 'WELCOME50' },
    update: {},
    create: { code: 'WELCOME50', discountPercent: 10, minOrderAmount: 200, isActive: true }
  });

  console.log('25 Restaurants mattu Prathi ondu 30 different items Database ge hakalagide! 🎉');
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(async () => { await prisma.$disconnect(); });