import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Shipment } from '../shipment.model';
import { ShipmentService } from '../shipment.service';

@Component({
  selector: 'app-list-shipment',
  templateUrl: './list-shipment.component.html',
  styleUrls: ['./list-shipment.component.css']
})
export class ListShipmentComponent implements OnInit {
  shipments: Shipment[] = [];
  loading = false;
  successMessage = '';
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private shipmentService: ShipmentService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe((params) => {
      this.successMessage = params.get('updated') === '1' ? 'Shipment updated successfully.' : '';
    });
    this.loadShipments();
  }

  loadShipments(): void {
    this.loading = true;
    this.errorMessage = '';

    this.shipmentService.getShipments().subscribe({
      next: (shipments) => {
        this.shipments = shipments || [];
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load shipments.';
      }
    });
  }

  onCreate(): void {
    this.router.navigate(['/shipments/create']);
  }

  onDetails(shipment: Shipment): void {
    this.router.navigate(['/shipments/details', shipment.id]);
  }

  onEdit(shipment: Shipment): void {
    this.router.navigate(['/shipments/edit', shipment.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this shipment?');
    if (!confirmed) {
      return;
    }

    this.shipmentService.deleteShipment(id).subscribe({
      next: () => this.loadShipments(),
      error: () => {
        this.errorMessage = 'Failed to delete shipment.';
      }
    });
  }

  getStatusClass(status: string): string {
    const normalized = (status || '').toUpperCase();
    if (normalized === 'DELIVERED') {
      return 'pill-success';
    }
    if (normalized === 'FAILED' || normalized === 'RETURNED') {
      return 'pill-danger';
    }
    if (normalized === 'OUT_FOR_DELIVERY' || normalized === 'IN_TRANSIT' || normalized === 'SHIPPED') {
      return 'pill-warning';
    }
    return 'pill-info';
  }
}
