import { Component, Input } from '@angular/core';

import { Product } from '../../../core/models/product.model';

@Component({
  selector: 'app-trending-products',
  templateUrl: './trending-products.component.html',
  styleUrls: ['./trending-products.component.css']
})
export class TrendingProductsComponent {
  @Input() products: Product[] = [];
  @Input() isLoading = false;
}
