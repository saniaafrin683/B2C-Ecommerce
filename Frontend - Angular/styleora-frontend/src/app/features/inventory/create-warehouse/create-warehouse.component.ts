import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { WarehouseService } from '../warehouse/warehouse.service';
import { Warehouse } from '../warehouse/warehouse.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-create-warehouse',
  templateUrl: './create-warehouse.component.html',
  styleUrls: ['./create-warehouse.component.css']
})
export class CreateWarehouseComponent {

  warehouseForm: Warehouse = {
    warehouseId: '',
    warehouseName: '',
    location: '',
    manager: '',
    contactNumber: '',
    stockAvailable: 0,
    stockShipping: 0,
    warehouseRevenue: 0
  };

  constructor(
    private warehouseService: WarehouseService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private router: Router
  ) {}

  onSave(): void {
    this.loadingService.show();

    this.warehouseService.createWarehouse(this.warehouseForm).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: (res) => {
        this.notificationService.showSuccess('Warehouse created successfully.');
        this.router.navigate(['/inventory/warehouse']);
      },
      error: (err) => {
        console.error('Failed to create warehouse', err);
        this.notificationService.showError('Failed to create warehouse.');
      }
    });
  }

  onReset(): void {
    this.warehouseForm = {
      warehouseId: '',
      warehouseName: '',
      location: '',
      manager: '',
      contactNumber: '',
      stockAvailable: 0,
      stockShipping: 0,
      warehouseRevenue: 0
    };
  }

  onCancel(): void {
    this.router.navigate(['/inventory/warehouse']);
  }
}
