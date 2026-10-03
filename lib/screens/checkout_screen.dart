import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<Product, int> cartItems;
  final String phoneNumber;
  final String address;
  final VoidCallback onClearCart;
  final VoidCallback onBackToShop;
  final Function(Map<Product, int> items, double total, String address, String phone, String paymentMethod) onPlaceOrder;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.phoneNumber,
    required this.address,
    required this.onClearCart,
    required this.onBackToShop,
    required this.onPlaceOrder,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late String _phone;
  late String _address;
  String _paymentOption = 'UPI'; // Default active option is UPI
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    _phone = widget.phoneNumber;
    _address = widget.address;
  }

  void _editAddress() {
    final controller = TextEditingController(text: _address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your full address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _address = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA5A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPhone() {
    final controller = TextEditingController(text: _phone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter phone number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _phone = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA5A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_isSubmittingOrder) return;
    setState(() {
      _isSubmittingOrder = true;
    });

    double subTotal = 0;
    widget.cartItems.forEach((product, quantity) {
      final double price = double.tryParse(product.price) ?? 0;
      subTotal += price * quantity;
    });
    double total = subTotal + 20;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? 'dc8e45dfcaca89fcdf2da05ed33a09f24f071aaa4468456f44e8b16429cb7fc7';

      final cartListPayload = widget.cartItems.entries.map((e) => {
        'product_id': e.key.id,
        'product_name': e.key.name,
        'qty': e.value.toString(),
        'unit': e.key.unit,
        'price_per_unit': e.key.price,
        'rating': e.key.rating,
        'decription': e.key.description,
      }).toList();

      final url = Uri.parse('https://ttbilling.in/trivkart/api/orders/place_order.php');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'cartlist': cartListPayload,
          'delivery_type': _paymentOption,
          'address': _address,
          'mobileno': _phone,
        }),
      );
    } catch (_) {}

    widget.onPlaceOrder(widget.cartItems, total, _address, _phone, _paymentOption);
    widget.onClearCart();

    if (!mounted) return;
    setState(() {
      _isSubmittingOrder = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Order Placed!'),
        content: const Text('Your order has been placed successfully. Thank you for shopping with TRIVKART!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Pop dialog
              Navigator.of(context).pop(); // Pop CheckoutScreen back to Home
              widget.onBackToShop();       // Switch tab back to Shop/Home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, int quantity) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 14.0, bottom: 8.0, top: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Blue Shopping Cart Badge top-right
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Color(0xFF1E88E5),
                size: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.buildImage(
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Green Title
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Color(0xFF558B2F), // Muted green matching mockup
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Price & Quantity
                      Row(
                        children: [
                          Text(
                            '₹ ${product.price}/-',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$quantity qty.',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            product.rating,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Delivery info
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining_rounded, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                children: [
                                  const TextSpan(text: 'Delivery by '),
                                  TextSpan(
                                    text: 'Today (2.00pm)',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFFFA5A00), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _address,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _editAddress,
            child: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Left +91 block
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              children: [
                const Icon(Icons.phone_iphone_rounded, color: Color(0xFFFA5A00), size: 16),
                const SizedBox(width: 4),
                const Text(
                  '+91',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _phone,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: _editPhone,
            child: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String key, String title, String subtitle, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentOption = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C2440) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C2440) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.15) : const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFA5A00) : const Color(0xFFFA5A00),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Radio Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFA5A00) : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFFA5A00) : Colors.transparent,
              ),
              padding: const EdgeInsets.all(3),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values
    double subTotal = 0;
    widget.cartItems.forEach((product, quantity) {
      final double price = double.tryParse(product.price) ?? 0;
      subTotal += price * quantity;
    });
    const double deliveryCharges = 20.0;
    final double total = subTotal > 0 ? (subTotal + deliveryCharges) : 0;

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
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // 1. Horizontally scrollable product cards
                  SizedBox(
                    height: 125,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final product = widget.cartItems.keys.elementAt(index);
                        final qty = widget.cartItems[product]!;
                        return _buildProductCard(product, qty);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Address & Contact Details Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Address & Contact Details',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildAddressBox(),
                  ),
                  const SizedBox(height: 12),

                  // Phone Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildPhoneBox(),
                  ),
                  const SizedBox(height: 24),

                  // 3. Payment Option Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'payment Option',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        _buildPaymentOption('UPI', 'UPI Payment', 'Google Pay, PhonePe, Paytm', Icons.account_balance_wallet_outlined, _paymentOption == 'UPI'),
                        _buildPaymentOption('COD', 'Cash on Delivery', 'Pay when item arrives at doorstep', Icons.payments_outlined, _paymentOption == 'COD'),
                        _buildPaymentOption('CARD', 'Credit / Debit Card', 'Visa, Mastercard, RuPay', Icons.credit_card_outlined, _paymentOption == 'CARD'),
                        _buildPaymentOption('NET_BANKING', 'Net Banking', 'All major Indian banks supported', Icons.account_balance_outlined, _paymentOption == 'NET_BANKING'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Calculations section + Place Order orange button
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
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 34.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA5A00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
