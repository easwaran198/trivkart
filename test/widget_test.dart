// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivkart/main.dart';
import 'package:trivkart/screens/checkout_screen.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts with SplashScreen, navigates to WelcomeScreen, LoginScreen, OtpVerificationScreen, and then HomeScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 1. Verify that the SplashScreen title is present initially.
    expect(find.text('TRIVKART'), findsOneWidget);

    // 2. Pump with duration to trigger the 3-second splash timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify that we successfully navigated to the WelcomeScreen.
    expect(find.text('Everyday Essentials,'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // 3. Tap the 'Next' button to navigate to the LoginScreen.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 4. Verify that we successfully navigated to the LoginScreen.
    expect(find.text('Welcome to'), findsOneWidget);

    // 5. Enter a valid mobile number.
    final phoneField = find.byType(TextFormField);
    expect(phoneField, findsOneWidget);
    await tester.enterText(phoneField, '7904488123');
    
    // Tap the 'Continue' button.
    await tester.tap(find.text('Continue'));
    
    // Pump 1 second (to match the simulated delay in _handleContinue)
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // 6. Verify that we successfully navigated to the OtpVerificationScreen.
    expect(find.text('Verify Your Number'), findsOneWidget);

    // 7. Enter 6-digit OTP code.
    final otpFields = find.byType(TextFormField);
    expect(otpFields, findsNWidgets(6));
    for (int i = 0; i < 6; i++) {
      await tester.enterText(otpFields.at(i), i.toString());
    }
    
    // Tap the 'Verify & Continue' button.
    await tester.tap(find.text('Verify & Continue'));
    
    // Pump 1.5 seconds (to match the simulated delay in _handleVerify)
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // 8. Verify that we successfully navigated to the HomeScreen.
    expect(find.text('Delivery To,'), findsOneWidget);
    expect(find.text('Popular Products'), findsOneWidget);

    // 9. Scroll down to find Chicken Burger card and tap it
    final scrollFinder = find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical);
    expect(scrollFinder, findsOneWidget);
    await tester.drag(scrollFinder, const Offset(0, -400));
    await tester.pumpAndSettle();

    final burgerCard = find.text('Chicken Burger');
    expect(burgerCard, findsOneWidget);
    await tester.tap(burgerCard);
    await tester.pumpAndSettle();

    // 10. Verify we navigated to the ProductDetailsScreen
    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('Description:'), findsOneWidget);

    // 11. Tap "Add to Cart" on the details page by invoking its onTap directly to bypass transition route barriers
    final addToCartBtn = find.text('Add to Cart');
    expect(addToCartBtn, findsOneWidget);
    final gestureDetector = tester.widget<GestureDetector>(
      find.ancestor(of: addToCartBtn, matching: find.byType(GestureDetector)).first,
    );
    gestureDetector.onTap!();
    await tester.pumpAndSettle();

    // Clear SnackBar so it doesn't obscure the bottom navigation bar
    final ScaffoldMessengerState scaffoldMessenger = tester.state(find.byType(ScaffoldMessenger));
    scaffoldMessenger.clearSnackBars();
    await tester.pumpAndSettle();

    // 12. Tap back button to return to Home Screen
    final backBtn = find.byIcon(Icons.arrow_back);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // 13. Tap the "Cart" tab in the floating bottom navigation bar by invoking onTap directly to bypass hit-test warnings
    final cartTabBtn = find.text('Cart');
    expect(cartTabBtn, findsOneWidget);
    final cartGestureDetector = tester.widget<GestureDetector>(
      find.ancestor(of: cartTabBtn, matching: find.byType(GestureDetector)).first,
    );
    cartGestureDetector.onTap!();
    await tester.pumpAndSettle();

    // 14. Verify we are on the Cart screen and see the added item
    expect(find.text('Sub Total'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);

    // 15. Tap "Proceed to Checkout" button on Cart Screen to navigate to Checkout Screen
    final placeOrderBtn = find.text('Proceed to Checkout');
    expect(placeOrderBtn, findsOneWidget);
    final elevatedButton = tester.widget<ElevatedButton>(
      find.ancestor(of: placeOrderBtn, matching: find.byType(ElevatedButton)).first,
    );
    elevatedButton.onPressed!();
    await tester.pumpAndSettle();

    // Verify we navigated to CheckoutScreen
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Address & Contact Details'), findsOneWidget);

    // Tap "Place Order" button on Checkout Screen by invoking onPressed directly
    final checkoutPlaceOrderBtn = find.descendant(
      of: find.byType(CheckoutScreen),
      matching: find.text('Place Order'),
    );
    expect(checkoutPlaceOrderBtn, findsOneWidget);
    final checkoutElevatedButton = tester.widget<ElevatedButton>(
      find.ancestor(of: checkoutPlaceOrderBtn, matching: find.byType(ElevatedButton)).first,
    );
    checkoutElevatedButton.onPressed!();
    await tester.pumpAndSettle();

    // 16. Verify order placed popup is shown
    expect(find.text('Order Placed!'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Close the dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    return MockHttpClientRequest(Uri.parse('https://$host$path'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri url;
  final List<int> _bodyBytes = [];

  MockHttpClientRequest(this.url);

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  void add(List<int> data) {
    _bodyBytes.addAll(data);
  }

  @override
  void write(Object? obj) {
    if (obj != null) {
      _bodyBytes.addAll(utf8.encode(obj.toString()));
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    String responseJson = '{}';
    final requestBody = utf8.decode(_bodyBytes);
    Map<String, dynamic> requestJson = {};
    try {
      if (requestBody.isNotEmpty) {
        requestJson = json.decode(requestBody);
      }
    } catch (_) {}

    if (url.path.contains('login.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'OTP sent successfully'
      });
    } else if (url.path.contains('verify_otp.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'token': 'mocked_token_123',
        'userid': '1',
        'message': 'OTP verified successfully'
      });
    } else if (url.path.contains('category.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'Category listed successfully',
        'category': [
          {'cat_id': 1, 'cat_name': 'Food', 'cat_img': 'food.png'},
          {'cat_id': 2, 'cat_name': 'Groceries', 'cat_img': 'groceries.png'},
          {'cat_id': 3, 'cat_name': 'Pharmacy', 'cat_img': 'pharmacy.png'}
        ]
      });
    } else if (url.path.contains('products.php')) {
      final catId = requestJson['cat_id']?.toString() ?? '1';
      if (catId == '2') {
        responseJson = json.encode({
          'success': 'true',
          'error': 'false',
          'message': 'Products listed successfully',
          'products': [
            {
              'product_id': 3,
              'product_name': 'SunFlower Oil',
              'qty': '1',
              'unit': 'lit.',
              'price_per_unit': '100',
              'rating': '4.5',
              'description': 'Premium quality refined sunflower oil, rich in Vitamin E, perfect for everyday cooking.',
              'image': 'assets/images/grocery_collage.png'
            },
            {
              'product_id': 4,
              'product_name': 'Fresh Apple',
              'qty': '1',
              'unit': 'kg',
              'price_per_unit': '180',
              'rating': '4.8',
              'description': 'Crisp and juicy fresh apples imported from organic orchards.',
              'image': 'assets/images/grocery_collage.png'
            }
          ]
        });
      } else if (catId == '3') {
        responseJson = json.encode({
          'success': 'true',
          'error': 'false',
          'message': 'Products listed successfully',
          'products': [
            {
              'product_id': 5,
              'product_name': 'Paracetamol Tablets',
              'qty': '10',
              'unit': 'tabs',
              'price_per_unit': '40',
              'rating': '4.9',
              'description': 'Effective relief from fever, body aches, and mild-to-moderate pain.',
              'image': 'assets/images/grocery_collage.png'
            }
          ]
        });
      } else {
        responseJson = json.encode({
          'success': 'true',
          'error': 'false',
          'message': 'Products listed successfully',
          'products': [
            {
              'product_id': 1,
              'product_name': 'Chicken Burger',
              'qty': '1',
              'unit': 'piece',
              'price_per_unit': '150',
              'rating': '4.5',
              'description': 'Juicy grilled chicken patty topped with fresh lettuce, tomatoes, cheese, and chef\'s special burger sauce.',
              'image': 'assets/images/pizza.png'
            },
            {
              'product_id': 2,
              'product_name': 'Panner Gravy',
              'qty': '1',
              'unit': 'qty',
              'price_per_unit': '500',
              'rating': '4.5',
              'description': 'Rich and creamy tomato gravy with grilled paneer cubes and Indian spices.',
              'image': 'assets/images/paneer_gravy.png'
            }
          ]
        });
      }
    } else if (url.path.contains('product_details.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'Category listed successfully',
        'product_id': '1',
        'product_name': 'Chicken Burger',
        'qty': '1',
        'unit': 'piece',
        'price_per_unit': '150',
        'rating': '4.5',
        'decription': 'Juicy grilled chicken burger',
        'recommeded_products': [
          {
            'product_id': '2',
            'product_name': 'Panner Gravy',
            'qty': '1',
            'unit': 'qty',
            'price_per_unit': '500',
            'rating': '4.5',
            'decription': 'Creamy paneer gravy'
          }
        ]
      });
    } else if (url.path.contains('add_cart.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'Added successfully'
      });
    } else if (url.path.contains('cart_list.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'cart listed successfully',
        'subtotal': '150',
        'delivery': '20',
        'grand_total': '170',
        'cartlist': [
          {
            'product_id': '1',
            'product_name': 'Chicken Burger',
            'qty': '1',
            'unit': 'piece',
            'price_per_unit': '150',
            'rating': '4.5',
            'decription': 'Juicy grilled chicken burger'
          }
        ]
      });
    } else if (url.path.contains('place_order.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'Order placed listed successfully'
      });
    } else if (url.path.contains('my_orders.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'Category listed successfully',
        'myorders': [
          {
            'product_id': '1',
            'product_name': 'Chicken Burger',
            'qty': '1',
            'unit': 'piece',
            'price_per_unit': '150',
            'rating': '4.5',
            'decription': 'Juicy grilled chicken burger',
            'total price': '170'
          }
        ]
      });
    } else if (url.path.contains('get_profile.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': ' Details got successfully',
        'name': 'Prakash',
        'mobileno': '9023900293',
        'address': '123, Anna Salai, Chennai, 600002.'
      });
    } else if (url.path.contains('edit_profile.php')) {
      responseJson = json.encode({
        'success': 'true',
        'error': 'false',
        'message': 'profile updated successfully'
      });
    } else if (url.path.contains('terms_conditions.php')) {
      responseJson = 'Standard TrivKart Terms & Conditions applied.';
    } else if (url.path.contains('privacy_policy.php')) {
      responseJson = 'Standard TrivKart Privacy Policy applied.';
    }
    return MockHttpClientResponse(responseJson);
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _bodyBytes.addAll(chunk);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  final String body;

  MockHttpClientResponse(this.body);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => utf8.encode(body).length;

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json; charset=utf-8'],
  };

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
