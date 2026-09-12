import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Setting } from './setting.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SettingService {
  private readonly baseUrl = `${environment.apiBaseUrl}/settings`;

  constructor(private http: HttpClient) {}

  getCurrentSetting(): Observable<Setting> {
    return this.http.get<Setting>(this.baseUrl);
  }

  saveSetting(setting: Setting): Observable<Setting> {
    return this.http.post<Setting>(`${this.baseUrl}/save`, setting);
  }

  updateSetting(id: number, setting: Setting): Observable<Setting> {
    return this.http.put<Setting>(`${this.baseUrl}/update/${id}`, setting);
  }

  deleteSetting(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/delete/${id}`);
  }
}
