import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Attribute } from './attribute.model';

@Injectable({
  providedIn: 'root'
})
export class AttributeService {
  private readonly baseUrl = 'http://localhost:8080/attributes';

  constructor(private http: HttpClient) {}

  getAttributes(): Observable<Attribute[]> {
    return this.http.get<Attribute[]>(`${this.baseUrl}/list`);
  }

  getAttributeById(id: number): Observable<Attribute> {
    return this.http.get<Attribute>(`${this.baseUrl}/${id}`);
  }

  createAttribute(attribute: Attribute): Observable<Attribute> {
    return this.http.post<Attribute>(`${this.baseUrl}/create`, attribute);
  }

  updateAttribute(id: number, attribute: Attribute): Observable<Attribute> {
    return this.http.put<Attribute>(`${this.baseUrl}/update/${id}`, attribute);
  }

  deleteAttribute(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }
}
