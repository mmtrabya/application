// lib/services/paymob_service.dart
// REPLACE lib/services/payment_service.dart with this file

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymobService {
  static final PaymobService _instance = PaymobService._internal();
  factory PaymobService() => _instance;
  PaymobService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create payment order with Paymob
  Future<Map<String, dynamic>> createPaymentOrder({
    required double amount,
    required String currency,
    String? bookingId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymobOrder');

      final result = await callable.call({
        'amount': amount,
        'currency': currency,
        'bookingId': bookingId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error creating payment order: $e');
      throw Exception('Failed to create payment order: $e');
    }
  }

  /// Show Paymob payment page
  Future<bool> showPaymentPage({
    required BuildContext context,
    required String iframeUrl,
  }) async {
    return await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymobPaymentPage(iframeUrl: iframeUrl),
      ),
    ) ?? false;
  }

  /// Process complete payment flow
  Future<bool> processPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    String? bookingId,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create payment order
      final orderData = await createPaymentOrder(
        amount: amount,
        currency: currency,
        bookingId: bookingId,
      );

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show payment page
      final success = await showPaymentPage(
        context: context,
        iframeUrl: orderData['iframeUrl'],
      );

      return success;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Payment error: $e');
      return false;
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      final callable = _functions.httpsCallable('getPaymentStatus');
      final result = await callable.call({'orderId': orderId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return null;
    }
  }

  /// Get user transactions
  Stream<QuerySnapshot> getUserTransactions(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

// ==================== PAYMOB PAYMENT PAGE ====================

class PaymobPaymentPage extends StatefulWidget {
  final String iframeUrl;

  const PaymobPaymentPage({
    Key? key,
    required this.iframeUrl,
  }) : super(key: key);

  @override
  State<PaymobPaymentPage> createState() => _PaymobPaymentPageState();
}

class _PaymobPaymentPageState extends State<PaymobPaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkPaymentStatus(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.iframeUrl));
  }

  void _checkPaymentStatus(String url) {
    debugPrint('Navigation: $url');

    // Check for success/failure in URL
    if (url.contains('success=true') || url.contains('success%3Dtrue')) {
      Navigator.pop(context, true);
    } else if (url.contains('success=false') || url.contains('success%3Dfalse')) {
      Navigator.pop(context, false);
    }
    // You can also check for specific Paymob redirect URLs
    else if (url.contains('payment_success')) {
      Navigator.pop(context, true);
    } else if (url.contains('payment_failed')) {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text('Are you sure you want to cancel this payment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, false); // Close payment page
                    },
                    child: const Text('Yes', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment page...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}