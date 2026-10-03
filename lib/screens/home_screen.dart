import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'product_details_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import '../utils/routes.dart';
import 'profile_screen.dart';
import '../models/order.dart';
import 'orders_screen.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;

  const HomeScreen({
    super.key,
    this.phoneNumber = '7904488781',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _userName;
  late String _userPhone;
  late String _userAddress;
  String? _userProfileBase64;
  final List<OrderModel> _orders = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchEmpty = true;
  int _activeNavIndex = 0;
  int _selectedCategoryIndex = 0; // 0: Food, 1: Groceries, 2: Pharmacy

  List<dynamic> _apiCategories = [];
  bool _isLoadingCategories = false;
  List<Product> _apiProducts = [];
  bool _isLoadingProducts = false;
  String? _token;

  // Local Cart State
  final Map<Product, int> _cart = {};

  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product)) {
        _cart[product] = _cart[product]! + 1;
      } else {
        _cart[product] = 1;
      }
    });
  }

  void _decrementCart(Product product) {
    setState(() {
      if (_cart.containsKey(product)) {
        if (_cart[product]! > 1) {
          _cart[product] = _cart[product]! - 1;
        } else {
          _cart.remove(product);
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  void _handlePlaceOrder(Map<Product, int> items, double total, String address, String phone, String paymentMethod) {
    setState(() {
      _orders.insert(0, OrderModel(
        orderId: '#TK-${1004 + _orders.length}',
        items: Map.from(items),
        totalAmount: total,
        address: address,
        phoneNumber: phone,
        paymentMethod: paymentMethod,
        status: 'Ongoing',
        orderDate: DateTime.now(),
      ));
    });
  }

  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _sliderTimer;
  final List<String> _banners = [
    'assets/images/banner_burger.png',
    'assets/images/banner_grocery.png',
  ];

  @override
  void initState() {
    super.initState();
    _userName = 'Prakash';
    _userPhone = widget.phoneNumber;
    _userAddress = '123, Anna Salai, Chennai, 600002.';
    _loadTokenAndFetchData();

    // Pre-populate mock orders matching mockup details
    _orders.addAll([
      OrderModel(
        orderId: '#TK-1001',
        items: {
          Product.foodProducts.firstWhere((p) => p.name == 'Panner Gravy'): 1,
          Product.foodProducts.firstWhere((p) => p.name == 'Idlly'): 1,
          Product.foodProducts.firstWhere((p) => p.name == 'Dosai'): 1,
          Product.foodProducts.firstWhere((p) => p.name == 'Kolambu'): 1,
        },
        totalAmount: 1000.0,
        address: _userAddress,
        phoneNumber: _userPhone,
        paymentMethod: 'UPI',
        status: 'Ongoing',
        orderDate: DateTime.now(),
      ),
      OrderModel(
        orderId: '#TK-1002',
        items: {
          Product.foodProducts.firstWhere((p) => p.name == 'Kesar Pista Ice Cream'): 1,
        },
        totalAmount: 160.0,
        address: _userAddress,
        phoneNumber: _userPhone,
        paymentMethod: 'UPI',
        status: 'Completed',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OrderModel(
        orderId: '#TK-1003',
        items: {
          Product.foodProducts.firstWhere((p) => p.name == 'Spicy Pizza'): 1,
        },
        totalAmount: 250.0,
        address: _userAddress,
        phoneNumber: _userPhone,
        paymentMethod: 'COD',
        status: 'Cancelled',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
    
    _searchController.addListener(() {
      setState(() {
        _isSearchEmpty = _searchController.text.isEmpty;
      });
    });

    // Auto slide banners every 4 seconds (skip in widget tests to prevent clock tick conflicts)
    if (!isFlutterTest) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          final nextIndex = (_currentBannerIndex + 1) % _banners.length;
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: [
          // Orange Location Pin Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFFA5A00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Location text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery To,',
                  style: TextStyle(
                    color: Color(0xFF0C2440),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '123, Anna Salai, Chennai, 600002.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification Bell Icon with shadow
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFA5A00)),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          // Cart Icon with shadow & dynamic badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF0C2440)),
                  onPressed: () {
                    setState(() {
                      _activeNavIndex = 2;
                    });
                  },
                ),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFA5A00),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cart.values.fold(0, (sum, count) => sum + count)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0C2440), size: 22),
                suffixIcon: const Icon(Icons.mic_none_rounded, color: Color(0xFF0C2440), size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0C2440),
              ),
            ),
            // Multi-colored hint text overlapping when search text is empty
            if (_isSearchEmpty)
              Positioned(
                left: 48,
                child: Row(
                  children: [
                    const Text(
                      'Food',
                      style: TextStyle(
                        color: Color(0xFFFF2E2E), // Red for Food
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ', ',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.3),
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Grocery',
                      style: TextStyle(
                        color: Color(0xFF4CAF50), // Green for Grocery
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ', ',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.3),
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Pharmacy,..',
                      style: TextStyle(
                        color: Color(0xFF1E88E5), // Blue for Pharmacy
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? 'dc8e45dfcaca89fcdf2da05ed33a09f24f071aaa4468456f44e8b16429cb7fc7';
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/category/category.php');
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
              _apiCategories = responseData['category'] ?? [];
              _isLoadingCategories = false;
            });
            if (_apiCategories.isNotEmpty) {
              _fetchProductsForCategory(_apiCategories[_selectedCategoryIndex]['cat_id'].toString());
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingCategories = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchProductsForCategory(String catId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/products/products.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _token,
          'cat_id': catId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 'true' || responseData['success'] == true) {
          final List<dynamic> productsList = responseData['products'] ?? [];
          final products = productsList.map((p) => Product.fromJson(p)).toList();
          if (mounted) {
            setState(() {
              _apiProducts = products;
              _isLoadingProducts = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _apiProducts = [];
              _isLoadingProducts = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _apiProducts = [];
            _isLoadingProducts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiProducts = [];
          _isLoadingProducts = false;
        });
      }
    }
  }

  Widget _buildCategoryRow() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Color(0xFFFA5A00),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_apiCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        children: List.generate(_apiCategories.length, (index) {
          final category = _apiCategories[index];
          final catName = category['cat_name']?.toString().toLowerCase() ?? '';
          final catTitle = category['cat_name']?.toString() ?? 'Category';
          final catId = category['cat_id'].toString();
          
          String assetImage = 'assets/images/cat_food.png';
          Color activeColor = const Color(0xFFFA5A00);
          if (catName.contains('grocer')) {
            assetImage = 'assets/images/cat_groceries.png';
            activeColor = const Color(0xFF4CAF50);
          } else if (catName.contains('pharm') || catName.contains('medi')) {
            assetImage = 'assets/images/cat_pharmacy.png';
            activeColor = const Color(0xFF1E88E5);
          }

          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
              _fetchProductsForCategory(catId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        assetImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    catTitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          // Banner Slider (PageView)
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      _banners[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Carousel Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              final isActive = _currentBannerIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFA5A00) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          createPageRoute(
            ProductDetailsScreen(
              product: product,
              onAddToCart: _addToCart,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image occupying top portion of the card
                SizedBox(
                  height: 105,
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
                // Rest of details padded
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Color(0xFF33691E), // Dark green text
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Price & Quantity
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          // Buy pill button
                          GestureDetector(
                            onTap: () {
                              _addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added to cart!'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'VIEW CART',
                                    textColor: Colors.amber,
                                    onPressed: () {
                                      setState(() {
                                        _activeNavIndex = 2;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _cart.containsKey(product) ? const Color(0xFF4CAF50) : const Color(0xFFFA5A00),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _cart.containsKey(product) ? Icons.check : Icons.shopping_bag_outlined,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _cart.containsKey(product) ? 'Added' : 'Buy',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
            // Shopping cart badge in top-right corner
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0C2440),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Icon(
            Icons.arrow_forward,
            color: Color(0xFF0C2440),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreenBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Spacing for floating navigation bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryRow(),
          _buildPromoBanner(),
          
          // 1. Dynamic Active Category Products Section
          _buildSectionHeader('Popular Products'),
          _isLoadingProducts
              ? const SizedBox(
                  height: 215,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFA5A00),
                    ),
                  ),
                )
              : _apiProducts.isEmpty
                  ? const SizedBox(
                      height: 215,
                      child: Center(child: Text('No products found')),
                    )
                  : SizedBox(
                      height: 215,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20.0),
                        itemCount: _apiProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_apiProducts[index]);
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC), // Soft off-white
      body: SafeArea(
        child: Stack(
          children: [
            // Dynamic body based on bottom navigation index
            Positioned.fill(
              child: _activeNavIndex == 0
                  ? _buildHomeScreenBody()
                  : _activeNavIndex == 1
                      ? CategoriesScreen(
                          selectedCategoryIndex: _selectedCategoryIndex,
                          onCategoryChanged: (index) {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                            if (_apiCategories.length > index) {
                              _fetchProductsForCategory(_apiCategories[index]['cat_id'].toString());
                            }
                          },
                          onAddToCart: _addToCart,
                        )
                      : _activeNavIndex == 2
                          ? CartScreen(
                              cartItems: _cart,
                              onIncrement: _addToCart,
                              onDecrement: _decrementCart,
                              onClearCart: _clearCart,
                              phoneNumber: _userPhone,
                              address: _userAddress,
                              onPlaceOrder: _handlePlaceOrder,
                              onBackToShop: () {
                                setState(() {
                                  _activeNavIndex = 0;
                                });
                              },
                            )
                           : _activeNavIndex == 3
                              ? OrdersScreen(orders: _orders)
                              : ProfileScreen(
                                  name: _userName,
                                  phoneNumber: _userPhone,
                                  address: _userAddress,
                                  imageBase64: _userProfileBase64,
                                  onNameChanged: (newName) {
                                    setState(() {
                                      _userName = newName;
                                    });
                                  },
                                  onPhoneChanged: (newPhone) {
                                    setState(() {
                                      _userPhone = newPhone;
                                    });
                                  },
                                  onAddressChanged: (newAddress) {
                                    setState(() {
                                      _userAddress = newAddress;
                                    });
                                  },
                                  onImageChanged: (newBase64) {
                                    setState(() {
                                      _userProfileBase64 = newBase64;
                                    });
                                  },
                                ),
            ),

            // Floating Navigation Bar overlay
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFA5A00), // Vibrant orange matching theme
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA5A00).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.grid_view_rounded, 'Categories'),
                    _buildNavItem(2, Icons.shopping_cart_rounded, 'Cart'),
                    _buildNavItem(3, Icons.receipt_long_rounded, 'Orders'),
                    _buildNavItem(4, Icons.person_rounded, 'Profile'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _activeNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
