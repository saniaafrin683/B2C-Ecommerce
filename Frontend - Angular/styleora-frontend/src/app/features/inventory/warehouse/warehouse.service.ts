import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Warehouse } from './warehouse.model';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class WarehouseService {

  private readonly baseUrl = `${environment.apiBaseUrl}/warehouses`;

  constructor(private http: HttpClient) {}

  getAllWarehouses(): Observable<Warehouse[]> {
    return this.http.get<Warehouse[]>(this.baseUrl + '/list');
  }

  getWarehouseById(id: number): Observable<Warehouse> {
    return this.http.get<Warehouse>(this.baseUrl + '/' + id);
  }

  createWarehouse(warehouse: Warehouse): Observable<any> {
    return this.http.post(this.baseUrl + '/create', warehouse, {
      responseType: 'text'
    });
  }

  updateWarehouse(warehouse: Warehouse): Observable<any> {
    return this.http.put(this.baseUrl + '/update', warehouse, {
      responseType: 'text'
    });
  }

  deleteWarehouse(id: number): Observable<any> {
    return this.http.delete(this.baseUrl + '/delete/' + id, {
      responseType: 'text'
    });
  }
}
