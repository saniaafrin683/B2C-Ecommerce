import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Shipment } from '../shipment.model';
import { ShipmentService } from '../shipment.service';

@Component({
  selector: 'app-details-shipment',
  templateUrl: './details-shipment.component.html',
  styleUrls: ['./details-shipment.component.css']
})
export class DetailsShipmentComponent implements OnInit {
  shipmentId!: number;
  loading = false;
  errorMessage = '';
  shipment: Shipment | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private shipmentService: ShipmentService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.shipmentId = +id;
        this.loadShipment();
      } else {
        this.router.navigate(['/shipments/list']);
      }
    });
  }

  loadShipment(): void {
    this.loading = true;
    this.errorMessage = '';

    this.shipmentService.getShipmentById(this.shipmentId).subscribe({
      next: (shipment) => {
        this.shipment = shipment;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load shipment details.';
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/shipments/list']);
  }

  onEdit(): void {
    this.router.navigate(['/shipments/edit', this.shipmentId]);
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
