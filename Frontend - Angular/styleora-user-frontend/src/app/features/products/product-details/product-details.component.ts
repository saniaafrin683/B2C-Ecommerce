import { HttpErrorResponse } from '@angular/common/http';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { CartService } from '../../../core/services/cart.service';
import { Product, ProductAttribute } from '../../../core/models/product.model';
import { ProductService } from '../../../core/services/product.service';
import { ReviewRecord, ReviewService } from '../../../core/services/review.service';
import { WishlistService } from '../../../core/services/wishlist.service';

interface CustomerReview {
  name: string;
  title: string;
  rating: number;
  comment: string;
  reviewDate: string;
  adminReply: string;
}

@Component({
  selector: 'app-product-details',
  templateUrl: './product-details.component.html',
  styleUrls: ['./product-details.component.css']
})
export class ProductDetailsComponent implements OnInit {
  readonly fallbackImage = 'assets/images/category/default-product.png';
  reviews: CustomerReview[] = [];
  product: Product | null = null;
  galleryImages: string[] = [];
  selectedImage = '';
  relatedProducts: Product[] = [];
  addToCartMessage = '';
  addToCartErrorMessage = '';
  wishlistMessage = '';
  buyNowMessage = '';
  selectedSize = '';
  quantity = 1;
  isWishlisted = false;
  isAddingToCart = false;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly productService: ProductService,
    private readonly cartService: CartService,
    private readonly wishlistService: WishlistService,
    private readonly reviewService: ReviewService
  ) {}

  ngOnInit(): void {
    const productId = Number(this.route.snapshot.paramMap.get('id'));

    if (!productId) {
      return;
    }

    this.productService.getProductById(productId).subscribe((product) => {
      this.product = product;
      this.syncSelectedSize(product);
      this.galleryImages = this.buildGalleryImages(product);
      this.selectedImage = this.galleryImages[0] || this.productImageUrl;
      this.isWishlisted = this.wishlistService.isInWishlist(product.id);
      this.loadApprovedReviews(product.id);
      this.loadRelatedProducts(product);
    });
  }

  addToCart(): void {
    if (!this.product || this.availableStock <= 0) {
      this.addToCartErrorMessage = 'This product is out of stock.';
      return;
    }

    const requestedQuantity = Math.min(this.quantity, this.availableStock);
    this.isAddingToCart = true;
    this.addToCartMessage = '';
    this.addToCartErrorMessage = '';

    this.cartService.addToCart(this.product, requestedQuantity, this.selectedSize).subscribe({
      next: (updatedProduct) => {
        this.product = updatedProduct;
        this.syncSelectedSize(updatedProduct);
        this.quantity = 1;
        this.addToCartMessage = this.selectedSize
          ? `${requestedQuantity} item(s) of size ${this.selectedSize} added to cart.`
          : `${requestedQuantity} item(s) added to cart.`;
        this.wishlistMessage = '';
        this.buyNowMessage = '';
        this.isAddingToCart = false;
      },
      error: (error: HttpErrorResponse) => {
        this.addToCartErrorMessage = error.error?.message || 'Unable to add this product to cart.';
        this.isAddingToCart = false;
      }
    });
  }

  toggleWishlist(): void {
    if (!this.product) {
      return;
    }

    this.isWishlisted = this.wishlistService.toggleWishlist(this.product);
    this.wishlistMessage = this.isWishlisted
      ? 'Added to wishlist.'
      : 'Removed from wishlist.';
    this.addToCartMessage = '';
    this.addToCartErrorMessage = '';
    this.buyNowMessage = '';
  }

  showBuyNowHint(): void {
    this.buyNowMessage = 'Use Add to Cart first, then continue from the cart or checkout flow.';
    this.addToCartMessage = '';
    this.addToCartErrorMessage = '';
    this.wishlistMessage = '';
  }

  selectImage(imageUrl: string): void {
    this.selectedImage = imageUrl;
  }

  selectSize(size: string): void {
    this.selectedSize = size;
  }

  increaseQuantity(): void {
    this.quantity = Math.min(this.quantity + 1, Math.max(this.availableStock, 1));
  }

  decreaseQuantity(): void {
    this.quantity = Math.max(this.quantity - 1, 1);
  }

  updateQuantity(quantity: number): void {
    this.quantity = Math.max(1, Math.min(quantity, Math.max(this.availableStock, 1)));
  }

  get stockLabel(): string {
    if (this.availableStock <= 0) {
      return 'Out of Stock';
    }

    if (this.availableStock <= 10) {
      return `Low Stock: ${this.availableStock} left`;
    }

    return `In Stock: ${this.availableStock}`;
  }

  get stockClass(): string {
    if (this.availableStock <= 0) {
      return 'stock-out';
    }

    if (this.availableStock <= 10) {
      return 'stock-low';
    }

    return 'stock-in';
  }

  get availableStock(): number {
    const stockValue = Number(this.product?.stock ?? 0);
    return Number.isFinite(stockValue) ? Math.max(0, Math.floor(stockValue)) : 0;
  }

  get productAttributes(): ProductAttribute[] {
    return this.product?.attributes || [];
  }

  get hasProductAttributes(): boolean {
    return this.productAttributes.length > 0;
  }

  get sizeOptions(): string[] {
    return this.sizeOptionsFromProduct(this.product);
  }

  get productSubCategory(): string {
    return this.product?.subCategory || this.product?.subcategory || '';
  }

  get originalPrice(): number | null {
    if (!this.product || !this.product.discount) {
      return null;
    }

    const finalPrice = Number(this.product.price || 0);
    const discountRate = 1 - (Number(this.product.discount) / 100);

    if (discountRate <= 0) {
      return null;
    }

    return Math.round((finalPrice / discountRate) * 100) / 100;
  }

  get finalPrice(): number {
    return Number(this.product?.price || 0);
  }

  get savingsAmount(): number {
    const originalPrice = this.originalPrice;
    return originalPrice ? Math.max(0, Math.round((originalPrice - this.finalPrice) * 100) / 100) : 0;
  }

  get productTags(): string[] {
    const tags = [
      this.product?.category,
      this.productSubCategory,
      this.product?.brand,
      this.availableStock > 0 ? 'Ready Stock' : 'Sold Out'
    ];

    return Array.from(new Set(tags.filter((value): value is string => Boolean(value && value.trim()))));
  }

  get shortDescription(): string {
    const description = (this.product?.description || '').trim();
    if (!description) {
      return 'A customer-favorite style crafted for everyday comfort and modern wear.';
    }

    return description.length > 170 ? `${description.slice(0, 167)}...` : description;
  }

  get productImageUrl(): string {
    return this.product?.imageUrl || this.fallbackImage;
  }

  get reviewAverage(): string {
    if (!this.reviews.length) {
      return '0.0';
    }

    const total = this.reviews.reduce((sum, review) => sum + review.rating, 0);
    return (total / this.reviews.length).toFixed(1);
  }

  trackByProduct(_: number, product: Product): number {
    return product.id;
  }

  trackByReview(_: number, review: CustomerReview): string {
    return `${review.name}-${review.comment}`;
  }

  createStars(rating: number): string[] {
    return Array.from({ length: rating }, () => 'star');
  }

  trackByAttribute(_: number, attribute: ProductAttribute): string {
    return `${attribute.key}-${attribute.value}`;
  }

  private buildGalleryImages(product: Product): string[] {
    const categoryFallback = product.category
      ? `assets/images/category/${product.category.toLowerCase()}.png`
      : this.fallbackImage;
    const baseImage = product.imageUrl || this.fallbackImage;
    const uniqueImages = new Set<string>([baseImage]);

    if (baseImage !== categoryFallback) {
      uniqueImages.add(categoryFallback);
    }

    if (baseImage !== this.fallbackImage) {
      uniqueImages.add(this.fallbackImage);
    }

    return Array.from(uniqueImages);
  }

  private loadRelatedProducts(product: Product): void {
    this.productService.getProducts().subscribe({
      next: (products) => {
        const sameCategory = products.filter((candidate) =>
          candidate.id !== product.id &&
          candidate.category?.trim().toLowerCase() === product.category?.trim().toLowerCase()
        );
        const fallbackProducts = products.filter((candidate) => candidate.id !== product.id);
        const preferred = sameCategory.length ? sameCategory : fallbackProducts;

        this.relatedProducts = preferred.slice(0, 4);
      },
      error: () => {
        this.relatedProducts = [];
      }
    });
  }

  private loadApprovedReviews(productId: number): void {
    this.reviewService.getApprovedReviewsByProduct(productId, 6).subscribe({
      next: (reviews) => {
        this.reviews = (reviews || []).map((review) => this.toCustomerReview(review));
      },
      error: () => {
        this.reviews = [];
      }
    });
  }

  private toCustomerReview(review: ReviewRecord): CustomerReview {
    return {
      name: review.customerName?.trim() || 'Styleora customer',
      title: review.reviewTitle?.trim() || 'Verified customer',
      rating: Math.max(1, Math.min(Number(review.rating || 0), 5)),
      comment: review.reviewMessage?.trim() || 'Customer feedback will appear here once approved.',
      reviewDate: review.reviewDate || '',
      adminReply: review.replyMessage?.trim() || ''
    };
  }

  private syncSelectedSize(product: Product): void {
    const availableSizeOptions = this.sizeOptionsFromProduct(product);

    if (!availableSizeOptions.length) {
      this.selectedSize = '';
      return;
    }

    if (availableSizeOptions.includes(this.selectedSize)) {
      return;
    }

    this.selectedSize = availableSizeOptions[0];
  }

  private sizeOptionsFromProduct(product: Product | null): string[] {
    const sizeAttribute = (product?.attributes || []).find((attribute) =>
      attribute?.key?.trim().toLowerCase() === 'size'
    )?.value;

    if (!sizeAttribute) {
      return [];
    }

    return Array.from(new Set(
      sizeAttribute
        .split(/[|/,]/)
        .map((value) => value.trim())
        .filter((value) => !!value)
    ));
  }

}
