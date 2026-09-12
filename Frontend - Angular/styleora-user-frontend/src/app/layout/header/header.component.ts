import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

import { forkJoin, Observable } from 'rxjs';

import { AuthService } from '../../core/services/auth.service';
import { CartService } from '../../core/services/cart.service';
import { WishlistService } from '../../core/services/wishlist.service';
import { Category } from '../../core/models/category.model';
import { SubCategory } from '../../core/models/sub-category.model';
import { CategoryService } from '../../core/services/category.service';
import { SubCategoryService } from '../../core/services/sub-category.service';

interface CategoryMenuLink {
  id?: number;
  label: string;
  slug: string;
  route: string[];
  queryParams?: { [key: string]: string | number };
}

interface CategoryMenuItem extends CategoryMenuLink {
  subCategories: CategoryMenuLink[];
}

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css']
})
export class HeaderComponent implements OnInit {
  readonly allProductsLink: CategoryMenuLink = { label: 'All Products', slug: '', route: ['/shop'] };
  categoryMenu: CategoryMenuItem[] = [];
  searchTerm = '';
  cartCount$: Observable<number>;
  wishlistCount$: Observable<number>;
  mobileCategoryMenuOpen = false;
  expandedMobileCategoryId: number | null = null;

  constructor(
    private readonly authService: AuthService,
    private readonly cartService: CartService,
    private readonly wishlistService: WishlistService,
    private readonly categoryService: CategoryService,
    private readonly subCategoryService: SubCategoryService,
    private readonly router: Router
  ) {
    this.cartCount$ = this.cartService.getCartCount();
    this.wishlistCount$ = this.wishlistService.getWishlistCount();
  }

  ngOnInit(): void {
    this.loadCategoryMenu();
  }

  goToShopSearch(): void {
    const normalizedSearch = this.searchTerm.trim();
    void this.router.navigate(
      ['/shop'],
      normalizedSearch ? { queryParams: { search: normalizedSearch } } : {}
    );
  }

  isShopActive(): boolean {
    return this.router.url === '/shop' || this.router.url.startsWith('/products');
  }

  isCategoryActive(): boolean {
    return this.router.url.startsWith('/shop/') || this.router.url.startsWith('/category/');
  }

  isWishlistActive(): boolean {
    return this.router.url.startsWith('/wishlist');
  }

  isProfileActive(): boolean {
    return this.router.url.startsWith('/profile') || this.router.url.startsWith('/login');
  }

  isLoggedIn(): boolean {
    return this.authService.isAuthenticated();
  }

  logout(): void {
    this.authService.logout();
  }

  toggleMobileCategoryMenu(): void {
    this.mobileCategoryMenuOpen = !this.mobileCategoryMenuOpen;
  }

  toggleMobileCategorySection(categoryId?: number): void {
    if (categoryId == null) {
      return;
    }

    this.expandedMobileCategoryId = this.expandedMobileCategoryId === categoryId ? null : categoryId;
  }

  closeMobileMenus(): void {
    this.mobileCategoryMenuOpen = false;
    this.expandedMobileCategoryId = null;
  }

  isSubCategoryActive(categorySlug: string, subCategorySlug: string): boolean {
    return this.router.url.startsWith(`/shop/${categorySlug}/${subCategorySlug}`);
  }

  private loadCategoryMenu(): void {
    forkJoin({
      categories: this.categoryService.getCategories(),
      subCategories: this.subCategoryService.getSubCategories()
    }).subscribe({
      next: ({ categories, subCategories }) => {
        this.categoryMenu = this.buildCategoryMenu(categories || [], subCategories || []);
      },
      error: () => {
        this.categoryMenu = this.buildFallbackMenu();
      }
    });
  }

  private buildCategoryMenu(categories: Category[], subCategories: SubCategory[]): CategoryMenuItem[] {
    const sortedCategories = [...(categories || [])].sort((left, right) =>
      (left.categoryTitle || '').localeCompare(right.categoryTitle || '')
    );

    return sortedCategories.map((category) => {
      const categorySlug = this.toSlug(category.categoryTitle);
      const childLinks = (subCategories || [])
        .filter((subCategory) => subCategory.categoryId === (category.id ?? null))
        .sort((left, right) => (left.subCategoryName || '').localeCompare(right.subCategoryName || ''))
        .map((subCategory) => ({
          id: subCategory.id,
          label: subCategory.subCategoryName,
          slug: this.toSlug(subCategory.subCategoryName),
          route: ['/shop', categorySlug, this.toSlug(subCategory.subCategoryName)],
          queryParams: subCategory.id != null ? { subcategoryId: subCategory.id } : undefined
        }));

      return {
        id: category.id,
        label: category.categoryTitle,
        slug: categorySlug,
        route: ['/shop', categorySlug],
        subCategories: childLinks
      };
    });
  }

  private buildFallbackMenu(): CategoryMenuItem[] {
    return ['Women', 'Men', 'Kids', 'Fashion', 'Showpiece'].map((label, index) => ({
      id: index + 1,
      label,
      slug: this.toSlug(label),
      route: ['/shop', this.toSlug(label)],
      subCategories: []
    }));
  }

  private toSlug(value: string | null | undefined): string {
    return (value || '')
      .trim()
      .toLowerCase()
      .replace(/&/g, ' and ')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }
}
