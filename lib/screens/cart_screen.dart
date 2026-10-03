import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'checkout_screen.dart';
import '../utils/routes.dart';

class CartScreen extends StatefulWidget {
  final Map<Product, int> cartItems;
  final Function(Product) onIncrement;
  final Function(Product) onDecrement;
  final VoidCallback onClearCart;
  final VoidCallback onBackToShop;
  final String phoneNumber;
  final String address;
  final Function(Map<Product, int> items, double total, String address, String phone, String paymentMethod) onPlaceOrder;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClearCart,
    required this.onBackToShop,
    required this.phoneNumber,
    required this.address,
    required this.onPlaceOrder,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _token;
  bool _isLoadingCart = false;
  double? _apiSubtotal;
  double? _apiDelivery;
  double? _apiGrandTotal;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchCart();
  }

  Future<void> _loadTokenAndFetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? 'dc8e45dfcaca89fcdf2da05ed33a09f24f071aaa4468456f44e8b16429cb7fc7';
    _fetchCartList();
  }

  Future<void> _fetchCartList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCart = true;
    });

    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/cart/cart_list.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': _token}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 'true' || responseData['success'] == true) {
          if (mounted) {
            setState(() {
              if (responseData['subtotal'] != null) {
                _apiSubtotal = double.tryParse(responseData['subtotal'].toString());
              }
              if (responseData['delivery'] != null) {
                _apiDelivery = double.tryParse(responseData['delivery'].toString());
              }
              if (responseData['grand_total'] != null) {
                _apiGrandTotal = double.tryParse(responseData['grand_total'].toString());
              }
              _isLoadingCart = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingCart = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCart = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCart = false;
        });
      }
    }
  }

  Future<void> _sendCartUpdate(Product p, int newQty) async {
    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/cart/add_cart.php');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _token,
          'product_id': p.id,
          'qty': newQty.toString(),
        }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values
    double calculatedSubTotal = 0;
    widget.cartItems.forEach((product, quantity) {
      final double price = double.tryParse(product.price) ?? 0;
      calculatedSubTotal += price * quantity;
    });
    const double fallbackDeliveryCharges = 20.0;

    final double subTotal = _apiSubtotal ?? calculatedSubTotal;
    final double deliveryCharges = _apiDelivery ?? (subTotal > 0 ? fallbackDeliveryCharges : 0);
    final double total = _apiGrandTotal ?? (subTotal > 0 ? (subTotal + deliveryCharges) : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orange Shopping Cart Icon
              const Icon(
                Icons.shopping_cart,
                color: Color(0xFFFA5A00),
                size: 26,
              ),
              // Title
              const Text(
                'Cart',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Three Dots Icon
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.black),
                onPressed: () {
                  if (widget.cartItems.isNotEmpty) {
                    widget.onClearCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cart cleared!')),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // 2. Body (List or Empty State)
        Expanded(
          child: widget.cartItems.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.cartItems.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade100,
                        height: 1,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        final product = widget.cartItems.keys.elementAt(index);
                        final quantity = widget.cartItems[product]!;
                        return _buildCartItemCard(context, product, quantity);
                      },
                    ),
                  ),
                ),
        ),

        // 3. Sticky Bottom Footer (Only when cart is not empty)
        if (widget.cartItems.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 110.0), // Spacing for floating navigation bar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Promo Coupon Code Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: Color(0xFFFA5A00), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'TRIVKART50 (50% OFF Applied)',
                          style: TextStyle(
                            color: Color(0xFFFA5A00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFA5A00),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'APPLIED ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bill Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sub Total',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                    Text(
                      '₹${subTotal.toStringAsFixed(0)} /-',
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Charges',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                    Text(
                      '₹${deliveryCharges.toStringAsFixed(0)} /-',
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)} /-',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        createPageRoute(
                          CheckoutScreen(
                            cartItems: widget.cartItems,
                            phoneNumber: widget.phoneNumber,
                            address: widget.address,
                            onClearCart: widget.onClearCart,
                            onBackToShop: widget.onBackToShop,
                            onPlaceOrder: widget.onPlaceOrder,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C2440), // Navy Blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFFFA5A00),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to cart to place your order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onBackToShop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA5A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Shop Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, Product product, int quantity) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.buildImage(
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Center: Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(0xFF33691E), // Dark green text
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Price & unit
                Row(
                  children: [
                    Text(
                      '₹ ${product.price}/-',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.desc,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Rating row
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      product.rating,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Badge & Stepper
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top shopping cart badge
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFF1E88E5),
                  size: 12,
                ),
              ),
              const SizedBox(height: 16),
              // Stepper
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFA5A00), // Stepper Orange
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Increment (+) on left
                    GestureDetector(
                      onTap: () {
                        widget.onIncrement(product);
                        _sendCartUpdate(product, quantity + 1);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Color(0xFFFA5A00), size: 14),
                        ),
                      ),
                    ),
                    // Value in center
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Decrement (-) on right
                    GestureDetector(
                      onTap: () {
                        widget.onDecrement(product);
                        _sendCartUpdate(product, quantity - 1);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(Icons.remove, color: Color(0xFFFA5A00), size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
