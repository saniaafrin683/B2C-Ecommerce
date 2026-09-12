import 'package:flutter/material.dart';

import '../../models/customer_order.dart';
import 'my_orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.onlinePaymentStarted,
    required this.onlinePaymentRequested,
    this.paymentError,
  });
  final CustomerOrder order;
  final bool onlinePaymentStarted;
  final bool onlinePaymentRequested;
  final String? paymentError;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDCFCE7),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 52,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Order placed!',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  onlinePaymentStarted
                      ? 'Your order was created and the payment page was opened. Payment status will update after confirmation.'
                      : onlinePaymentRequested
                      ? 'Your order was created, but the payment page was not opened. Keep your order reference for support.'
                      : 'Thank you. Your Cash on Delivery order has been received.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
                ),
                if (paymentError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    paymentError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _SuccessRow(
                        'Order reference',
                        order.reference ?? '#${order.id ?? '—'}',
                      ),
                      _SuccessRow(
                        'Total',
                        '৳${order.total.toStringAsFixed(2)}',
                      ),
                      _SuccessRow('Status', order.orderStatus ?? 'Pending'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('View My Orders'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Continue Shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
