import 'product.dart';

class OrderModel {
  final String orderId;
  final Map<Product, int> items;
  final double totalAmount;
  final String address;
  final String phoneNumber;
  final String paymentMethod;
  final String status; // 'Ongoing', 'Completed', 'Cancelled'
  final DateTime orderDate;

  OrderModel({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.status,
    required this.orderDate,
  });
}
