import 'package:flutter/material.dart';

Widget adminInvoiceStatusChip(String? status) {
  final value = (status?.trim().isNotEmpty == true ? status!.trim() : 'Pending');
  final color = switch (value.toLowerCase()) {
    'paid' => const Color(0xFF059669),
    'pending' => const Color(0xFFF59E0B),
    'cancelled' => const Color(0xFFDC2626),
    'refunded' => const Color(0xFF7C3AED),
    _ => const Color(0xFF2563EB),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String adminInvoiceMoney(double value) => '৳${value.toStringAsFixed(2)}';

String adminInvoiceDate(DateTime? value) {
  if (value == null) return '—';
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
