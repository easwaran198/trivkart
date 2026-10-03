import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../utils/routes.dart';
import 'checkout_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final Function(Product) onAddToCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  List<Product> _recommendedProducts = [];
  bool _isLoadingDetails = false;
  bool _isAddedToCart = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchDetails();
  }

  Future<void> _loadTokenAndFetchDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? 'dc8e45dfcaca89fcdf2da05ed33a09f24f071aaa4468456f44e8b16429cb7fc7';
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/products/product_details.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _token,
          'product_id': widget.product.id,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 'true' || responseData['success'] == true) {
          final List<dynamic> recs = responseData['recommeded_products'] ?? [];
          final products = recs.map((p) => Product.fromJson(p)).toList();
          if (mounted) {
            setState(() {
              _recommendedProducts = products;
              _isLoadingDetails = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingDetails = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDetails = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _sendAddToCartApi(Product p, int qty) async {
    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/cart/add_cart.php');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _token,
          'product_id': p.id,
          'qty': qty.toString(),
        }),
      );
    } catch (_) {}
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          createPageRoute(
            ProductDetailsScreen(
              product: product,
              onAddToCart: widget.onAddToCart,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF1E88E5),
                  size: 12,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: product.buildImage(
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Color(0xFF33691E),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '₹ ${product.price}/-',
                            style: const TextStyle(
                              color: Color(0xFF0C2440),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.desc,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                product.rating,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C2440),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 9),
                                SizedBox(width: 2),
                                Text(
                                  'Buy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recommendation products fallback (filtering out current product name)
    final allProducts = [
      const Product(
        name: 'Chicken Burger',
        price: '150',
        rating: '4.5 (21)',
        desc: '1 piece',
        imagePath: 'assets/images/pizza.png',
        description: "Juicy grilled chicken patty topped with fresh lettuce, tomatoes, cheese, and chef's special burger sauce.",
      ),
      const Product(
        name: 'SunFlower Oil',
        price: '100',
        rating: '4.5 (21)',
        desc: '1 lit.',
        imagePath: 'assets/images/grocery_collage.png',
        description: "Premium quality refined sunflower oil, rich in Vitamin E, perfect for healthy and everyday cooking.",
      ),
      const Product(
        name: 'Spicy Pizza',
        price: '200',
        rating: '4.7 (35)',
        desc: '1 slice',
        imagePath: 'assets/images/pizza.png',
        description: "Freshly baked pizza crust loaded with spicy pepperoni, melted mozzarella cheese, tomatoes, and herbs.",
      ),
      const Product(
        name: 'Kesar Pista Ice Cream',
        price: '100',
        rating: '4.5 (21)',
        desc: '1 qty',
        imagePath: 'assets/images/pista_ice_cream.png',
        description: "Creamy Kesar Pista ice cream made with rich saffron and crunchy pistachios for a delightful and refreshing treat.",
      ),
    ];

    final recommendations = allProducts.where((p) => p.name != widget.product.name).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Big Product Image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Container(
                      height: 260,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.product.buildImage(
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // 2. Title & Actions row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              color: Color(0xFFFA5A00), // Bold orange matching mockup
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Shopping Cart Outline Circle
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 20),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Share Outline Circle
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Rating, Price, Delivery & Quantity custom Stepper Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating Row
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.rating,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Price Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹ ${widget.product.price}/-',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.product.desc,
                                  style: const TextStyle(
                                    color: Color(0xFF1E88E5), // Blue qty text
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Delivery Row
                            Row(
                              children: [
                                const Icon(Icons.delivery_dining_rounded, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                    children: [
                                      TextSpan(text: 'Delivery by '),
                                      TextSpan(
                                        text: 'Today (2.00pm)',
                                        style: TextStyle(
                                          color: Color(0xFF4CAF50),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Stepper Container on the right
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA5A00), // Stepper Orange
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Increment (+) on left
                              GestureDetector(
                                onTap: _increment,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, color: Color(0xFFFA5A00), size: 16),
                                  ),
                                ),
                              ),
                              // Value in center
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Decrement (-) on right
                              GestureDetector(
                                onTap: _decrement,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.remove, color: Color(0xFFFA5A00), size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Description Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description:',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Recommendations Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text(
                      'Recommendation Products',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 6. Recommendations Horizontal scroll list
                  SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20.0),
                      itemCount: _recommendedProducts.isNotEmpty ? _recommendedProducts.length : recommendations.length,
                      itemBuilder: (context, index) {
                        final list = _recommendedProducts.isNotEmpty ? _recommendedProducts : recommendations;
                        return _buildProductCard(list[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Floating Bottom Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFA5A00),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFA5A00).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Add to Cart
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAddedToCart = true;
                        });
                        _sendAddToCartApi(widget.product, _quantity);
                        for (int i = 0; i < _quantity; i++) {
                          widget.onAddToCart(widget.product);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.product.name} (x$_quantity) added to cart!'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 54,
                        decoration: BoxDecoration(
                          color: _isAddedToCart ? const Color(0xFFE8F5E9) : Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          border: _isAddedToCart ? Border.all(color: const Color(0xFF4CAF50), width: 2) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isAddedToCart ? Icons.check_circle_rounded : Icons.shopping_cart_rounded,
                              color: _isAddedToCart ? const Color(0xFF2E7D32) : Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isAddedToCart ? 'Added to Cart ✓' : 'Add to Cart',
                              style: TextStyle(
                                color: _isAddedToCart ? const Color(0xFF2E7D32) : Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Buy Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _sendAddToCartApi(widget.product, _quantity);
                        for (int i = 0; i < _quantity; i++) {
                          widget.onAddToCart(widget.product);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Proceeding to buy ${widget.product.name}...'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).push(
                          createPageRoute(
                            CheckoutScreen(
                              cartItems: {widget.product: _quantity},
                              phoneNumber: '9023900293',
                              address: '123, Anna Salai, Chennai, 600002.',
                              onClearCart: () {},
                              onBackToShop: () => Navigator.of(context).pop(),
                              onPlaceOrder: (items, total, address, phone, paymentMethod) {},
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C2440),
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Buy Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
