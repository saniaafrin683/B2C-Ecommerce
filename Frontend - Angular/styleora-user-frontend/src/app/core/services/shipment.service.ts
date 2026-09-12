import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';

export interface ShipmentDetails {
  id: number;
  orderId: number;
  trackingNumber?: string;
  courierName?: string;
  shipmentStatus?: string;
  shippedDate?: string;
  estimatedDeliveryDate?: string;
  deliveredDate?: string;
  remarks?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ShipmentService {
  private readonly apiBaseUrl = environment.apiBaseUrl || 'http://localhost:8080';

  constructor(private readonly http: HttpClient) {}

  getShipmentByOrderId(orderId: number): Observable<ShipmentDetails> {
    return this.http.get<ShipmentDetails>(`${this.apiBaseUrl}/shipments/order/${orderId}`);
  }
}
