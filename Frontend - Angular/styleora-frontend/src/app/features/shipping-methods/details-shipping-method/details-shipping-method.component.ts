import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ShippingMethod } from '../shipping-method.model';
import { ShippingMethodService } from '../shipping-method.service';

@Component({
  selector: 'app-details-shipping-method',
  templateUrl: './details-shipping-method.component.html',
  styleUrls: ['./details-shipping-method.component.css']
})
export class DetailsShippingMethodComponent implements OnInit {
  shippingMethodId!: number;
  loading = false;
  errorMessage = '';
  shippingMethod: ShippingMethod | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private shippingMethodService: ShippingMethodService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.shippingMethodId = +id;
        this.loadShippingMethod();
      } else {
        this.router.navigate(['/shipping-methods/list']);
      }
    });
  }

  loadShippingMethod(): void {
    this.loading = true;
    this.errorMessage = '';

    this.shippingMethodService.getShippingMethodById(this.shippingMethodId).subscribe({
      next: (shippingMethod) => {
        this.shippingMethod = shippingMethod;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load shipping method details.';
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/shipping-methods/list']);
  }

  onEdit(): void {
    this.router.navigate(['/shipping-methods/edit', this.shippingMethodId]);
  }

  getStatusClass(status: string): string {
    return (status || '').toUpperCase() === 'ACTIVE' ? 'pill-success' : 'pill-danger';
  }
}
