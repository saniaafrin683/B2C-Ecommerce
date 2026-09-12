import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ShippingMethod } from '../shipping-method.model';
import { ShippingMethodService } from '../shipping-method.service';

@Component({
  selector: 'app-list-shipping-method',
  templateUrl: './list-shipping-method.component.html',
  styleUrls: ['./list-shipping-method.component.css']
})
export class ListShippingMethodComponent implements OnInit {
  shippingMethods: ShippingMethod[] = [];
  filteredShippingMethods: ShippingMethod[] = [];
  loading = false;
  errorMessage = '';
  searchTerm = '';

  constructor(
    private shippingMethodService: ShippingMethodService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadShippingMethods();
  }

  loadShippingMethods(): void {
    this.loading = true;
    this.errorMessage = '';

    this.shippingMethodService.getShippingMethods().subscribe({
      next: (shippingMethods) => {
        this.shippingMethods = shippingMethods || [];
        this.applySearch();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load shipping methods.';
      }
    });
  }

  applySearch(): void {
    const searchValue = this.searchTerm.trim().toLowerCase();
    this.filteredShippingMethods = this.shippingMethods.filter((shippingMethod) => {
      return !searchValue || [
        shippingMethod.name,
        shippingMethod.description,
        shippingMethod.status
      ].some((value) => (value || '').toLowerCase().includes(searchValue));
    });
  }

  onCreate(): void {
    this.router.navigate(['/shipping-methods/create']);
  }

  onDetails(shippingMethod: ShippingMethod): void {
    this.router.navigate(['/shipping-methods/details', shippingMethod.id]);
  }

  onEdit(shippingMethod: ShippingMethod): void {
    this.router.navigate(['/shipping-methods/edit', shippingMethod.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this shipping method?');
    if (!confirmed) {
      return;
    }

    this.shippingMethodService.deleteShippingMethod(id).subscribe({
      next: () => this.loadShippingMethods(),
      error: () => {
        this.errorMessage = 'Failed to delete shipping method.';
      }
    });
  }

  getStatusClass(status: string): string {
    return (status || '').toUpperCase() === 'ACTIVE' ? 'pill-success' : 'pill-danger';
  }
}
