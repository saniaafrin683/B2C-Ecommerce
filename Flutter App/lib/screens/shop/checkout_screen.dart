import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth_provider.dart';
import '../../core/cart_provider.dart';
import '../../services/customer_commerce_service.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.shippingCost});
  final double shippingCost;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _address;
  String _paymentMethod = 'Cash on Delivery';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final customer = context.read<AuthProvider>().customer;
    _phone = TextEditingController(text: customer?.phone ?? '');
    _address = TextEditingController(
      text: [
        customer?.address,
        customer?.city,
        customer?.country,
      ].whereType<String>().where((v) => v.trim().isNotEmpty).join(', '),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final customer = auth.customer;
    if (customer == null || cart.isEmpty) {
      _message('Your session or cart is no longer available.', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final service = context.read<CustomerCommerceService>();
      final order = await service.createOrder(
        token: auth.token ?? '',
        customer: customer,
        items: cart.items,
        phone: _phone.text,
        shippingAddress: _address.text,
        paymentMethod: _paymentMethod,
        shippingCost: widget.shippingCost,
        couponCode: cart.coupon?.code,
      );
      String? paymentUrl;
      String? paymentError;
      var paymentStarted = false;
      if (_paymentMethod == 'SSLCommerz' && order.id != null) {
        try {
          paymentUrl = await service.initiatePayment(
            auth.token ?? '',
            order.id!,
          );
          final launched = await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );
          paymentStarted = launched;
          if (!launched) {
            paymentError = 'The payment page could not be opened.';
          }
        } catch (error) {
          paymentError = error.toString();
        }
      }
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            order: order,
            onlinePaymentStarted: paymentStarted,
            onlinePaymentRequested: _paymentMethod == 'SSLCommerz',
            paymentError: paymentError,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) _message(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final customer = context.watch<AuthProvider>().customer;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Details',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: customer?.fullName ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 7
                        ? 'Enter a valid phone number.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _address,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Shipping address',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 8
                        ? 'Enter a complete shipping address.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  RadioGroup<String>(
                    groupValue: _paymentMethod,
                    onChanged: (value) => setState(
                      () => _paymentMethod = value ?? _paymentMethod,
                    ),
                    child: const Column(
                      children: [
                        RadioListTile(
                          value: 'Cash on Delivery',
                          title: Text('Cash on Delivery'),
                          subtitle: Text('Pay when your order arrives'),
                          secondary: Icon(Icons.payments_outlined),
                        ),
                        RadioListTile(
                          value: 'SSLCommerz',
                          title: Text('Online Payment'),
                          subtitle: Text(
                            'Continue through the secure payment gateway',
                          ),
                          secondary: Icon(Icons.credit_card_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _CheckoutRow('Subtotal', cart.subtotal),
                        if (cart.couponDiscount > 0)
                          _CheckoutRow(
                            'Coupon discount',
                            -cart.couponDiscount,
                            green: true,
                          ),
                        _CheckoutRow('Delivery', widget.shippingCost),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Final total',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '৳${cart.totalWithShipping(widget.shippingCost).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _placeOrder,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _submitting ? 'Placing Order…' : 'Place Order',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow(this.label, this.value, {this.green = false});
  final String label;
  final double value;
  final bool green;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Text(
          '${value < 0 ? '-' : ''}৳${value.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: green ? const Color(0xFF059669) : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
