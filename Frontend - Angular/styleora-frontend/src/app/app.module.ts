import { APP_INITIALIZER, NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

import { LayoutMainComponent } from './layout/layout-main/layout-main.component';
import { SidebarComponent } from './layout/sidebar/sidebar.component';
import { TopbarComponent } from './layout/topbar/topbar.component';

import { DashboardComponent } from './features/dashboard/dashboard.component';
import { LoginComponent } from './features/auth/login/login.component';
import { AccessDeniedComponent } from './features/access-denied/access-denied.component';

import { CreateComponent } from './features/products/create/create.component';
import { ListComponent } from './features/products/list/list.component';
import { EditComponent } from './features/products/edit/edit.component';
import { DetailsComponent as ProductDetailsComponent } from './features/products/details/details.component';
import { GridComponent } from './features/products/grid/grid.component';

import { CreateCategoryComponent } from './features/category/create-category/create-category.component';
import { EditCategoryComponent } from './features/category/edit-category/edit-category.component';
import { ListCategoryComponent } from './features/category/list-category/list-category.component';
import { CreateSubCategoryComponent } from './features/sub-category/create/create-sub-category.component';
import { EditSubCategoryComponent } from './features/sub-category/edit/edit-sub-category.component';
import { SubCategoryListComponent } from './features/sub-category/list/sub-category-list.component';

import { WarehouseComponent } from './features/inventory/warehouse/warehouse.component';
import { ReceivedOrdersComponent } from './features/inventory/received-orders/received-orders.component';
import { CreateWarehouseComponent } from './features/inventory/create-warehouse/create-warehouse.component';
import { EditWarehouseComponent } from './features/inventory/edit-warehouse/edit-warehouse.component';
import { WarehouseDetailsComponent } from './features/inventory/warehouse-details/warehouse-details.component';
import { CreateReceivedOrderComponent } from './features/inventory/create-received-order/create-received-order.component';
import { EditReceivedOrderComponent } from './features/inventory/edit-received-order/edit-received-order.component';
import { ReceivedOrderDetailsComponent } from './features/inventory/received-order-details/received-order-details.component';
import { CurrentStockComponent } from './features/inventory/current-stock/current-stock.component';
import { ListPurchaseComponent } from './features/purchases/list/list-purchase.component';
import { CreatePurchaseComponent } from './features/purchases/create/create-purchase.component';
import { PurchaseDetailsComponent } from './features/purchases/details/purchase-details.component';
import { EditPurchaseComponent } from './features/purchases/edit/edit-purchase.component';
import { PurchaseOrderComponent } from './features/purchases/order/purchase-order.component';
import { CreatePurchaseOrderComponent } from './features/purchases/order/create-purchase-order/create-purchase-order.component';
import { PurchaseReturnComponent } from './features/purchases/return/purchase-return.component';
import { PurchaseReturnFormComponent } from './features/purchases/return/purchase-return-form.component';
import { AttributeListComponent } from './features/attributes/list/attribute-list.component';
import { CreateAttributeComponent } from './features/attributes/create/create-attribute.component';
import { EditAttributeComponent } from './features/attributes/edit/edit-attribute.component';
import { DetailsAttributeComponent } from './features/attributes/details/details-attribute.component';
import { AttributeValueListComponent } from './features/attributes/values/list/attribute-value-list.component';
import { CreateAttributeValueComponent } from './features/attributes/values/create/create-attribute-value.component';
import { EditAttributeValueComponent } from './features/attributes/values/edit/edit-attribute-value.component';
import { SettingsService } from './core/services/settings.service';
import { AuthInterceptor } from './core/interceptors/auth.interceptor';
import { SharedModule } from './shared/shared.module';

export function initializeSettings(settingsService: SettingsService): () => Promise<void> {
  return () => settingsService.loadSettings();
}

@NgModule({
  declarations: [
    AppComponent,
    LayoutMainComponent,
    SidebarComponent,
    TopbarComponent,

    DashboardComponent,
    LoginComponent,
    AccessDeniedComponent,

    CreateComponent,
    ListComponent,
    EditComponent,
    ProductDetailsComponent,
    GridComponent,

    CreateCategoryComponent,
    EditCategoryComponent,
    ListCategoryComponent,
    CreateSubCategoryComponent,
    EditSubCategoryComponent,
    SubCategoryListComponent,

    WarehouseComponent,
    CurrentStockComponent,
    ReceivedOrdersComponent,
    CreateWarehouseComponent,
    EditWarehouseComponent,
    WarehouseDetailsComponent,
    CreateReceivedOrderComponent,
    EditReceivedOrderComponent,
    ReceivedOrderDetailsComponent,

    ListPurchaseComponent,
    CreatePurchaseComponent,
    PurchaseDetailsComponent,
    EditPurchaseComponent,
    PurchaseOrderComponent,
    CreatePurchaseOrderComponent,
    PurchaseReturnComponent,
    PurchaseReturnFormComponent,
    AttributeListComponent,
    CreateAttributeComponent,
    EditAttributeComponent,
    DetailsAttributeComponent,
    AttributeValueListComponent,
    CreateAttributeValueComponent,
    EditAttributeValueComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
    HttpClientModule,
    SharedModule
  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initializeSettings,
      deps: [SettingsService],
      multi: true
    },
    {
      provide: HTTP_INTERCEPTORS,
      useClass: AuthInterceptor,
      multi: true
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
