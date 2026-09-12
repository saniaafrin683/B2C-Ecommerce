import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { WarehouseService } from '../warehouse/warehouse.service';
import { Warehouse } from '../warehouse/warehouse.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-warehouse-details',
  templateUrl: './warehouse-details.component.html',
  styleUrls: ['./warehouse-details.component.css']
})
export class WarehouseDetailsComponent implements OnInit {

  warehouse!: Warehouse;
  loading = false;
  warehouseId: number = 0;

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
        this.warehouseId = +id;
        this.loadWarehouse(this.warehouseId);
      } else {
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
        this.warehouse = res;
      },
      error: (err) => {
        console.error('Failed to load warehouse details', err);
        this.notificationService.showError('Failed to load warehouse details.');
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/inventory/warehouse']);
  }

  goToEdit(): void {
    this.router.navigate(['/inventory/edit-warehouse', this.warehouseId]);
  }
}
