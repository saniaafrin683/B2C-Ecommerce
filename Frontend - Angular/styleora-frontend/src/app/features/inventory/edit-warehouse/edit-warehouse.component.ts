import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { WarehouseService } from '../warehouse/warehouse.service';
import { Warehouse } from '../warehouse/warehouse.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-edit-warehouse',
  templateUrl: './edit-warehouse.component.html',
  styleUrls: ['./edit-warehouse.component.css']
})
export class EditWarehouseComponent implements OnInit {

  warehouseForm: Warehouse = {
    id: 0,
    warehouseId: '',
    warehouseName: '',
    location: '',
    manager: '',
    contactNumber: '',
    stockAvailable: 0,
    stockShipping: 0,
    warehouseRevenue: 0
  };

  loading = false;
  warehouseParamId: number = 0;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private warehouseService: WarehouseService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.warehouseParamId = +id;
        this.loadWarehouse(this.warehouseParamId);
      } else {
        this.notificationService.showError('Warehouse id not found.');
        this.router.navigate(['/inventory/warehouse']);
      }
    });
  }

  loadWarehouse(id: number): void {
    this.loading = true;
    this.loadingService.show();

    this.warehouseService.getWarehouseById(id).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Warehouse) => {
        this.warehouseForm = res;
      },
      error: (err) => {
        console.error('Failed to load warehouse', err);
        this.notificationService.showError('Failed to load warehouse.');
      }
    });
  }

  onUpdate(): void {
    this.loadingService.show();

    this.warehouseService.updateWarehouse(this.warehouseForm).pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Warehouse updated successfully.');
        this.router.navigate(['/inventory/warehouse']);
      },
      error: (err) => {
        console.error('Failed to update warehouse', err);
        this.notificationService.showError('Failed to update warehouse.');
      }
    });
  }

  onReset(): void {
    this.loadWarehouse(this.warehouseParamId);
  }

  onCancel(): void {
    this.router.navigate(['/inventory/warehouse']);
  }
}
