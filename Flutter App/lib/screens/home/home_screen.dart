import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../core/cart_provider.dart';
import '../../core/wishlist_provider.dart';
import '../../models/category.dart';
import '../../models/customer_profile.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../widgets/category_image.dart';
import '../../widgets/product_image.dart';
import '../auth/login_screen.dart';
import '../catalog/product_list_screen.dart';
import '../shop/cart_screen.dart';
import '../shop/product_details_screen.dart';
import '../shop/wishlist_screen.dart';
import '../shop/my_orders_screen.dart';
import '../shop/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  late Future<List<Category>> _categoriesFuture = Future.value(
    _fallbackCategories,
  );
  late Future<List<Product>> _hotDealsFuture = Future.value(const <Product>[]);
  late Future<List<Product>> _featuredProductsFuture = Future.value(
    const <Product>[],
  );
  late Future<List<Product>> _recommendedProductsFuture = Future.value(
    const <Product>[],
  );
  late final Timer _bannerTimer;
  bool _catalogLoaded = false;
  int _selectedTab = 0;
  int _bannerIndex = 0;

  CatalogService get _catalogService => context.read<CatalogService>();

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _advanceBanner(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_catalogLoaded) {
      return;
    }
    _catalogLoaded = true;
    _loadCatalogFutures();
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _advanceBanner() {
    if (!mounted) {
      return;
    }
    if (!_bannerController.hasClients) {
      return;
    }
    final nextPage = (_bannerIndex + 1) % _banners.length;
    _bannerController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    setState(() {
      _bannerIndex = nextPage;
    });
  }

  void _onBannerChanged(int index) {
    setState(() {
      _bannerIndex = index;
    });
  }

  void _loadCatalogFutures() {
    _categoriesFuture = _loadCategories();
    _hotDealsFuture = _loadHotDeals();
    _featuredProductsFuture = _loadFeaturedProducts();
    _recommendedProductsFuture = _loadRecommendedProducts();
  }

  Future<List<Category>> _loadCategories() {
    return _catalogService.getCategories();
  }

  Future<List<Product>> _loadHotDeals() async {
    final page = await _catalogService.getProductsPage(
      page: 0,
      size: 24,
      sortBy: 'id',
      sortDir: 'desc',
    );

    final discounted = page.content
        .where((product) => (product.discount ?? 0) > 0)
        .toList(growable: false);
    if (discounted.isNotEmpty) {
      return discounted;
    }

    final candidates = <Product>[];
    for (final tag in ['hot deal', 'hot', 'deal']) {
      try {
        final response = await _catalogService.searchProducts(
          tag: tag,
          page: 0,
          size: 12,
          sortBy: 'id',
          sortDir: 'desc',
        );
        for (final product in response.content) {
          if (candidates.any(
            (existing) => existing.id != null && existing.id == product.id,
          )) {
            continue;
          }
          candidates.add(product);
        }
      } catch (_) {
        continue;
      }
    }
    return candidates;
  }

  Future<List<Product>> _loadFeaturedProducts() async {
    final page = await _catalogService.getProductsPage(
      page: 0,
      size: 8,
      sortBy: 'id',
      sortDir: 'desc',
    );
    return page.content;
  }

  Future<List<Product>> _loadRecommendedProducts() async {
    try {
      final page = await _catalogService.getProductsPage(
        page: 0,
        size: 8,
        sortBy: 'createdAt',
        sortDir: 'desc',
      );
      return page.content;
    } catch (_) {
      final fallback = await _catalogService.getProductsPage(
        page: 0,
        size: 8,
        sortBy: 'id',
        sortDir: 'desc',
      );
      return fallback.content;
    }
  }

  void _retryCategories() {
    setState(() {
      _categoriesFuture = _loadCategories();
    });
  }

  void _retryHotDeals() {
    setState(() {
      _hotDealsFuture = _loadHotDeals();
    });
  }

  void _retryFeatured() {
    setState(() {
      _featuredProductsFuture = _loadFeaturedProducts();
    });
  }

  void _retryRecommended() {
    setState(() {
      _recommendedProductsFuture = _loadRecommendedProducts();
    });
  }

  void _openSearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductListScreen(initialQuery: query.isEmpty ? null : query),
      ),
    );
  }

  void _openCategory(Category category) {
    final categoryTitle = category.categoryTitle?.trim();
    if (categoryTitle == null || categoryTitle.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductListScreen(initialCategory: categoryTitle),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _openCart() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final customer = authProvider.customer;
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _HomeTab(
            searchController: _searchController,
            bannerController: _bannerController,
            bannerIndex: _bannerIndex,
            categoriesFuture: _categoriesFuture,
            hotDealsFuture: _hotDealsFuture,
            featuredProductsFuture: _featuredProductsFuture,
            recommendedProductsFuture: _recommendedProductsFuture,
            onBannerChanged: _onBannerChanged,
            onSearch: _openSearch,
            onCategoryTap: _openCategory,
            onProductTap: _openProduct,
            onWishlistTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
            onOrdersTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
            onCartTap: _openCart,
            cartCount: cartCount,
            onCategoriesRetry: _retryCategories,
            onHotDealsRetry: _retryHotDeals,
            onFeaturedRetry: _retryFeatured,
            onRecommendedRetry: _retryRecommended,
          ),
          _BrandsTab(onSearchTap: _openSearch, onBrandTap: _openSearch),
          _CategoriesTab(
            categoriesFuture: _categoriesFuture,
            onCategoryTap: _openCategory,
            onSearchTap: _openSearch,
            onRetry: _retryCategories,
          ),
          _BlogTab(onSearchTap: _openSearch),
          _ProfileTab(
            customer: customer,
            role: authProvider.role,
            isSubmitting: authProvider.isSubmitting,
            wishlistCount: context.watch<WishlistProvider>().itemCount,
            cartCount: cartCount,
            onWishlist: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
            onOrders: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
            onNotifications: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            onLogout: () async {
              context.read<CartProvider>().clear();
              context.read<WishlistProvider>().clear();
              await context.read<AuthProvider>().logout();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (index == 3) {
            _openCart();
            return;
          }
          setState(() {
            _selectedTab = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        backgroundColor: Colors.white,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Brands',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: _CartBadgeIcon(count: cartCount),
            selectedIcon: _CartBadgeIcon(count: cartCount, selected: true),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.searchController,
    required this.bannerController,
    required this.bannerIndex,
    required this.categoriesFuture,
    required this.hotDealsFuture,
    required this.featuredProductsFuture,
    required this.recommendedProductsFuture,
    required this.onBannerChanged,
    required this.onSearch,
    required this.onCategoryTap,
    required this.onProductTap,
    required this.onWishlistTap,
    required this.onOrdersTap,
    required this.onCartTap,
    required this.cartCount,
    required this.onCategoriesRetry,
    required this.onHotDealsRetry,
    required this.onFeaturedRetry,
    required this.onRecommendedRetry,
  });

  final TextEditingController searchController;
  final PageController bannerController;
  final int bannerIndex;
  final Future<List<Category>> categoriesFuture;
  final Future<List<Product>> hotDealsFuture;
  final Future<List<Product>> featuredProductsFuture;
  final Future<List<Product>> recommendedProductsFuture;
  final ValueChanged<int> onBannerChanged;
  final ValueChanged<String> onSearch;
  final ValueChanged<Category> onCategoryTap;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onCartTap;
  final int cartCount;
  final VoidCallback onCategoriesRetry;
  final VoidCallback onHotDealsRetry;
  final VoidCallback onFeaturedRetry;
  final VoidCallback onRecommendedRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          _HeaderRow(
            onWishlistTap: onWishlistTap,
            onOrdersTap: onOrdersTap,
            onCartTap: onCartTap,
            cartCount: cartCount,
          ),
          const SizedBox(height: 18),
          _SearchField(controller: searchController, onSubmitted: onSearch),
          const SizedBox(height: 18),
          _BannerCarousel(
            controller: bannerController,
            activeIndex: bannerIndex,
            onChanged: onBannerChanged,
            onShopNow: () => onSearch('new arrivals'),
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Categories',
            subtitle: 'Shop by style, mood, and occasion',
            actionLabel: 'View all',
            onActionTap: () => onSearch(''),
          ),
          const SizedBox(height: 12),
          _CategoryStrip(
            categoriesFuture: categoriesFuture,
            onCategoryTap: onCategoryTap,
            onRetry: onCategoriesRetry,
          ),
          const SizedBox(height: 22),
          _ProductShowcaseSection(
            title: 'Hot Deals',
            subtitle: 'Limited-time price drops worth a look',
            future: hotDealsFuture,
            onRetry: onHotDealsRetry,
            isGrid: false,
            itemBuilder: (context, product, index) {
              return _ShowcaseCard(
                product: product,
                gradient: [
                  _hotDealGradients[index % _hotDealGradients.length],
                  _hotDealGradients[(index + 1) % _hotDealGradients.length],
                ],
                onTap: () => onProductTap(product),
              );
            },
          ),
          const SizedBox(height: 22),
          _ProductShowcaseSection(
            title: 'Featured Products',
            subtitle: 'Curated pieces with premium finishes',
            future: featuredProductsFuture,
            onRetry: onFeaturedRetry,
            isGrid: true,
            itemBuilder: (context, product, index) {
              return _ActionProductGridTile(
                product: product,
                accent: _featuredAccents[index % _featuredAccents.length],
                onTap: () => onProductTap(product),
              );
            },
          ),
          const SizedBox(height: 22),
          _ProductShowcaseSection(
            title: 'Recommended For You',
            subtitle: 'Fresh styles selected for the new season',
            future: recommendedProductsFuture,
            onRetry: onRecommendedRetry,
            isGrid: false,
            itemBuilder: (context, product, index) {
              return _ActionCompactProductCard(
                product: product,
                accent: _recommendedAccents[index % _recommendedAccents.length],
                onTap: () => onProductTap(product),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BrandsTab extends StatelessWidget {
  const _BrandsTab({required this.onSearchTap, required this.onBrandTap});

  final ValueChanged<String> onSearchTap;
  final ValueChanged<String> onBrandTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          const _SimpleTabHeader(
            title: 'Brands',
            subtitle: 'Premium labels and selected collections',
          ),
          const SizedBox(height: 14),
          _SearchField(
            hintText: 'Search a brand or collection',
            onSubmitted: onSearchTap,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _brandNames
                .map(
                  (brand) => ActionChip(
                    label: Text(brand),
                    onPressed: () => onBrandTap(brand),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 22),
          ..._brandStories.map(
            (story) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BrandStoryCard(
                title: story.title,
                subtitle: story.subtitle,
                highlight: story.highlight,
                gradient: story.gradient,
                onTap: () => onSearchTap(story.searchTerm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({
    required this.categoriesFuture,
    required this.onCategoryTap,
    required this.onSearchTap,
    required this.onRetry,
  });

  final Future<List<Category>> categoriesFuture;
  final ValueChanged<Category> onCategoryTap;
  final ValueChanged<String> onSearchTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          const _SimpleTabHeader(
            title: 'Categories',
            subtitle: 'Browse the catalog by collection',
          ),
          const SizedBox(height: 14),
          _SearchField(hintText: 'Search a category', onSubmitted: onSearchTap),
          const SizedBox(height: 18),
          FutureBuilder<List<Category>>(
            future: categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _SectionStateMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to load categories',
                  message: _errorText(snapshot.error),
                  actionLabel: 'Retry',
                  onActionTap: onRetry,
                );
              }

              final categories = snapshot.data ?? const <Category>[];
              if (categories.isEmpty) {
                return _SectionStateMessage(
                  icon: Icons.inbox_outlined,
                  title: 'No categories available',
                  message: 'The backend did not return any categories yet.',
                  actionLabel: 'Retry',
                  onActionTap: onRetry,
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 700 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.08,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryGridCard(
                        category: category,
                        tint: _categoryTints[index % _categoryTints.length],
                        onTap: () => onCategoryTap(category),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BlogTab extends StatelessWidget {
  const _BlogTab({required this.onSearchTap});

  final ValueChanged<String> onSearchTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          const _SimpleTabHeader(
            title: 'Blog',
            subtitle: 'Style notes, launches, and seasonal edits',
          ),
          const SizedBox(height: 14),
          ..._blogPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BlogPostCard(
                title: post.title,
                subtitle: post.subtitle,
                tag: post.tag,
                accent: post.accent,
                onTap: () => onSearchTap(post.searchTerm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.customer,
    required this.role,
    required this.isSubmitting,
    required this.onLogout,
    required this.wishlistCount,
    required this.cartCount,
    required this.onWishlist,
    required this.onOrders,
    required this.onNotifications,
  });

  final CustomerProfile? customer;
  final String? role;
  final bool isSubmitting;
  final Future<void> Function() onLogout;
  final int wishlistCount;
  final int cartCount;
  final VoidCallback onWishlist;
  final VoidCallback onOrders;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final name = customer?.fullName ?? 'Guest User';
    final email = customer?.email ?? 'No email linked';
    final status = customer?.status ?? 'Signed in';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          const _SimpleTabHeader(
            title: 'Profile',
            subtitle: 'Session details and account actions',
          ),
          const SizedBox(height: 16),
          _ProfileHero(
            name: name,
            email: email,
            role: role ?? 'customer',
            status: status,
          ),
          const SizedBox(height: 16),
          _ProfileStatGrid(
            stats: [
              const _ProfileStat(label: 'Orders', value: '—'),
              _ProfileStat(label: 'Wishlist', value: '$wishlistCount'),
              _ProfileStat(label: 'Cart', value: '$cartCount'),
              const _ProfileStat(label: 'Status', value: 'Active'),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('My Orders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOrders,
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border_rounded),
                  title: const Text('Wishlist'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onWishlist,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Name', value: name),
                  _DetailRow(label: 'Email', value: email),
                  _DetailRow(label: 'Role', value: role ?? '-'),
                  _DetailRow(label: 'Status', value: status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isSubmitting
                ? null
                : () {
                    onLogout();
                  },
            icon: const Icon(Icons.logout_rounded),
            label: Text(isSubmitting ? 'Logging out...' : 'Logout'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.onWishlistTap,
    required this.onOrdersTap,
    required this.onCartTap,
    required this.cartCount,
  });

  final VoidCallback onWishlistTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onCartTap;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LogoMark(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StyleOra',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Premium fashion marketplace',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _PillActionButton(
          icon: Icons.favorite_border_rounded,
          label: 'Wishlist',
          onTap: onWishlistTap,
        ),
        const SizedBox(width: 8),
        _PillActionButton(
          icon: Icons.shopping_bag_outlined,
          label: 'Cart',
          badgeCount: cartCount,
          onTap: onCartTap,
        ),
        const SizedBox(width: 8),
        _PillActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Orders',
          onTap: onOrdersTap,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.onSubmitted,
    this.hintText = 'Search products, brands, or categories',
    this.controller,
  });

  final TextEditingController? controller;
  final ValueChanged<String> onSubmitted;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            onPressed: () => onSubmitted(controller?.text ?? ''),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.controller,
    required this.activeIndex,
    required this.onChanged,
    required this.onShopNow,
  });

  final PageController controller;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;
        final isNarrow = constraints.maxWidth < 360;
        final isWide = constraints.maxWidth >= 840;
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final heightScale = textScale > 1 ? textScale : 1.0;
        final baseBannerHeight = isWide
            ? 288.0
            : isCompact
            ? (isNarrow ? 280.0 : 236.0)
            : 272.0;
        final bannerHeight = baseBannerHeight * heightScale;
        final titleStyle =
            (isWide
                    ? Theme.of(context).textTheme.headlineMedium
                    : isCompact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                );
        final subtitleStyle =
            (isCompact
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.28,
                );

        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                PageView.builder(
                  controller: controller,
                  itemCount: _banners.length,
                  onPageChanged: onChanged,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: banner.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -18,
                            top: -12,
                            child: _BannerOrb(
                              size: 132,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            bottom: -24,
                            child: _BannerOrb(
                              size: 104,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isCompact ? 16 : 22,
                              isCompact ? 14 : 16,
                              isCompact ? 16 : 22,
                              10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: _Ribbon(text: banner.pill),
                                ),
                                SizedBox(height: isCompact ? 10 : 14),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isWide ? 360 : 250,
                                  ),
                                  child: Text(
                                    banner.title,
                                    maxLines: isCompact ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 6 : 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isWide ? 380 : 270,
                                  ),
                                  child: Text(
                                    banner.subtitle,
                                    maxLines: isCompact ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: subtitleStyle,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 8 : 12),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    FilledButton(
                                      onPressed: onShopNow,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF111827,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 14 : 18,
                                          vertical: isCompact ? 10 : 12,
                                        ),
                                      ),
                                      child: const Text('Shop now'),
                                    ),
                                    Text(
                                      banner.offer,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        _banners.length,
                                        (dotIndex) => AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          height: 6,
                                          width: dotIndex == activeIndex
                                              ? 22
                                              : 6,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: dotIndex == activeIndex
                                                  ? 0.95
                                                  : 0.45,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
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
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categoriesFuture,
    required this.onCategoryTap,
    required this.onRetry,
  });

  final Future<List<Category>> categoriesFuture;
  final ValueChanged<Category> onCategoryTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SectionStateMessage(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load categories',
            message: _errorText(snapshot.error),
            actionLabel: 'Retry',
            onActionTap: onRetry,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _HorizontalLoadingStrip(itemCount: 6);
        }

        final categories = snapshot.data ?? const <Category>[];
        if (categories.isEmpty) {
          return _SectionStateMessage(
            icon: Icons.inbox_outlined,
            title: 'No categories available',
            message: 'The backend did not return any categories yet.',
            actionLabel: 'Retry',
            onActionTap: onRetry,
          );
        }

        return SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryPill(
                category: category,
                tint: _categoryTints[index % _categoryTints.length],
                onTap: () => onCategoryTap(category),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductShowcaseSection extends StatelessWidget {
  const _ProductShowcaseSection({
    required this.title,
    required this.subtitle,
    required this.future,
    required this.onRetry,
    required this.itemBuilder,
    required this.isGrid,
  });

  final String title;
  final String subtitle;
  final Future<List<Product>> future;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, Product product, int index)
  itemBuilder;
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        FutureBuilder<List<Product>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SectionStateMessage(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load $title',
                message: _errorText(snapshot.error),
                actionLabel: 'Retry',
                onActionTap: onRetry,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder(context);
            }

            final products = snapshot.data ?? const <Product>[];
            if (products.isEmpty) {
              return _SectionStateMessage(
                icon: Icons.inventory_2_outlined,
                title: 'No $title yet',
                message: 'The backend returned no products for this section.',
                actionLabel: 'Retry',
                onActionTap: onRetry,
              );
            }

            return _buildContent(context, products);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return SizedBox(
      height: isGrid ? 304 : 250,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
    );
  }

  Widget _buildContent(BuildContext context, List<Product> products) {
    if (isGrid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 1120
              ? 4
              : constraints.maxWidth >= 760
              ? 3
              : 2;
          final childAspectRatio = constraints.maxWidth >= 1120
              ? 0.9
              : constraints.maxWidth >= 760
              ? 0.84
              : 0.74;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) =>
                itemBuilder(context, products[index], index),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth >= 980
            ? (constraints.maxWidth * 0.28).clamp(220.0, 286.0)
            : constraints.maxWidth >= 640
            ? (constraints.maxWidth * 0.36).clamp(198.0, 230.0)
            : 186.0);

        return SizedBox(
          height: 242,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            padding: const EdgeInsets.only(right: 4),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: itemBuilder(context, products[index], index),
            ),
          ),
        );
      },
    );
  }
}

class _SectionStateMessage extends StatelessWidget {
  const _SectionStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.black45),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onActionTap, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _HorizontalLoadingStrip extends StatelessWidget {
  const _HorizontalLoadingStrip({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            width: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          );
        },
      ),
    );
  }
}

String _errorText(Object? error) {
  if (error == null) {
    return 'Something went wrong.';
  }
  return error.toString();
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.tint,
    required this.onTap,
  });

  final Category category;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = category.categoryTitle ?? 'Category';
    final stock = category.stock ?? 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tint.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: CategoryImage(
                imageUrl: category.imageUrl,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '$stock items',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.tint,
    required this.onTap,
  });

  final Category category;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = category.categoryTitle ?? 'Category';
    final stock = category.stock ?? 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 54,
                width: 54,
                child: CategoryImage(
                  imageUrl: category.imageUrl,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '$stock in stock',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImagePanel extends StatelessWidget {
  const _ProductImagePanel({
    required this.product,
    required this.borderRadius,
    required this.accent,
    this.fit = BoxFit.cover,
    this.badge,
    this.imagePadding,
  });

  final Product product;
  final BorderRadius borderRadius;
  final Color accent;
  final BoxFit fit;
  final Widget? badge;
  final EdgeInsetsGeometry? imagePadding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: imagePadding ?? const EdgeInsets.all(10),
              child: ProductImage(
                imageUrl: product.resolvedImageUrl,
                fit: fit,
                borderRadius: BorderRadius.circular(16),
                backgroundColor: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            if (badge != null) Positioned(left: 10, top: 10, child: badge!),
          ],
        ),
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.product,
    required this.gradient,
    required this.onTap,
  });

  final Product product;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discount = product.discount ?? 0;
    final badgeText = discount > 0 ? '-${discount.toStringAsFixed(0)}%' : 'Hot';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: 18,
                child: _BannerOrb(
                  size: 90,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProductImagePanel(
                        product: product,
                        accent: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        fit: BoxFit.contain,
                        imagePadding: const EdgeInsets.all(12),
                        badge: _Ribbon(text: badgeText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name ?? 'Untitled product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand ?? product.category ?? 'StyleOra',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '৳${product.effectivePrice.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DetailsArrow(accent: Colors.white, onTap: onTap),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _WishlistButton(
                            product: product,
                            stock: product.stock ?? 0,
                            compact: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AddToCartButton(
                            product: product,
                            stock: product.stock ?? 0,
                            compact: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProductGridTile extends StatelessWidget {
  const _ProductGridTile({
    required this.product,
    required this.accent,
    required this.onTap,
  });

  final Product product;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (product.discount ?? 0) > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductImagePanel(
                  product: product,
                  accent: accent,
                  borderRadius: BorderRadius.circular(20),
                  fit: BoxFit.cover,
                  badge: hasDiscount
                      ? _Ribbon(
                          text: '-${product.discount!.toStringAsFixed(0)}%',
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name ?? 'Untitled product',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                product.brand ?? product.category ?? 'StyleOra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '৳${product.effectivePrice.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _CompactProductCard extends StatelessWidget {
  const _CompactProductCard({
    required this.product,
    required this.accent,
    required this.onTap,
  });

  final Product product;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (product.discount ?? 0) > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductImagePanel(
                  product: product,
                  accent: accent,
                  borderRadius: BorderRadius.circular(20),
                  fit: BoxFit.cover,
                  badge: hasDiscount
                      ? _Ribbon(
                          text: '-${product.discount!.toStringAsFixed(0)}%',
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name ?? 'Untitled product',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                product.brand ?? product.category ?? 'StyleOra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '৳${product.effectivePrice.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandStoryCard extends StatelessWidget {
  const _BrandStoryCard({
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String highlight;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [Colors.white, gradient.first.withValues(alpha: 0.12)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_mall_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        highlight,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: gradient.last,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlogPostCard extends StatelessWidget {
  const _BlogPostCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.library_books_rounded, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String name;
  final String email;
  final String role;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF3B2F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileBadge(
                label: role.toUpperCase(),
                color: const Color(0xFFF59E0B),
              ),
              _ProfileBadge(label: status, color: const Color(0xFF22C55E)),
              _ProfileBadge(
                label: 'StyleOra member',
                color: const Color(0xFF60A5FA),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatGrid extends StatelessWidget {
  const _ProfileStatGrid({required this.stats});

  final List<_ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.label,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final showLabel = MediaQuery.sizeOf(context).width >= 600;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: (badgeCount ?? 0) > 0,
              label: Text(_badgeLabel(badgeCount ?? 0)),
              child: Icon(icon, size: 18),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _badgeLabel(int count) => count > 99 ? '99+' : '$count';
}

class _CartBadgeIcon extends StatelessWidget {
  const _CartBadgeIcon({required this.count, this.selected = false});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(
        selected ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

class _BannerOrb extends StatelessWidget {
  const _BannerOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SimpleTabHeader extends StatelessWidget {
  const _SimpleTabHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ProfileStat {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _BannerData {
  const _BannerData({
    required this.pill,
    required this.title,
    required this.subtitle,
    required this.offer,
    required this.gradient,
  });

  final String pill;
  final String title;
  final String subtitle;
  final String offer;
  final List<Color> gradient;
}

class _BrandStory {
  const _BrandStory({
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.searchTerm,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String highlight;
  final String searchTerm;
  final List<Color> gradient;
}

class _BlogPost {
  const _BlogPost({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.searchTerm,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String tag;
  final String searchTerm;
  final Color accent;
}

const List<_BannerData> _banners = [
  _BannerData(
    pill: 'New season edit',
    title: 'Luxury layers for everyday wear',
    subtitle:
        'Refined silhouettes, elevated textures, and a calm monochrome palette.',
    offer: 'Up to 40% off selected styles',
    gradient: [Color(0xFF111827), Color(0xFF3B2F2F), Color(0xFF7C3AED)],
  ),
  _BannerData(
    pill: 'Trending now',
    title: 'Statement pieces that finish the look',
    subtitle:
        'Premium accessories and fashion-forward essentials curated for StyleOra.',
    offer: 'Fresh drops every week',
    gradient: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF1D4ED8)],
  ),
  _BannerData(
    pill: 'Limited offer',
    title: 'Discover polished fits built to stand out',
    subtitle:
        'Get inspired by the newest arrivals and best-performing seasonal picks.',
    offer: 'Free delivery on featured picks',
    gradient: [Color(0xFF9F1239), Color(0xFFBE185D), Color(0xFF4338CA)],
  ),
];

const List<Category> _fallbackCategories = [
  Category(categoryTitle: 'Women'),
  Category(categoryTitle: 'Men'),
  Category(categoryTitle: 'Shoes'),
  Category(categoryTitle: 'Accessories'),
  Category(categoryTitle: 'Beauty'),
  Category(categoryTitle: 'New In'),
];

const List<Color> _categoryTints = [
  Color(0xFF1D4ED8),
  Color(0xFF0F766E),
  Color(0xFFB45309),
  Color(0xFF7C3AED),
  Color(0xFFBE185D),
  Color(0xFF334155),
];

const List<Color> _hotDealGradients = [
  Color(0xFF111827),
  Color(0xFF0F766E),
  Color(0xFF9F1239),
  Color(0xFF4338CA),
];

const List<Color> _featuredAccents = [
  Color(0xFF1D4ED8),
  Color(0xFF0F766E),
  Color(0xFFB45309),
  Color(0xFFBE185D),
];

const List<Color> _recommendedAccents = [
  Color(0xFF7C3AED),
  Color(0xFF0F766E),
  Color(0xFF111827),
];

const List<_BrandStory> _brandStories = [
  _BrandStory(
    title: 'Minimal Luxe',
    subtitle: 'Neutral palettes, sharp lines, and polished essentials.',
    highlight: 'Shop tailored essentials',
    searchTerm: 'tailored',
    gradient: [Color(0xFF111827), Color(0xFF44403C)],
  ),
  _BrandStory(
    title: 'Urban Motion',
    subtitle: 'Activewear-inspired fits built for all-day comfort.',
    highlight: 'Explore active styles',
    searchTerm: 'activewear',
    gradient: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
  ),
  _BrandStory(
    title: 'Soft Glow Beauty',
    subtitle: 'Clean beauty and care staples with a premium finish.',
    highlight: 'See beauty picks',
    searchTerm: 'beauty',
    gradient: [Color(0xFFBE185D), Color(0xFFF59E0B)],
  ),
];

const List<_BlogPost> _blogPosts = [
  _BlogPost(
    title: 'The five pieces shaping this season',
    subtitle: 'A quick guide to building a premium capsule wardrobe.',
    tag: 'Style Edit',
    searchTerm: 'capsule wardrobe',
    accent: Color(0xFF1D4ED8),
  ),
  _BlogPost(
    title: 'How to layer textures without overdoing it',
    subtitle: 'Balance contrast, volume, and color for a refined finish.',
    tag: 'Fashion Notes',
    searchTerm: 'layering',
    accent: Color(0xFF0F766E),
  ),
  _BlogPost(
    title: 'Accessories that lift a simple outfit',
    subtitle: 'Small changes with a big impact on your overall look.',
    tag: 'Trending',
    searchTerm: 'accessories',
    accent: Color(0xFFBE185D),
  ),
];

const List<String> _brandNames = [
  'StyleOra Select',
  'Urban Form',
  'Nova Street',
  'Maison Line',
  'Ora Beauty',
  'Studio Ora',
];

class _ActionProductGridTile extends StatelessWidget {
  const _ActionProductGridTile({
    required this.product,
    required this.accent,
    required this.onTap,
  });

  final Product product;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (product.discount ?? 0) > 0;
    final stock = product.stock ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductImagePanel(
                  product: product,
                  accent: accent,
                  borderRadius: BorderRadius.circular(20),
                  fit: BoxFit.cover,
                  badge: hasDiscount
                      ? _Ribbon(
                          text: '-${product.discount!.toStringAsFixed(0)}%',
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name ?? 'Untitled product',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                product.brand ?? product.category ?? 'StyleOra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '৳${product.effectivePrice.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DetailsArrow(accent: accent, onTap: onTap),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 190;
                  if (compact) {
                    return Row(
                      children: [
                        Expanded(
                          child: _WishlistButton(
                            product: product,
                            stock: stock,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AddToCartButton(
                            product: product,
                            stock: stock,
                            compact: true,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      _WishlistButton(
                        product: product,
                        stock: stock,
                        compact: false,
                      ),
                      const SizedBox(width: 8),
                      _AddToCartButton(
                        product: product,
                        stock: stock,
                        compact: false,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCompactProductCard extends StatelessWidget {
  const _ActionCompactProductCard({
    required this.product,
    required this.accent,
    required this.onTap,
  });

  final Product product;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (product.discount ?? 0) > 0;
    final stock = product.stock ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductImagePanel(
                  product: product,
                  accent: accent,
                  borderRadius: BorderRadius.circular(20),
                  fit: BoxFit.cover,
                  badge: hasDiscount
                      ? _Ribbon(
                          text: '-${product.discount!.toStringAsFixed(0)}%',
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name ?? 'Untitled product',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                product.brand ?? product.category ?? 'StyleOra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '৳${product.effectivePrice.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DetailsArrow(accent: accent, onTap: onTap),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _WishlistButton(
                      product: product,
                      stock: stock,
                      compact: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AddToCartButton(
                      product: product,
                      stock: stock,
                      compact: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.product,
    required this.stock,
    required this.compact,
  });

  final Product product;
  final int stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, _) {
        final selected = wishlist.contains(product);
        if (compact) {
          return OutlinedButton(
            onPressed: stock <= 0 ? null : () => wishlist.toggle(product),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Icon(
              selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: selected
                  ? const Color(0xFFBE123C)
                  : const Color(0xFF111827),
            ),
          );
        }
        return OutlinedButton.icon(
          onPressed: stock <= 0 ? null : () => wishlist.toggle(product),
          icon: Icon(
            selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: selected ? const Color(0xFFBE123C) : const Color(0xFF111827),
          ),
          label: Text(selected ? 'Saved' : 'Wishlist'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({
    required this.product,
    required this.stock,
    required this.compact,
  });

  final Product product;
  final int stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: stock <= 0
          ? null
          : () {
              final added = context.read<CartProvider>().add(product);
              if (added) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to cart'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
      label: Text(compact ? 'Add' : 'Add to Cart'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _DetailsArrow extends StatelessWidget {
  const _DetailsArrow({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
      ),
    );
  }
}
