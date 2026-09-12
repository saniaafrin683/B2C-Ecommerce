import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { combineLatest, forkJoin } from 'rxjs';

import { Category } from '../../core/models/category.model';
import { Product } from '../../core/models/product.model';
import { SubCategory } from '../../core/models/sub-category.model';
import { CategoryService } from '../../core/services/category.service';
import { ProductPageResponse, ProductSearchParams, ProductService } from '../../core/services/product.service';
import { SubCategoryService } from '../../core/services/sub-category.service';

interface ShopCategoryLink {
  label: string;
  slug: string;
  aliases: string[];
}

interface ShopSubCategoryLink {
  id: number;
  name: string;
  slug: string;
}

@Component({
  selector: 'app-products',
  templateUrl: './products.component.html',
  styleUrls: ['./products.component.css']
})
export class ProductsComponent implements OnInit {
  readonly shopCategories: ShopCategoryLink[] = [
    { label: 'Women', slug: 'women', aliases: ['women', 'woman', 'girls', 'ladies'] },
    { label: 'Men', slug: 'men', aliases: ['men', 'man', 'boys'] },
    { label: 'Kids', slug: 'kids', aliases: ['kids', 'kid', 'child', 'children', 'baby', 'toddler'] },
    { label: 'Fashion', slug: 'fashion', aliases: ['fashion', 'apparel', 'clothing', 'style', 'wear'] },
    { label: 'Showpiece', slug: 'showpiece', aliases: ['showpiece', 'showpieces', 'decor', 'decoration', 'home decor', 'ornament'] }
  ];

  products: Product[] = [];
  filteredProducts: Product[] = [];
  displayedProducts: Product[] = [];
  availableSubCategories: ShopSubCategoryLink[] = [];
  availableBrands: string[] = [];
  categories: Category[] = [];
  subCategories: SubCategory[] = [];
  isLoading = true;
  errorMessage = '';
  pageTitle = 'All Products';
  pageDescription = 'Explore the full customer catalog across fashion, beauty, and family essentials.';
  searchTerm = '';
  minPrice: number | null = null;
  maxPrice: number | null = null;
  selectedBrand = '';
  sortOption = 'featured';
  isFilterPanelOpen = false;
  selectedCategorySlug = '';
  selectedSubCategorySlug = '';
  selectedSubCategoryId: number | null = null;
  page = 0;
  pageSize = 12;
  totalPages = 0;
  totalElements = 0;
  private taxonomyLoaded = false;

  constructor(
    private readonly productService: ProductService,
    private readonly categoryService: CategoryService,
    private readonly subCategoryService: SubCategoryService,
    private readonly route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    combineLatest([this.route.paramMap, this.route.queryParamMap]).subscribe(([paramMap, queryParamMap]) => {
      this.selectedCategorySlug = this.toSlug(paramMap.get('category'));
      this.selectedSubCategorySlug = this.toSlug(paramMap.get('subCategory'));
      this.selectedSubCategoryId = this.parseNullableNumber(queryParamMap.get('subcategoryId'));
      this.searchTerm = queryParamMap.get('search')?.trim() || '';
      this.page = 0;
      this.ensureTaxonomyLoaded(() => this.loadProducts());
    });
  }

  trackByLabel(_: number, value: string): string {
    return value;
  }

  trackBySubCategory(_: number, value: ShopSubCategoryLink): number {
    return value.id;
  }

  toSlug(value: string | null): string {
    return (value || '')
      .trim()
      .toLowerCase()
      .replace(/&/g, ' and ')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  getCategoryLabel(categorySlug: string): string {
    const category = this.shopCategories.find((item) => item.slug === categorySlug);
    return category ? category.label : this.getDisplayLabel(categorySlug);
  }

  applyFilters(): void {
    this.page = 0;
    this.isFilterPanelOpen = false;
    this.loadProducts();
  }

  resetClientFilters(): void {
    this.searchTerm = '';
    this.minPrice = null;
    this.maxPrice = null;
    this.selectedBrand = '';
    this.sortOption = 'featured';
    this.page = 0;
    this.isFilterPanelOpen = false;
    this.loadProducts();
  }

  toggleFilterPanel(): void {
    this.isFilterPanelOpen = !this.isFilterPanelOpen;
  }

  closeFilterPanel(): void {
    this.isFilterPanelOpen = false;
  }

  get hasClientSideFilters(): boolean {
    return Boolean(
      this.searchTerm.trim() ||
      this.selectedBrand ||
      this.toValidPrice(this.minPrice) !== null ||
      this.toValidPrice(this.maxPrice) !== null ||
      this.sortOption !== 'featured'
    );
  }

  private loadProducts(): void {
    this.isLoading = true;
    this.errorMessage = '';
    this.availableSubCategories = this.collectSubCategoryLinks();
    const { sortBy, sortDir } = this.resolveSort();
    const categoryFilter = this.resolveCategoryFilter();
    const resolvedSubCategoryId = this.resolveSelectedSubCategoryId();

    if (resolvedSubCategoryId != null) {
      this.loadProductsBySubCategory(resolvedSubCategoryId);
      return;
    }

    const searchParams: ProductSearchParams = {
      query: this.searchTerm,
      category: categoryFilter || undefined,
      brand: this.selectedBrand || undefined,
      minPrice: this.toValidPrice(this.minPrice),
      maxPrice: this.toValidPrice(this.maxPrice),
      page: this.page,
      size: this.pageSize,
      sortBy,
      sortDir
    };

    const request$ = this.hasServerSideFilters()
      ? this.productService.searchProducts(searchParams)
      : this.productService.getProductsPage(this.page, this.pageSize, sortBy, sortDir);

    request$.subscribe({
      next: (response) => this.applyPageResponse(response),
      error: () => this.handleProductLoadError()
    });
  }

  goToPage(nextPage: number): void {
    if (nextPage < 0 || nextPage >= this.totalPages || nextPage === this.page) {
      return;
    }

    this.page = nextPage;

    if (this.resolveSelectedSubCategoryId() != null) {
      this.updateClientSidePagination();
      return;
    }

    this.loadProducts();
  }

  private matchesCategory(product: Product, routeCategorySlug: string): boolean {
    if (!routeCategorySlug) {
      return true;
    }

    const normalizedTokens = this.getProductCategoryTokens(product);
    const routeCategory = this.shopCategories.find((category) => category.slug === routeCategorySlug);

    if (routeCategory) {
      return routeCategory.aliases.some((alias) => normalizedTokens.includes(this.toSlug(alias)));
    }

    return normalizedTokens.includes(routeCategorySlug);
  }

  private matchesSubCategory(product: Product, routeSubCategorySlug: string): boolean {
    if (!routeSubCategorySlug) {
      return true;
    }

    return this.toSlug(this.getProductSubCategory(product)) === routeSubCategorySlug;
  }

  private collectSubCategoryLinks(): ShopSubCategoryLink[] {
    const selectedCategoryId = this.resolveSelectedCategoryId();
    const relevantSubCategories = (this.subCategories || [])
      .filter((subCategory) => selectedCategoryId == null || subCategory.categoryId === selectedCategoryId)
      .filter((subCategory) => subCategory.id != null)
      .sort((left, right) => (left.subCategoryName || '').localeCompare(right.subCategoryName || ''));

    return relevantSubCategories.map((subCategory) => ({
      id: Number(subCategory.id),
      name: subCategory.subCategoryName,
      slug: this.toSlug(subCategory.subCategoryName)
    }));
  }

  private collectBrands(): string[] {
    const brandSet = new Set<string>();

    this.products
      .filter((product) => this.matchesCategory(product, this.selectedCategorySlug))
      .filter((product) => this.matchesSubCategory(product, this.selectedSubCategorySlug))
      .forEach((product) => {
        const brand = (product.brand || '').trim();
        if (brand) {
          brandSet.add(brand);
        }
      });

    return Array.from(brandSet).sort((left, right) => left.localeCompare(right));
  }

  private getProductSubCategory(product: Product): string {
    return product.subCategory || product.subcategory || '';
  }

  private matchesResolvedSubCategory(product: Product, resolvedSubCategoryId: number): boolean {
    if (product.subCategoryId != null && product.subCategoryId === resolvedSubCategoryId) {
      return true;
    }

    if (this.selectedSubCategorySlug && this.toSlug(this.getProductSubCategory(product)) === this.selectedSubCategorySlug) {
      return true;
    }

    return !this.getProductSubCategory(product) && this.selectedSubCategorySlug
      ? this.toSlug(product.name || '') === this.selectedSubCategorySlug
      : false;
  }

  private getProductCategoryTokens(product: Product): string[] {
    const rawValues = [product.category, this.getProductSubCategory(product)];
    const tokenSet = new Set<string>();

    rawValues
      .filter((value): value is string => Boolean(value))
      .forEach((value) => {
        const lowerValue = value.toLowerCase();
        const slugValue = this.toSlug(value);

        if (slugValue) {
          tokenSet.add(slugValue);
        }

        lowerValue
          .split(/[^a-z0-9]+/i)
          .map((token) => this.toSlug(token))
          .filter(Boolean)
          .forEach((token) => tokenSet.add(token));
      });

    return Array.from(tokenSet);
  }

  private syncPageCopy(): void {
    const categoryLabel = this.getCategoryLabel(this.selectedCategorySlug);
    const subCategoryLabel = this.getDisplayLabel(this.selectedSubCategorySlug);

    if (categoryLabel && subCategoryLabel) {
      this.pageTitle = categoryLabel + ' / ' + subCategoryLabel;
      this.pageDescription = 'Browsing ' + subCategoryLabel + ' products from the ' + categoryLabel + ' collection.';
      return;
    }

    if (categoryLabel) {
      this.pageTitle = categoryLabel + ' Collection';
      this.pageDescription = 'Browse ' + categoryLabel.toLowerCase() + ' products curated for everyday customer shopping.';
      return;
    }

    this.pageTitle = 'All Products';
    this.pageDescription = 'Explore the full customer catalog across fashion, beauty, and family essentials.';
  }

  getDisplayLabel(slug: string): string {
    return slug
      .split('-')
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(' ');
  }

  private toValidPrice(value: number | null): number | null {
    if (value === null || value === undefined || Number.isNaN(value)) {
      return null;
    }

    return value >= 0 ? value : null;
  }

  private applyPageResponse(response: ProductPageResponse): void {
    this.products = response?.content || [];
    this.availableSubCategories = this.collectSubCategoryLinks();
    this.availableBrands = this.collectBrands();

    let filteredProducts = this.products.filter((product) => this.matchesSubCategory(product, this.selectedSubCategorySlug));

    if (this.selectedBrand) {
      filteredProducts = filteredProducts.filter((product) =>
        (product.brand || '').trim().toLowerCase() === this.selectedBrand.trim().toLowerCase()
      );
    }

    this.filteredProducts = filteredProducts;
    this.displayedProducts = filteredProducts;
    this.totalPages = response?.totalPages || 0;
    this.totalElements = response?.totalElements || filteredProducts.length;
    this.isLoading = false;
    this.syncPageCopy();
  }

  private applySubCategoryProducts(products: Product[]): void {
    this.products = products.filter((product) => this.matchesCategory(product, this.selectedCategorySlug));
    this.availableSubCategories = this.collectSubCategoryLinks();
    this.availableBrands = this.collectBrands();
    this.filteredProducts = this.applyLocalFilters(this.products);
    this.totalElements = this.filteredProducts.length;
    this.totalPages = Math.ceil(this.totalElements / this.pageSize);
    this.updateClientSidePagination();
  }

  private loadProductsBySubCategory(resolvedSubCategoryId: number): void {
    this.productService.getProductsBySubCategory(resolvedSubCategoryId).subscribe({
      next: (products) => {
        const resolvedProducts = products || [];

        if (resolvedProducts.length > 0) {
          this.applySubCategoryProducts(resolvedProducts);
          return;
        }

        this.loadProductsBySubCategoryFallback(resolvedSubCategoryId);
      },
      error: () => this.loadProductsBySubCategoryFallback(resolvedSubCategoryId)
    });
  }

  private loadProductsBySubCategoryFallback(resolvedSubCategoryId: number): void {
    this.productService.getProducts().subscribe({
      next: (products) => {
        const fallbackProducts = (products || []).filter((product) =>
          this.matchesResolvedSubCategory(product, resolvedSubCategoryId)
        );

        this.applySubCategoryProducts(fallbackProducts);
      },
      error: () => this.handleProductLoadError()
    });
  }

  private resolveCategoryFilter(): string {
    if (!this.selectedCategorySlug) {
      return '';
    }

    const category = this.shopCategories.find((item) => item.slug === this.selectedCategorySlug);
    return category ? category.label : this.getDisplayLabel(this.selectedCategorySlug);
  }

  private hasServerSideFilters(): boolean {
    return Boolean(
      this.searchTerm.trim() ||
      this.selectedCategorySlug ||
      this.selectedBrand ||
      this.toValidPrice(this.minPrice) !== null ||
      this.toValidPrice(this.maxPrice) !== null
    );
  }

  private resolveSort(): { sortBy: string; sortDir: string } {
    switch (this.sortOption) {
      case 'price-asc':
        return { sortBy: 'price', sortDir: 'asc' };
      case 'price-desc':
        return { sortBy: 'price', sortDir: 'desc' };
      case 'name-asc':
        return { sortBy: 'name', sortDir: 'asc' };
      default:
        return { sortBy: 'id', sortDir: 'desc' };
    }
  }

  private ensureTaxonomyLoaded(onReady: () => void): void {
    if (this.taxonomyLoaded) {
      onReady();
      return;
    }

    forkJoin({
      categories: this.categoryService.getCategories(),
      subCategories: this.subCategoryService.getSubCategories()
    }).subscribe({
      next: ({ categories, subCategories }) => {
        this.categories = categories || [];
        this.subCategories = subCategories || [];
        this.taxonomyLoaded = true;
        onReady();
      },
      error: () => {
        this.categories = [];
        this.subCategories = [];
        this.taxonomyLoaded = true;
        onReady();
      }
    });
  }

  private resolveSelectedCategoryId(): number | null {
    if (!this.selectedCategorySlug) {
      return null;
    }

    const directCategory = (this.categories || []).find(
      (category) => this.toSlug(category.categoryTitle) === this.selectedCategorySlug
    );

    return directCategory?.id ?? null;
  }

  private resolveSelectedSubCategoryId(): number | null {
    if (this.selectedSubCategoryId != null) {
      return this.selectedSubCategoryId;
    }

    if (!this.selectedSubCategorySlug) {
      return null;
    }

    const selectedCategoryId = this.resolveSelectedCategoryId();
    const matchedSubCategory = (this.subCategories || []).find((subCategory) => {
      const sameSlug = this.toSlug(subCategory.subCategoryName) === this.selectedSubCategorySlug;
      const sameCategory = selectedCategoryId == null || subCategory.categoryId === selectedCategoryId;
      return sameSlug && sameCategory;
    });

    return matchedSubCategory?.id ?? null;
  }

  private applyLocalFilters(products: Product[]): Product[] {
    let filteredProducts = [...products];

    if (this.selectedSubCategorySlug) {
      filteredProducts = filteredProducts.filter((product) => this.matchesSubCategory(product, this.selectedSubCategorySlug));
    }

    if (this.selectedBrand) {
      filteredProducts = filteredProducts.filter((product) =>
        (product.brand || '').trim().toLowerCase() === this.selectedBrand.trim().toLowerCase()
      );
    }

    const minPrice = this.toValidPrice(this.minPrice);
    if (minPrice != null) {
      filteredProducts = filteredProducts.filter((product) => Number(product.price || 0) >= minPrice);
    }

    const maxPrice = this.toValidPrice(this.maxPrice);
    if (maxPrice != null) {
      filteredProducts = filteredProducts.filter((product) => Number(product.price || 0) <= maxPrice);
    }

    const searchTerm = this.searchTerm.trim().toLowerCase();
    if (searchTerm) {
      filteredProducts = filteredProducts.filter((product) =>
        [product.name, product.category, this.getProductSubCategory(product), product.brand, product.description]
          .filter((value): value is string => Boolean(value))
          .some((value) => value.toLowerCase().includes(searchTerm))
      );
    }

    return this.sortProducts(filteredProducts);
  }

  private sortProducts(products: Product[]): Product[] {
    const items = [...products];

    switch (this.sortOption) {
      case 'price-asc':
        return items.sort((left, right) => Number(left.price || 0) - Number(right.price || 0));
      case 'price-desc':
        return items.sort((left, right) => Number(right.price || 0) - Number(left.price || 0));
      case 'name-asc':
        return items.sort((left, right) => (left.name || '').localeCompare(right.name || ''));
      default:
        return items.sort((left, right) => Number(right.id || 0) - Number(left.id || 0));
    }
  }

  private updateClientSidePagination(): void {
    const startIndex = this.page * this.pageSize;
    const endIndex = startIndex + this.pageSize;

    this.displayedProducts = this.filteredProducts.slice(startIndex, endIndex);
    this.isLoading = false;
    this.syncPageCopy();
  }

  private parseNullableNumber(value: string | null): number | null {
    if (!value) {
      return null;
    }

    const normalizedValue = Number(value);
    return Number.isFinite(normalizedValue) ? normalizedValue : null;
  }

  private handleProductLoadError(): void {
    this.products = [];
    this.filteredProducts = [];
    this.displayedProducts = [];
    this.availableSubCategories = [];
    this.availableBrands = [];
    this.totalPages = 0;
    this.totalElements = 0;
    this.isLoading = false;
    this.errorMessage = 'Unable to load products right now. Please try again.';
    this.syncPageCopy();
  }
}
