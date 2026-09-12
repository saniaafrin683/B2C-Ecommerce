import { Component, Input } from '@angular/core';

import { Product } from '../../../core/models/product.model';

@Component({
  selector: 'app-new-arrivals',
  templateUrl: './new-arrivals.component.html',
  styleUrls: ['./new-arrivals.component.css']
})
export class NewArrivalsComponent {
  @Input() products: Product[] = [];
  @Input() isLoading = false;
}
