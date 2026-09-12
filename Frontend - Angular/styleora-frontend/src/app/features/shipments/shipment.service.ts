import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Shipment } from './shipment.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ShipmentService {
  private readonly baseUrl = `${environment.apiBaseUrl}/shipments`;
  private readonly shipmentStatuses = ['Pending', 'Packed', 'Shipped', 'Out For Delivery', 'Delivered'];

  constructor(private http: HttpClient) {}

  getShipments(): Observable<Shipment[]> {
    return this.http.get<Shipment[]>(`${this.baseUrl}/list`).pipe(
      map((shipments) => (shipments || []).map((shipment) => this.normalizeShipment(shipment)))
    );
  }

  getShipmentByOrderId(orderId: number): Observable<Shipment> {
    return this.http.get<Shipment>(`${this.baseUrl}/order/${orderId}`).pipe(
      map((shipment) => this.normalizeShipment(shipment))
    );
  }

  getShipmentById(id: number): Observable<Shipment> {
    return this.http.get<Shipment>(`${this.baseUrl}/${id}`).pipe(
      map((shipment) => this.normalizeShipment(shipment))
    );
  }

  createShipment(shipment: Shipment): Observable<Shipment> {
    return this.http.post<Shipment>(`${this.baseUrl}`, this.toApiPayload(shipment)).pipe(
      map((response) => this.normalizeShipment(response))
    );
  }

  updateShipment(id: number, shipment: Shipment): Observable<Shipment> {
    return this.http.put<Shipment>(`${this.baseUrl}/${id}`, this.toApiPayload(shipment)).pipe(
      map((response) => this.normalizeShipment(response))
    );
  }

  updateShipmentStatus(id: number, shipmentStatus: string): Observable<Shipment> {
    return this.http.put<Shipment>(`${this.baseUrl}/status/${id}`, {
      shipmentStatus: this.normalizeStatus(shipmentStatus)
    }).pipe(
      map((response) => this.normalizeShipment(response))
    );
  }

  deleteShipment(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }

  getShipmentStatuses(): string[] {
    return [...this.shipmentStatuses];
  }

  private toApiPayload(shipment: Shipment): Shipment {
    const shippedDate = this.normalizeDateTime(shipment.shippedDate || shipment.dispatchDate || '');
    const estimatedDeliveryDate = this.normalizeDateTime(shipment.estimatedDeliveryDate || '');
    const deliveredDate = this.normalizeDateTime(shipment.deliveredDate || '');
    const shipmentStatus = this.normalizeStatus(shipment.shipmentStatus ?? shipment.status ?? 'Pending');

    return {
      ...shipment,
      orderId: Number(shipment.orderId ?? 0),
      shippingMethodId: Number(shipment.shippingMethodId ?? 0),
      trackingNumber: (shipment.trackingNumber || '').trim(),
      courierName: (shipment.courierName || '').trim(),
      shipmentStatus,
      status: shipmentStatus,
      shippedDate,
      dispatchDate: shippedDate,
      estimatedDeliveryDate,
      deliveredDate,
      remarks: (shipment.remarks || '').trim()
    };
  }

  private normalizeShipment(shipment: Shipment | null | undefined): Shipment {
    const shipmentStatus = this.normalizeStatus(shipment?.shipmentStatus || shipment?.status || 'Pending');
    const shippedDate = shipment?.shippedDate || shipment?.dispatchDate || '';

    return {
      ...shipment,
      id: shipment?.id,
      orderId: Number(shipment?.orderId ?? 0),
      shippingMethodId: Number(shipment?.shippingMethodId ?? 0),
      trackingNumber: shipment?.trackingNumber || '',
      courierName: shipment?.courierName || '',
      shipmentStatus,
      status: shipmentStatus,
      shippedDate,
      dispatchDate: shippedDate,
      estimatedDeliveryDate: shipment?.estimatedDeliveryDate || '',
      deliveredDate: shipment?.deliveredDate || '',
      remarks: shipment?.remarks || ''
    };
  }

  private normalizeStatus(value: string | null | undefined): string {
    const rawStatus = (value || '').trim().toLowerCase();

    if (!rawStatus || rawStatus === 'created') {
      return 'Pending';
    }

    if (rawStatus === 'confirmed' || rawStatus === 'processing' || rawStatus === 'in progress') {
      return 'Packed';
    }

    if (rawStatus === 'in transit') {
      return 'Shipped';
    }

    if (rawStatus === 'out_for_delivery') {
      return 'Out For Delivery';
    }

    const matchedStatus = this.shipmentStatuses.find((status) => status.toLowerCase() === rawStatus);
    return matchedStatus || 'Pending';
  }

  private normalizeDateTime(value: string | null | undefined): string | undefined {
    const normalizedValue = (value || '').trim();
    if (!normalizedValue) {
      return undefined;
    }

    return normalizedValue.length === 16 ? `${normalizedValue}:00` : normalizedValue;
  }
}
