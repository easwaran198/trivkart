import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../utils/routes.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  final List<OrderModel> orders;

  const OrdersScreen({
    super.key,
    required this.orders,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeTab = 'Ongoing'; // 'Ongoing', 'Completed', 'Cancelled'
  List<OrderModel> _apiOrders = [];
  bool _isLoadingOrders = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchOrders();
  }

  Future<void> _loadTokenAndFetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? 'dc8e45dfcaca89fcdf2da05ed33a09f24f071aaa4468456f44e8b16429cb7fc7';
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOrders = true;
    });

    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/orders/my_orders.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': _token}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 'true' || responseData['success'] == true) {
          final List<dynamic> ordersData = responseData['myorders'] ?? [];
          final List<OrderModel> fetchedOrders = [];

          for (int i = 0; i < ordersData.length; i++) {
            final itemJson = ordersData[i];
            final product = Product.fromJson(itemJson);
            final double totPrice = double.tryParse(itemJson['total price']?.toString() ?? itemJson['price_per_unit']?.toString() ?? '100') ?? 100.0;
            final int qty = int.tryParse(itemJson['qty']?.toString() ?? '1') ?? 1;

            fetchedOrders.add(
              OrderModel(
                orderId: '#TK-${1000 + i + 1}',
                items: {product: qty},
                totalAmount: totPrice,
                status: 'Ongoing',
                address: 'Your Address',
                phoneNumber: 'Your Phone',
                paymentMethod: 'UPI',
                orderDate: DateTime.now(),
              ),
            );
          }

          if (mounted) {
            setState(() {
              _apiOrders = fetchedOrders;
              _isLoadingOrders = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingOrders = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingOrders = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    Navigator.of(context).push(
      createPageRoute(
        OrderDetailsScreen(order: order),
      ),
    );
  }

  Widget _buildTabItem(String tabName) {
    final isActive = _activeTab == tabName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tabName;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0C2440) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          alignment: Alignment.center,
          child: Text(
            tabName,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Total items and dynamic naming calculation
    int totalItemsCount = 0;
    order.items.values.forEach((qty) {
      totalItemsCount += qty;
    });

    final firstProduct = order.items.keys.first;
    final otherItemsCount = totalItemsCount - 1;
    
    final String dynamicTitle = otherItemsCount > 0 
        ? '${firstProduct.name} + $otherItemsCount items' 
        : firstProduct.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          // Blue Shopping Cart Badge top-right
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Color(0xFF1E88E5),
                size: 14,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: firstProduct.buildImage(
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Green Title
                    Text(
                      dynamicTitle,
                      style: const TextStyle(
                        color: Color(0xFF558B2F), // Muted green
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Price
                    Text(
                      '₹ ${order.totalAmount.toStringAsFixed(0)}/-',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Total Qty
                    Text(
                      '$totalItemsCount qty.',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Star Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          firstProduct.rating,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Red Details Button bottom-right
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _showOrderDetails(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = _apiOrders.isNotEmpty ? _apiOrders : widget.orders;
    final filteredOrders = allOrders.where((o) => o.status == _activeTab || (_activeTab == 'Ongoing' && _apiOrders.isNotEmpty)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orange Shopping Bag Icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBE9E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_mall,
                  color: Color(0xFFFA5A00),
                  size: 24,
                ),
              ),
              // Title
              const Text(
                'My Orders',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 32), // spacer balance
            ],
          ),
        ),

        // 2. Tabs Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Container(
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
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                _buildTabItem('Ongoing'),
                _buildTabItem('Completed'),
                _buildTabItem('Cancelled'),
              ],
            ),
          ),
        ),

        // 3. Orders List
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_mall_outlined, color: Colors.grey.shade400, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No $_activeTab Orders',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 100.0),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(filteredOrders[index]);
                  },
                ),
        ),
      ],
    );
  }
}
