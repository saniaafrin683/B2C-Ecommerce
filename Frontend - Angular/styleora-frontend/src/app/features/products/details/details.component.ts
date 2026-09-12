import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ProductService } from '../product.service';
import { Product } from '../product.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';
import { getProductDisplayPrice } from '../../../shared/utils/product-price.util';

@Component({
  selector: 'app-details',
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.css']
})
export class DetailsComponent implements OnInit {

  productId: number | null = null;
  product!: Product;
  loading: boolean = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private productService: ProductService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.productId = +id;
        this.loadProductDetails(this.productId);
      } else {
        this.router.navigate(['/products/list']);
      }
    });
  }

  loadProductDetails(id: number): void {
    this.loading = true;
    this.loadingService.show();

    this.productService.getProductById(id).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Product) => {
        this.product = res;
      },
      error: () => {
        this.notificationService.showError('Failed to load product details.');
        this.router.navigate(['/products/list']);
      }
    });
  }

  goToEdit(): void {
    if (!this.productId) {
      return;
    }

    this.router.navigate(['/products/edit', this.productId]);
  }

  goBack(): void {
    this.router.navigate(['/products/list']);
  }

  getProductImage(): string {
    if (this.product && this.product.imageUrl && this.product.imageUrl.trim() !== '') {
      return this.product.imageUrl;
    }
    return 'https://via.placeholder.com/500x500?text=Product';
  }

  getDisplayPrice(): number {
    return getProductDisplayPrice(this.product);
  }
}
