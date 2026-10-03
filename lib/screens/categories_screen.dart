import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'product_details_screen.dart';
import '../utils/routes.dart';

class CategoriesScreen extends StatefulWidget {
  final int selectedCategoryIndex;
  final ValueChanged<int> onCategoryChanged;
  final Function(Product) onAddToCart;

  const CategoriesScreen({
    super.key,
    required this.selectedCategoryIndex,
    required this.onCategoryChanged,
    required this.onAddToCart,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _apiCategories = [];
  bool _isLoadingCategories = false;
  List<Product> _apiProducts = [];
  bool _isLoadingProducts = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryIndex != widget.selectedCategoryIndex) {
      if (_apiCategories.isNotEmpty && widget.selectedCategoryIndex < _apiCategories.length) {
        _fetchProductsForCategory(_apiCategories[widget.selectedCategoryIndex]['cat_id'].toString());
      }
    }
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
            if (_apiCategories.isNotEmpty && widget.selectedCategoryIndex < _apiCategories.length) {
              _fetchProductsForCategory(_apiCategories[widget.selectedCategoryIndex]['cat_id'].toString());
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

  Widget _buildCategoriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Orange Apps Grid Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apps_rounded,
              color: Color(0xFFFA5A00),
              size: 24,
            ),
          ),
          // Title
          const Text(
            'Categories',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Search Icon
          Container(
            padding: const EdgeInsets.all(8),
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
            child: const Icon(
              Icons.search_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSelectorRow() {
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
          final catName = category['cat_name']?.toString() ?? '';
          final catNameLower = catName.toLowerCase();
          final catId = category['cat_id'].toString();

          Color activeBgColor = const Color(0xFFFF0000);
          String assetImage = 'assets/images/cat_food.png';
          if (catNameLower.contains('grocer')) {
            activeBgColor = const Color(0xFF4CAF50);
            assetImage = 'assets/images/cat_groceries.png';
          } else if (catNameLower.contains('pharm') || catNameLower.contains('medi')) {
            activeBgColor = const Color(0xFF1E88E5);
            assetImage = 'assets/images/cat_pharmacy.png';
          }

          return _buildCategorySelectionCapsule(
            index: index,
            title: catName,
            activeBgColor: activeBgColor,
            imagePath: assetImage,
            catId: catId,
          );
        }),
      ),
    );
  }

  Widget _buildCategorySelectionCapsule({
    required int index,
    required String title,
    required Color activeBgColor,
    required String imagePath,
    required String catId,
  }) {
    final isActive = widget.selectedCategoryIndex == index;
    return GestureDetector(
      onTap: () {
        widget.onCategoryChanged(index);
        _fetchProductsForCategory(catId);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(26),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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
            // Shopping cart badge in corner
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
                          GestureDetector(
                            onTap: () {
                              widget.onAddToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added to cart!'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF4CAF50),
                                ),
                              );
                            },
                            child: Container(
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
    if (_isLoadingProducts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoriesHeader(),
          _buildCategoriesSelectorRow(),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFA5A00),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoriesHeader(),
        _buildCategoriesSelectorRow(),
        Expanded(
          child: _apiProducts.isEmpty
              ? const Center(child: Text('No products found'))
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 100.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _apiProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_apiProducts[index]);
                  },
                ),
        ),
      ],
    );
  }
}
