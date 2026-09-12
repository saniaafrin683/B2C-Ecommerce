import { Component, OnInit } from '@angular/core';

import { Product } from '../../core/models/product.model';
import { ProductService } from '../../core/services/product.service';

interface HomeCategoryHighlight {
  title: string;
  subtitle: string;
  route: string;
  accent: string;
}

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {
  readonly categoryHighlights: HomeCategoryHighlight[] = [
    {
      title: 'Women Fashion',
      subtitle: 'Fresh silhouettes for daily wear and event-ready looks.',
      route: '/shop/women',
      accent: 'accent-women'
    },
    {
      title: 'Men Essentials',
      subtitle: 'Reliable wardrobe staples with smarter styling details.',
      route: '/shop/men',
      accent: 'accent-men'
    },
   
    {
      title: 'Showpieces',
      subtitle: 'Decor-led picks to round out a polished home mood.',
      route: '/shop/showpiece',
      accent: 'accent-showpiece'
    }
  ];

  isLoadingProducts = true;
  newArrivals: Product[] = [];
  trendingProducts: Product[] = [];
  bestSellers: Product[] = [];

  constructor(private readonly productService: ProductService) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  trackByProduct(_: number, product: Product): number {
    return product.id;
  }

  trackByCategory(_: number, category: HomeCategoryHighlight): string {
    return category.title;
  }

  private loadProducts(): void {
    this.productService.getProducts().subscribe({
      next: (products) => {
        const latestProducts = [...products].sort((left, right) => (right.id || 0) - (left.id || 0));
        const discountedProducts = [...products]
          .filter((product) => (product.discount || 0) > 0)
          .sort((left, right) => (right.discount || 0) - (left.discount || 0) || (right.id || 0) - (left.id || 0));
        const demandProducts = [...products]
          .filter((product) => (product.stock || 0) > 0)
          .sort((left, right) => (left.stock || 0) - (right.stock || 0) || (right.discount || 0) - (left.discount || 0));

        this.newArrivals = this.pickProducts(latestProducts, 4);
        this.trendingProducts = this.pickProducts(discountedProducts.length ? discountedProducts : latestProducts, 4, this.newArrivals);
        this.bestSellers = this.pickProducts(demandProducts.length ? demandProducts : latestProducts, 4, [...this.newArrivals, ...this.trendingProducts]);
        this.isLoadingProducts = false;
      },
      error: () => {
        this.newArrivals = [];
        this.trendingProducts = [];
        this.bestSellers = [];
        this.isLoadingProducts = false;
      }
    });
  }

  private pickProducts(source: Product[], count: number, excluded: Product[] = []): Product[] {
    const excludedIds = new Set(excluded.map((product) => product.id));
    const selected = source.filter((product) => !excludedIds.has(product.id)).slice(0, count);

    if (selected.length === count) {
      return selected;
    }

    const selectedIds = new Set(selected.map((product) => product.id));
    const fallback = source.filter((product) => !selectedIds.has(product.id)).slice(0, count - selected.length);
    return [...selected, ...fallback];
  }
}
