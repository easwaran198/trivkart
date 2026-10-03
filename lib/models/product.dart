import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String price;
  final String rating;
  final String desc;
  final String unit;
  final String imagePath;
  final String description;

  const Product({
    this.id = '1',
    required this.name,
    required this.price,
    required this.rating,
    required this.desc,
    this.unit = 'qty',
    required this.imagePath,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = (json['product_id'] ?? '1').toString();
    final name = json['product_name'] ?? json['₹'] ?? 'Unnamed Product';
    final priceStr = (json['price_per_unit'] ?? '0').toString();
    final price = priceStr.contains('.') ? priceStr.split('.').first : priceStr;
    final rating = (json['rating'] ?? '5.0').toString();
    final qty = (json['qty'] ?? '1').toString();
    final unit = (json['unit'] ?? 'qty').toString();
    final desc = '$qty $unit';
    final description = json['description'] ?? json['decription'] ?? '';
    final imagePath = json['image'] ?? 'assets/images/grocery_collage.png';

    return Product(
      id: id,
      name: name,
      price: price,
      rating: rating,
      desc: desc,
      unit: unit,
      imagePath: imagePath,
      description: description,
    );
  }

  Widget buildImage({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        },
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  static const List<Product> foodProducts = [
    Product(
      name: 'Chicken Burger',
      price: '150',
      rating: '4.5 (21)',
      desc: '1 piece',
      imagePath: 'assets/images/pizza.png',
      description: "Juicy grilled chicken patty topped with fresh lettuce, tomatoes, cheese, and chef's special burger sauce.",
    ),
    Product(
      name: 'Panner Gravy',
      price: '500',
      rating: '4.5 (21)',
      desc: '1 qty.',
      imagePath: 'assets/images/paneer_gravy.png',
      description: "Rich and creamy tomato gravy with grilled paneer cubes and Indian spices.",
    ),
    Product(
      name: 'Spicy Pizza',
      price: '250',
      rating: '4.5 (21)',
      desc: '1 qty',
      imagePath: 'assets/images/pizza.png',
      description: "Freshly baked pizza crust loaded with spicy pepperoni, melted mozzarella cheese, tomatoes, and herbs.",
    ),
    Product(
      name: 'Kesar Pista Ice Cream',
      price: '100',
      rating: '4.5 (21)',
      desc: '1 lit.',
      imagePath: 'assets/images/pista_ice_cream.png',
      description: "Creamy Kesar Pista ice cream made with rich saffron and crunchy pistachios.",
    ),
    Product(
      name: 'Idlly',
      price: '200',
      rating: '4.7 (15)',
      desc: '2 pieces',
      imagePath: 'assets/images/paneer_gravy.png',
      description: "Soft and fluffy steamed rice cakes served with sambar and chutney.",
    ),
    Product(
      name: 'Dosai',
      price: '300',
      rating: '4.8 (34)',
      desc: '1 piece',
      imagePath: 'assets/images/pizza.png',
      description: "Crispy thin rice and lentil crepe served with sambar and multiple chutneys.",
    ),
    Product(
      name: 'Kolambu',
      price: '200',
      rating: '4.4 (18)',
      desc: '1 bowl',
      imagePath: 'assets/images/paneer_gravy.png',
      description: "Traditional spicy and tangy South Indian curry.",
    ),
  ];

  static const List<Product> groceryProducts = [
    Product(
      name: 'SunFlower Oil',
      price: '100',
      rating: '4.5 (21)',
      desc: '1 lit.',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Premium quality refined sunflower oil, rich in Vitamin E, perfect for everyday cooking.",
    ),
    Product(
      name: 'Fresh Apple',
      price: '180',
      rating: '4.8 (52)',
      desc: '1 kg',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Crisp and juicy fresh apples imported from organic orchards.",
    ),
    Product(
      name: 'Milk Packet',
      price: '30',
      rating: '4.6 (40)',
      desc: '500 ml',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Pasteurized double toned fresh milk, high in calcium.",
    ),
    Product(
      name: 'Organic Eggs',
      price: '70',
      rating: '4.7 (28)',
      desc: '6 pcs',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Farm-fresh organic brown eggs, rich in protein.",
    ),
  ];

  static const List<Product> pharmacyProducts = [
    Product(
      name: 'Paracetamol Tablets',
      price: '40',
      rating: '4.9 (95)',
      desc: '10 tabs',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Effective relief from fever, body aches, and mild-to-moderate pain.",
    ),
    Product(
      name: 'Vitamin C Capsules',
      price: '120',
      rating: '4.8 (84)',
      desc: '30 caps',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Immunity booster Vitamin C supplements for daily wellness.",
    ),
    Product(
      name: 'Cough Syrup',
      price: '85',
      rating: '4.7 (62)',
      desc: '100 ml',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Soothing relief from dry cough, throat irritation, and congestion.",
    ),
    Product(
      name: 'First Aid Bandages',
      price: '50',
      rating: '4.6 (38)',
      desc: '20 strips',
      imagePath: 'assets/images/grocery_collage.png',
      description: "Breathable, antiseptic adhesive bandages to protect cuts and wounds.",
    ),
  ];
}
