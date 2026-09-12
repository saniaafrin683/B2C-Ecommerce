import { Component, OnInit } from '@angular/core';

import { ProductService } from '../../../core/services/product.service';
import { Product } from '../../../core/models/product.model';

@Component({
  selector: 'app-hot-deal',
  templateUrl: './hot-deal.component.html',
  styleUrls: ['./hot-deal.component.css']
})
export class HotDealComponent implements OnInit {

  products: Product[] = [];
  hotDeals: Product[] = [];
  isLoading = true;
  errorMessage = '';

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    this.loadHotDeals();
  }

  loadHotDeals(): void {
    this.isLoading = true;
    this.errorMessage = '';

    this.productService.getProducts().subscribe({
      next: (res: Product[]) => {
        this.products = res || [];

        this.hotDeals = this.products
          .filter(p => p.discount && p.discount > 0)
          .sort((a, b) => (b.discount || 0) - (a.discount || 0))
          .slice(0, 12);

        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Failed to load hot deals';
        this.isLoading = false;
      }
    });
  }
}