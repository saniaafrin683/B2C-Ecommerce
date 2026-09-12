import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError, finalize } from 'rxjs/operators';
import { ProductService } from '../product.service';
import { Product } from '../product.model';
import { CategoryService } from '../../category/category.service';
import { Category } from '../../category/category.model';
import { clampPage, getPaginatedItems, getTotalPages, getVisiblePages } from '../../../shared/utils/pagination.util';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { environment } from '../../../../environments/environment';
import { getProductDisplayPrice, hasProductDiscount } from '../../../shared/utils/product-price.util';

interface ProductGridItem extends Product {
  displayImage: string;
  rating: number;
  reviewCount: number;
  oldPrice: number;
  newPrice: number;
  discountText: string;
  normalizedGender: string;
}

interface PriceRange {
  label: string;
  min: number | null;
  max: number | null;
}

interface RatingOption {
  label: string;
  min: number;
}

@Component({
  selector: 'app-grid',
  templateUrl: './grid.component.html',
  styleUrls: ['./grid.component.css']
})
export class GridComponent implements OnInit {
  private readonly defaultProductImage =
    'data:image/svg+xml;utf8,' +
    encodeURIComponent(
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480">
        <rect width="640" height="480" rx="28" fill="#f8fafc"/>
        <rect x="48" y="48" width="544" height="384" rx="24" fill="#e2e8f0"/>
        <path d="M180 320l72-88 64 76 92-120 88 132H180z" fill="#94a3b8"/>
        <circle cx="250" cy="176" r="34" fill="#cbd5e1"/>
        <text x="50%" y="86%" text-anchor="middle" font-family="Arial, sans-serif" font-size="28" fill="#475569">
          No image available
        </text>
      </svg>`
    );

  private readonly backendOrigin = environment.apiBaseUrl;

  allProducts: ProductGridItem[] = [];
  filteredProducts: ProductGridItem[] = [];
  paginatedProducts: ProductGridItem[] = [];
  private categoryImageMap: { [key: string]: string } = {};

  loading = false;
  deletingId: number | null = null;
  errorMessage = '';
  currentPage = 1;
  readonly pageSize = 12;

  searchTerm = '';
  selectedCategory = 'All Categories';
  selectedPriceLabel = 'All Prices';
  selectedGender = 'All';
  selectedSizeFit = 'All';
  selectedMinPrice: number | null = null;
  selectedMaxPrice: number | null = null;
  selectedRating = 0;

  categories: string[] = ['All Categories'];
  genders: string[] = ['All', 'Men', 'Women', 'Unisex'];

  priceRanges: PriceRange[] = [
    { label: 'All Prices', min: null, max: null },
    { label: 'Below 500', min: null, max: 499.99 },
    { label: '500 - 1000', min: 500, max: 1000 },
    { label: '1000 - 2000', min: 1000, max: 2000 },
    { label: 'Above 2000', min: 2000.01, max: null }
  ];

  sizeFitOptions = ['All', 'S', 'M', 'L', 'XL', 'Slim Fit', 'Regular Fit', 'Oversized'];

  ratingOptions: RatingOption[] = [
    { label: 'All Ratings', min: 0 },
    { label: '5 Star', min: 5 },
    { label: '4 Star & Up', min: 4 },
    { label: '3 Star & Up', min: 3 }
  ];

  constructor(
    private productService: ProductService,
    private router: Router,
    private categoryService: CategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.loading = true;
    this.errorMessage = '';
    this.loadingService.show();

    forkJoin({
      products: this.productService.getAllProducts(),
      categories: this.categoryService.getAllCategories().pipe(
        catchError(() => of(this.categoryService.getCachedCategories()))
      )
    }).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: ({ products, categories }: { products: Product[]; categories: Category[] }) => {
        this.categoryImageMap = this.buildCategoryImageMap(categories || []);
        this.allProducts = (products || []).map((product: Product, index: number) =>
          this.mapProductForGrid(product, index)
        );

        this.categories = [
          'All Categories',
          ...Array.from(
            new Set(
              this.allProducts
                .map((product) => (product.category || '').trim())
                .filter((category) => !!category)
            )
          )
        ];

        this.applyFilters();
      },
      error: () => {
        this.errorMessage = 'Failed to load products for the grid view.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  mapProductForGrid(product: Product, index: number): ProductGridItem {
    const basePrice = Number(product.price || 0);
    const discount = Number(product.discount || 0);
    const newPrice = getProductDisplayPrice(product);
    const oldPrice = hasProductDiscount(product) ? basePrice : newPrice;

    return {
      ...product,
      displayImage: this.getImage(product),
      rating: this.resolveRating(product, index),
      reviewCount: this.generateReviewCount(index),
      oldPrice,
      newPrice,
      discountText: discount > 0 ? `(${discount}% Off)` : '(No Offer)',
      normalizedGender: this.normalizeGender(product.gender)
    };
  }

  resolveRating(product: Product, index: number): number {
    const productRating = Number(product.rating);

    if (!Number.isNaN(productRating) && productRating > 0) {
      return productRating;
    }

    const fallbackRatings = [4, 4.5, 4.2, 4.8, 4.1];
    return fallbackRatings[index % fallbackRatings.length];
  }

  generateReviewCount(index: number): number {
    const counts = [55, 143, 174, 23, 109, 200, 321, 190];
    return counts[index % counts.length];
  }

  getImage(product: Product): string {
    const productImage = this.normalizeImageUrl(product.imageUrl);

    if (productImage) {
      return productImage;
    }

    const categoryImage = this.normalizeImageUrl(this.getCategoryImage(product.category));

    if (categoryImage) {
      return categoryImage;
    }

    return this.getFallbackImageByCategory(product.category);
  }

  getCategoryImage(category: string | null | undefined): string {
    const key = this.normalizeCategoryName(category);
    return key ? (this.categoryImageMap[key] || '') : '';
  }

  buildCategoryImageMap(categories: Category[]): { [key: string]: string } {
    return (categories || []).reduce((map: { [key: string]: string }, category: Category) => {
      const key = this.normalizeCategoryName(category.categoryTitle);
      const imageUrl = (category.imageUrl || '').trim();

      if (key && imageUrl) {
        map[key] = imageUrl;
      }

      return map;
    }, {});
  }

  getFallbackImageByCategory(category: string | null | undefined): string {
    return this.defaultProductImage;
  }

  applyPriceRange(min: number | null, max: number | null): void {
    this.selectedMinPrice = min;
    this.selectedMaxPrice = max;
    this.selectedPriceLabel = this.getPriceLabel(min, max);
    this.applyFilters();
  }

  selectCategory(category: string): void {
    this.selectedCategory = category;
    this.applyFilters();
  }

  selectGender(gender: string): void {
    this.selectedGender = gender;
    this.applyFilters();
  }

  selectSizeFit(option: string): void {
    this.selectedSizeFit = option;
    this.applyFilters();
  }

  selectRating(rating: number): void {
    this.selectedRating = rating;
    this.applyFilters();
  }

  applyFilters(): void {
    const normalizedSearch = this.searchTerm.trim().toLowerCase();

    this.filteredProducts = this.allProducts.filter((product) => {
      const searchMatch =
        !normalizedSearch ||
        (product.name || '').toLowerCase().includes(normalizedSearch) ||
        (product.brand || '').toLowerCase().includes(normalizedSearch) ||
        (product.category || '').toLowerCase().includes(normalizedSearch) ||
        (product.tagNumber || '').toLowerCase().includes(normalizedSearch) ||
        (product.tag || '').toLowerCase().includes(normalizedSearch);

      const categoryMatch =
        this.selectedCategory === 'All Categories' ||
        this.normalizeCategoryName(product.category) === this.selectedCategory.toLowerCase();

      const genderMatch =
        this.selectedGender === 'All' ||
        product.normalizedGender === this.normalizeGender(this.selectedGender);

      const minPriceMatch =
        this.selectedMinPrice === null || Number(product.price || 0) >= this.selectedMinPrice;

      const maxPriceMatch =
        this.selectedMaxPrice === null || Number(product.price || 0) <= this.selectedMaxPrice;

      const sizeFitMatch = this.matchesSizeFit(product, this.selectedSizeFit);

      const ratingMatch =
        this.selectedRating === 0 || Number(product.rating || 0) >= this.selectedRating;

      return searchMatch && categoryMatch && genderMatch && minPriceMatch && maxPriceMatch && sizeFitMatch && ratingMatch;
    });

    this.currentPage = 1;
    this.updatePaginatedProducts();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedCategory = 'All Categories';
    this.selectedPriceLabel = 'All Prices';
    this.selectedGender = 'All';
    this.selectedSizeFit = 'All';
    this.selectedMinPrice = null;
    this.selectedMaxPrice = null;
    this.selectedRating = 0;
    this.applyFilters();
  }

  getPriceLabel(min: number | null, max: number | null): string {
    const matched = this.priceRanges.find((range) => range.min === min && range.max === max);
    return matched ? matched.label : 'All Prices';
  }

  normalizeCategoryName(value: string | null | undefined): string {
    return (value || '').trim().toLowerCase();
  }

  normalizeGender(value: string | null | undefined): string {
    const normalized = (value || '').trim().toLowerCase();

    if (normalized === 'men' || normalized === 'man' || normalized === 'male') {
      return 'men';
    }

    if (normalized === 'women' || normalized === 'woman' || normalized === 'female') {
      return 'women';
    }

    if (normalized === 'unisex') {
      return 'unisex';
    }

    return normalized;
  }

  matchesSizeFit(product: ProductGridItem, selectedOption: string): boolean {
    if (selectedOption === 'All') {
      return true;
    }

    const target = selectedOption.trim().toLowerCase();
    const candidates = this.getSizeFitCandidates(product);

    return candidates.some((candidate) => this.matchesCandidate(candidate, target));
  }

  getSizeFitCandidates(product: Product): string[] {
    const values: string[] = [];

    const append = (value: string | null | undefined): void => {
      if (value && value.trim()) {
        values.push(value.trim());
      }
    };

    append(product.size);
    append(product.weight);
    append(product.tag);
    append(product.description);
    append(product.name);

    (product.sizes || []).forEach((value) => append(value));
    (product.selectedSizes || []).forEach((value) => append(value));

    return values;
  }

  matchesCandidate(candidate: string, target: string): boolean {
    const normalized = candidate.toLowerCase();

    if (['s', 'm', 'l', 'xl'].includes(target)) {
      const padded = ` ${normalized.replace(/[^a-z0-9]+/g, ' ')} `;
      return padded.includes(` ${target} `) || normalized === target || normalized.includes(`size ${target}`);
    }

    return normalized.includes(target);
  }

  goToCreate(): void {
    this.router.navigate(['/products/create']);
  }

  goToEdit(productId: number | undefined): void {
    if (!productId) {
      return;
    }

    this.router.navigate(['/products/edit', productId]);
  }

  goToDetails(productId: number | undefined): void {
    if (!productId) {
      return;
    }

    this.router.navigate(['/products/details', productId]);
  }

  onDelete(productId: number | undefined): void {
    if (!productId) {
      return;
    }

    const confirmDelete = window.confirm('Are you sure you want to delete this product?');

    if (!confirmDelete) {
      return;
    }

    this.deletingId = productId;
    this.loadingService.show();

    this.productService.deleteProduct(productId).pipe(
      finalize(() => {
        this.deletingId = null;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.allProducts = this.allProducts.filter((product) => product.id !== productId);
        this.applyFilters();
      },
      error: () => {
        this.errorMessage = 'Delete failed. Please try again.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  getStarArray(rating: number): number[] {
    const rounded = Math.round(rating);
    return Array(rounded).fill(0);
  }

  onImageError(event: Event): void {
    const image = event.target as HTMLImageElement | null;

    if (!image) {
      return;
    }

    image.onerror = null;
    image.src = this.defaultProductImage;
  }

  private normalizeImageUrl(imageUrl: string | null | undefined): string {
    const value = (imageUrl || '').trim();

    if (!value) {
      return '';
    }

    if (
      value.startsWith('assets/') ||
      value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('data:')
    ) {
      return value;
    }

    if (value.startsWith('/')) {
      return `${this.backendOrigin}${value}`;
    }

    return `${this.backendOrigin}/${value.replace(/^\/+/, '')}`;
  }

  trackByProduct(index: number, item: ProductGridItem): number | undefined {
    return item.id;
  }

  get totalPages(): number {
    return getTotalPages(this.filteredProducts.length, this.pageSize);
  }

  get pages(): number[] {
    return getVisiblePages(this.currentPage, this.totalPages);
  }

  get pageStart(): number {
    if (this.filteredProducts.length === 0) {
      return 0;
    }

    return (this.currentPage - 1) * this.pageSize + 1;
  }

  get pageEnd(): number {
    return Math.min(this.currentPage * this.pageSize, this.filteredProducts.length);
  }

  goToPage(page: number): void {
    this.currentPage = clampPage(page, this.totalPages);
    this.updatePaginatedProducts();
  }

  goToPrevious(): void {
    this.goToPage(this.currentPage - 1);
  }

  goToNext(): void {
    this.goToPage(this.currentPage + 1);
  }

  private updatePaginatedProducts(): void {
    this.paginatedProducts = getPaginatedItems(this.filteredProducts, this.currentPage, this.pageSize);
  }
}