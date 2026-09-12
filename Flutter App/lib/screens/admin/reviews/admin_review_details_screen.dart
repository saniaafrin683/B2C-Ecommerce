import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_review_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/product_image.dart';

class AdminReviewDetailsScreen extends StatefulWidget {
  const AdminReviewDetailsScreen({
    super.key,
    required this.reviewId,
    this.initialReview,
  });

  final int reviewId;
  final AdminReview? initialReview;

  @override
  State<AdminReviewDetailsScreen> createState() =>
      _AdminReviewDetailsScreenState();
}

class _AdminReviewDetailsScreenState extends State<AdminReviewDetailsScreen> {
  AdminReview? _review;
  String? _error;
  bool _loading = true;
  bool _updating = false;
  bool _changed = false;
  bool _loadedOnce = false;

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminReviewService get _service => context.read<AdminReviewService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      if (widget.initialReview != null) {
        _review = widget.initialReview;
        _loading = false;
      }
      _loadReview(showLoading: widget.initialReview == null);
    }
  }

  Future<void> _loadReview({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final review = await _service.getReview(_token, widget.reviewId);
      if (!mounted) return;
      setState(() {
        _review = review;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadReview(showLoading: false);
  }

  Future<void> _approve() async {
    final review = _review;
    if (review == null || review.id == null) return;
    final confirmed = await _confirmAction(
      title: 'Approve review?',
      message:
          'Approve ${review.displayTitle} from ${review.displayCustomerName}?',
      confirmText: 'Approve',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _updating = true;
    });
    try {
      final updated = await _service.approveReview(_token, review.id!);
      if (!mounted) return;
      setState(() {
        _review = updated;
        _updating = false;
        _changed = true;
      });
      _showMessage('Review approved successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updating = false;
      });
      _showMessage(
        'Unable to approve review: ${error.toString()}',
        error: true,
      );
    }
  }

  Future<void> _reject() async {
    final review = _review;
    if (review == null || review.id == null) return;
    final confirmed = await _confirmAction(
      title: 'Reject review?',
      message:
          'Reject ${review.displayTitle} from ${review.displayCustomerName}?',
      confirmText: 'Reject',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _updating = true;
    });
    try {
      final updated = await _service.rejectReview(_token, review.id!);
      if (!mounted) return;
      setState(() {
        _review = updated;
        _updating = false;
        _changed = true;
      });
      _showMessage('Review rejected successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updating = false;
      });
      _showMessage('Unable to reject review: ${error.toString()}', error: true);
    }
  }

  Future<void> _delete() async {
    final review = _review;
    if (review == null || review.id == null) return;
    final confirmed = await _confirmAction(
      title: 'Delete review?',
      message:
          'Delete ${review.displayTitle} from ${review.displayCustomerName}? This cannot be undone.',
      confirmText: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _updating = true;
    });
    try {
      await _service.deleteReview(_token, review.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updating = false;
      });
      _showMessage('Unable to delete review: ${error.toString()}', error: true);
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required bool destructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? const Color(0xFFDC2626) : null,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB91C1C) : null,
        ),
      );
  }

  void _goBack() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Review Details',
      activeItem: 'Reviews',
      child: _loading && _review == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _review == null
          ? _ReviewError(error: _error, onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          review: _review!,
                          updating: _updating,
                          onBack: _goBack,
                          onApprove: _approve,
                          onReject: _reject,
                          onDelete: _delete,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _InlineRefreshError(
                            error: _error!,
                            onRetry: _refresh,
                          ),
                        ],
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1000) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _ReviewSummaryCard(review: _review!),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _ProductCard(review: _review!),
                                        const SizedBox(height: 18),
                                        _CustomerCard(review: _review!),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _ReviewSummaryCard(review: _review!),
                                const SizedBox(height: 18),
                                _ProductCard(review: _review!),
                                const SizedBox(height: 18),
                                _CustomerCard(review: _review!),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _MetadataCard(review: _review!),
                        const SizedBox(height: 18),
                        if (_review!.reviewImageUrls.isNotEmpty) ...[
                          _ReviewImagesCard(review: _review!),
                          const SizedBox(height: 18),
                        ],
                        _ReplyCard(review: _review!),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.review,
    required this.updating,
    required this.onBack,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final AdminReview review;
  final bool updating;
  final VoidCallback onBack;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to reviews',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.displayTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '${review.displayProductName} • ${review.displayCustomerName}',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        FilledButton.tonal(
          onPressed: updating || review.isApproved ? null : onApprove,
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: updating || review.isRejected ? null : onReject,
          child: const Text('Reject'),
        ),
        TextButton(
          onPressed: updating ? null : onDelete,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          child: const Text('Delete'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 12), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

class _InlineRefreshError extends StatelessWidget {
  const _InlineRefreshError({required this.error, required this.onRetry});

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.sync_problem_rounded, color: Color(0xFFB91C1C)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Showing saved data because refresh failed. $error',
                style: const TextStyle(color: Color(0xFF991B1B)),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Full review',
      subtitle: 'Customer rating and feedback',
      trailing: _ReviewStatusChip(status: review.displayStatus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stars(rating: review.rating ?? 0),
              const SizedBox(width: 12),
              Text(
                '${review.rating ?? 0}/5',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.displayTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            review.displayBody,
            style: const TextStyle(height: 1.45, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 14),
          _KeyValueLine(label: 'Review code', value: review.reviewCode),
          const SizedBox(height: 8),
          _KeyValueLine(
            label: 'Review date',
            value: _formatDate(review.reviewDate ?? review.createdAt),
          ),
          const SizedBox(height: 8),
          _KeyValueLine(label: 'Updated', value: _formatDate(review.updatedAt)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Product information',
      subtitle: 'Product linked to this review',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProductImage(
                imageUrl: review.productImageUrl ?? '',
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.displayProductName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                _KeyValueLine(
                  label: 'Product ID',
                  value: review.productId?.toString(),
                ),
                const SizedBox(height: 8),
                _KeyValueLine(
                  label: 'Order ID',
                  value: review.orderId?.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Customer information',
      subtitle: 'Customer who submitted the review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KeyValueLine(
            label: 'Customer name',
            value: review.displayCustomerName,
          ),
          const SizedBox(height: 8),
          _KeyValueLine(label: 'Email', value: review.customerEmail),
          const SizedBox(height: 8),
          _KeyValueLine(
            label: 'Customer ID',
            value: review.customerId?.toString(),
          ),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Metadata',
      subtitle: 'Operational details for moderation',
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        children: [
          _MetaPill(label: 'Review status', value: review.displayStatus),
          _MetaPill(label: 'Created', value: _formatDate(review.createdAt)),
          _MetaPill(label: 'Updated', value: _formatDate(review.updatedAt)),
          _MetaPill(label: 'Review ID', value: review.id?.toString()),
          _MetaPill(label: 'Order ID', value: review.orderId?.toString()),
        ],
      ),
    );
  }
}

class _ReviewImagesCard extends StatelessWidget {
  const _ReviewImagesCard({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Review images',
      subtitle: 'Images attached to the review, if any',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 4 : 2;
          final itemWidth =
              (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: review.reviewImageUrls
                .map(
                  (url) => SizedBox(
                    width: itemWidth,
                    height: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ProductImage(
                        imageUrl: url,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Admin reply',
      subtitle: 'Current moderation reply, if available',
      child: Text(
        review.displayReply,
        style: const TextStyle(height: 1.45, color: Color(0xFF334155)),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim().isNotEmpty == true ? value! : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim().isNotEmpty == true ? value! : '—';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < rating;
        return Icon(
          active ? Icons.star_rounded : Icons.star_border_rounded,
          size: 20,
          color: active ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
        );
      }),
    );
  }
}

class _ReviewStatusChip extends StatelessWidget {
  const _ReviewStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'approved' => const Color(0xFF059669),
      'rejected' => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            const Text('Unable to load review details.'),
            const SizedBox(height: 5),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = monthNames[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}
