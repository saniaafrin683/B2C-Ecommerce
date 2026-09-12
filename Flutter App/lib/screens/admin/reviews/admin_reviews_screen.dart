import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../services/admin/admin_review_service.dart';
import '../../../widgets/admin/admin_section_card.dart';
import '../../../widgets/admin/admin_shell.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import '../../../widgets/product_image.dart';
import 'admin_review_details_screen.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  static const routeName = '/admin/reviews';

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  static const _pageSize = 8;

  final _searchController = TextEditingController();
  Future<_ReviewListData>? _request;
  String _statusFilter = 'All';
  int _ratingFilter = 0;
  int _pageIndex = 0;
  final Set<int> _busyIds = {};

  String get _token => context.read<AuthProvider>().token ?? '';
  AdminReviewService get _service => context.read<AdminReviewService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_ReviewListData> _load() async {
    final reviews = await _service.getReviews(_token);
    final summary = AdminReviewSummary.fromReviews(reviews);
    return _ReviewListData(reviews, summary);
  }

  Future<void> _refresh({bool preserveDataOnError = false}) async {
    final previousRequest = _request;
    final request = _load();
    setState(() {
      _request = request;
      _pageIndex = 0;
    });
    try {
      await request;
    } catch (_) {
      if (preserveDataOnError && mounted) {
        setState(() {
          _request = previousRequest;
        });
      }
      rethrow;
    }
  }

  List<AdminReview> _filtered(List<AdminReview> reviews) {
    final query = _searchController.text.trim().toLowerCase();
    return reviews.where((review) {
      final matchesSearch =
          query.isEmpty ||
          [
            review.customerName,
            review.customerEmail,
            review.productName,
            review.reviewTitle,
            review.reviewMessage,
            review.reviewCode,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );

      final matchesStatus =
          _statusFilter == 'All' ||
          review.normalizedStatus == _statusFilter.toLowerCase();

      final matchesRating =
          _ratingFilter == 0 || review.rating == _ratingFilter;

      return matchesSearch && matchesStatus && matchesRating;
    }).toList();
  }

  Future<void> _openDetails(AdminReview review) async {
    final id = review.id;
    if (id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminReviewDetailsScreen(reviewId: id, initialReview: review),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _approve(AdminReview review) async {
    final id = review.id;
    if (id == null) return;
    final confirmed = await _confirmModeration(
      title: 'Approve review?',
      message:
          'Approve ${review.displayTitle} from ${review.displayCustomerName}?',
      confirmText: 'Approve',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busyIds.add(id);
    });
    var succeeded = false;
    try {
      await _service.approveReview(_token, id);
      if (!mounted) return;
      succeeded = true;
      _showMessage('Review approved successfully.');
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to approve review: ${error.toString()}',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(id);
        });
      }
    }
    if (succeeded && mounted) {
      await _refreshAfterMutation('approved');
    }
  }

  Future<void> _reject(AdminReview review) async {
    final id = review.id;
    if (id == null) return;
    final confirmed = await _confirmModeration(
      title: 'Reject review?',
      message:
          'Reject ${review.displayTitle} from ${review.displayCustomerName}?',
      confirmText: 'Reject',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busyIds.add(id);
    });
    var succeeded = false;
    try {
      await _service.rejectReview(_token, id);
      if (!mounted) return;
      succeeded = true;
      _showMessage('Review rejected successfully.');
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to reject review: ${error.toString()}',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(id);
        });
      }
    }
    if (succeeded && mounted) {
      await _refreshAfterMutation('rejected');
    }
  }

  Future<void> _delete(AdminReview review) async {
    final id = review.id;
    if (id == null) return;
    final confirmed = await _confirmModeration(
      title: 'Delete review?',
      message:
          'Delete ${review.displayTitle} from ${review.displayCustomerName}? This cannot be undone.',
      confirmText: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busyIds.add(id);
    });
    var succeeded = false;
    try {
      await _service.deleteReview(_token, id);
      if (!mounted) return;
      succeeded = true;
      _showMessage('Review deleted successfully.');
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to delete review: ${error.toString()}',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(id);
        });
      }
    }
    if (succeeded && mounted) {
      await _refreshAfterMutation('deleted');
    }
  }

  Future<void> _refreshAfterMutation(String action) async {
    try {
      await _refresh(preserveDataOnError: true);
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Review was $action, but the list could not refresh: $error',
          error: true,
        );
      }
    }
  }

  Future<bool?> _confirmModeration({
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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Reviews',
      activeItem: 'Reviews',
      child: FutureBuilder<_ReviewListData>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ReviewError(error: snapshot.error, onRetry: _refresh);
          }

          final data = snapshot.data ?? _ReviewListData.empty;
          final filtered = _filtered(data.reviews);
          final pageItems = _pageItems(filtered);
          final pageCount = filtered.isEmpty
              ? 0
              : (filtered.length / _pageSize).ceil();
          if (_pageIndex >= pageCount && pageCount > 0) {
            final nextIndex = pageCount - 1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _pageIndex = nextIndex;
                });
              }
            });
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewsHeader(
                        total: data.summary.total,
                        onRefresh: _refresh,
                      ),
                      const SizedBox(height: 22),
                      _SummaryGrid(summary: data.summary),
                      const SizedBox(height: 22),
                      _Filters(
                        controller: _searchController,
                        statusFilter: _statusFilter,
                        ratingFilter: _ratingFilter,
                        onChanged: () {
                          if (mounted) {
                            setState(() {
                              _pageIndex = 0;
                            });
                          }
                        },
                        onStatus: (value) {
                          setState(() {
                            _statusFilter = value;
                            _pageIndex = 0;
                          });
                        },
                        onRating: (value) {
                          setState(() {
                            _ratingFilter = value ?? 0;
                            _pageIndex = 0;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _statusFilter = 'All';
                            _ratingFilter = 0;
                            _searchController.clear();
                            _pageIndex = 0;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        _EmptyReviews(
                          hasFilters: _hasFilters,
                          onClear: () {
                            setState(() {
                              _statusFilter = 'All';
                              _ratingFilter = 0;
                              _searchController.clear();
                              _pageIndex = 0;
                            });
                          },
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 1100) {
                              return _ReviewTable(
                                reviews: pageItems,
                                busyIds: _busyIds,
                                onView: _openDetails,
                                onApprove: _approve,
                                onReject: _reject,
                                onDelete: _delete,
                              );
                            }
                            return _ReviewCards(
                              reviews: pageItems,
                              busyIds: _busyIds,
                              onView: _openDetails,
                              onApprove: _approve,
                              onReject: _reject,
                              onDelete: _delete,
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _Pagination(
                          pageIndex: _pageIndex,
                          pageSize: _pageSize,
                          total: filtered.length,
                          onPrevious: _pageIndex <= 0
                              ? null
                              : () => setState(() => _pageIndex -= 1),
                          onNext: (_pageIndex + 1) >= pageCount
                              ? null
                              : () => setState(() => _pageIndex += 1),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<AdminReview> _pageItems(List<AdminReview> reviews) {
    final start = _pageIndex * _pageSize;
    if (start >= reviews.length) return const [];
    final end = (start + _pageSize).clamp(0, reviews.length);
    return reviews.sublist(start, end);
  }

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty ||
      _statusFilter != 'All' ||
      _ratingFilter != 0;
}

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.total, required this.onRefresh});

  final int total;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reviews moderation',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total reviews: $total',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Refresh reviews',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final AdminReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = <AdminStatCard>[
      AdminStatCard(
        label: 'Total Reviews',
        value: '${summary.total}',
        icon: Icons.rate_review_outlined,
        color: const Color(0xFF2563EB),
      ),
      AdminStatCard(
        label: 'Pending',
        value: '${summary.pending}',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF59E0B),
      ),
      AdminStatCard(
        label: 'Approved',
        value: '${summary.approved}',
        icon: Icons.verified_outlined,
        color: const Color(0xFF059669),
      ),
      AdminStatCard(
        label: 'Rejected',
        value: '${summary.rejected}',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
      ),
      AdminStatCard(
        label: 'Average Rating',
        value: summary.averageRating.toStringAsFixed(1),
        icon: Icons.star_rounded,
        color: const Color(0xFFDB2777),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 720
            ? 3
            : 1;
        const gap = 16.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.statusFilter,
    required this.ratingFilter,
    required this.onChanged,
    required this.onStatus,
    required this.onRating,
    required this.onClear,
  });

  final TextEditingController controller;
  final String statusFilter;
  final int ratingFilter;
  final VoidCallback onChanged;
  final ValueChanged<String> onStatus;
  final ValueChanged<int?> onRating;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Search and filters',
      subtitle: 'Find reviews by customer, product, status, or rating',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchWidth = constraints.maxWidth < 340
              ? constraints.maxWidth
              : 340.0;
          final filterWidth = constraints.maxWidth < 180
              ? constraints.maxWidth
              : 180.0;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Search reviews',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: filterWidth,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(statusFilter),
                  initialValue: statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'Approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'Rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) => onStatus(value ?? 'All'),
                ),
              ),
              SizedBox(
                width: filterWidth,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(ratingFilter),
                  initialValue: ratingFilter == 0 ? null : ratingFilter,
                  decoration: const InputDecoration(
                    labelText: 'Rating',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All ratings'),
                    ),
                    ...List.generate(
                      5,
                      (index) => DropdownMenuItem<int?>(
                        value: 5 - index,
                        child: Text('${5 - index} star'),
                      ),
                    ),
                  ],
                  onChanged: (value) => onRating(value ?? 0),
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewTable extends StatelessWidget {
  const _ReviewTable({
    required this.reviews,
    required this.busyIds,
    required this.onView,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final List<AdminReview> reviews;
  final Set<int> busyIds;
  final Future<void> Function(AdminReview review) onView;
  final Future<void> Function(AdminReview review) onApprove;
  final Future<void> Function(AdminReview review) onReject;
  final Future<void> Function(AdminReview review) onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Reviews list',
      subtitle: 'Desktop review moderation table',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 92,
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Review')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: reviews.map((review) {
            final id = review.id;
            final busy = id != null && busyIds.contains(id);
            return DataRow(
              cells: [
                DataCell(_ProductCell(review: review, compact: false)),
                DataCell(_CustomerCell(review: review)),
                DataCell(_RatingCell(rating: review.rating ?? 0)),
                DataCell(_ReviewPreview(review: review)),
                DataCell(_StatusCell(status: review.displayStatus)),
                DataCell(
                  Text(_formatDate(review.reviewDate ?? review.createdAt)),
                ),
                DataCell(
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TextButton(
                        onPressed: busy ? null : () => onView(review),
                        child: const Text('Details'),
                      ),
                      TextButton(
                        onPressed: busy || review.isApproved
                            ? null
                            : () => onApprove(review),
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: busy || review.isRejected
                            ? null
                            : () => onReject(review),
                        child: const Text('Reject'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => onDelete(review),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReviewCards extends StatelessWidget {
  const _ReviewCards({
    required this.reviews,
    required this.busyIds,
    required this.onView,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final List<AdminReview> reviews;
  final Set<int> busyIds;
  final Future<void> Function(AdminReview review) onView;
  final Future<void> Function(AdminReview review) onApprove;
  final Future<void> Function(AdminReview review) onReject;
  final Future<void> Function(AdminReview review) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: reviews.map((review) {
        final id = review.id;
        final busy = id != null && busyIds.contains(id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AdminSectionCard(
            title: review.displayTitle,
            subtitle:
                '${review.displayProductName} • ${review.displayCustomerName}',
            trailing: _StatusCell(status: review.displayStatus),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductImageBox(review: review),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RatingCell(rating: review.rating ?? 0),
                          const SizedBox(height: 8),
                          _ReviewPreview(review: review),
                          const SizedBox(height: 8),
                          Text(
                            'Reviewed on ${_formatDate(review.reviewDate ?? review.createdAt)}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: busy ? null : () => onView(review),
                      child: const Text('Details'),
                    ),
                    OutlinedButton(
                      onPressed: busy || review.isApproved
                          ? null
                          : () => onApprove(review),
                      child: const Text('Approve'),
                    ),
                    OutlinedButton(
                      onPressed: busy || review.isRejected
                          ? null
                          : () => onReject(review),
                      child: const Text('Reject'),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => onDelete(review),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProductCell extends StatelessWidget {
  const _ProductCell({required this.review, required this.compact});

  final AdminReview review;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 220 : 260,
      child: Row(
        children: [
          _ProductImageBox(review: review),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  review.displayProductName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  review.productId == null
                      ? '—'
                      : 'Product #${review.productId}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            review.displayCustomerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            review.customerEmail ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            review.displayBody,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => _ReviewStatusChip(status: status);
}

class _RatingCell extends StatelessWidget {
  const _RatingCell({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < rating;
        return Icon(
          active ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: active ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
        );
      }),
    );
  }
}

class _ProductImageBox extends StatelessWidget {
  const _ProductImageBox({required this.review});

  final AdminReview review;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 70,
        height: 70,
        child: ProductImage(
          imageUrl: review.productImageUrl ?? '',
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'No reviews found',
      subtitle: hasFilters
          ? 'Try removing filters or searching by another product/customer.'
          : 'No review data is available yet.',
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'Nothing matches the current search.'
                : 'The review queue is empty.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (hasFilters)
            FilledButton.tonal(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
        ],
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
            const Text('Unable to load reviews.'),
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

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pageIndex,
    required this.pageSize,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageIndex;
  final int pageSize;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final start = pageIndex * pageSize + 1;
    final end = (start + pageSize - 1).clamp(start, total);
    final pageCount = (total / pageSize).ceil();
    return AdminSectionCard(
      title: 'Pagination',
      subtitle: 'Showing $start-$end of $total reviews',
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Text('Page ${pageIndex + 1} of $pageCount'),
          OutlinedButton(onPressed: onPrevious, child: const Text('Previous')),
          FilledButton.tonal(onPressed: onNext, child: const Text('Next')),
        ],
      ),
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

class _ReviewListData {
  const _ReviewListData(this.reviews, this.summary);

  final List<AdminReview> reviews;
  final AdminReviewSummary summary;

  static const empty = _ReviewListData(
    <AdminReview>[],
    AdminReviewSummary(
      total: 0,
      pending: 0,
      approved: 0,
      rejected: 0,
      averageRating: 0,
    ),
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final monthNames = const [
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
