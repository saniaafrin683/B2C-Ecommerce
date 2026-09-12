import { Component, Input } from '@angular/core';

import { Product } from '../../../core/models/product.model';

@Component({
  selector: 'app-product-grid',
  templateUrl: './product-grid.component.html',
  styleUrls: ['./product-grid.component.css']
})
export class ProductGridComponent {
  @Input() products: Product[] = [];
  @Input() variant: 'default' | 'home' = 'default';

  get columnClasses(): string {
    return this.variant === 'home'
      ? 'col-12 col-sm-6 col-lg-4 col-xl-3'
      : 'col-12 col-sm-6 col-lg-4';
  }
}
