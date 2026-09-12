import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { RoleGuard } from './core/guards/role.guard';
import {
  CUSTOMER_VIEW_ROLES,
  DASHBOARD_ACCESS_ROLES,
  MODERATION_ACCESS_ROLES,
  ORDER_VIEW_ROLES,
  SALES_ACCESS_ROLES
} from './core/auth/admin-role.model';

import { LayoutMainComponent } from './layout/layout-main/layout-main.component';
import { LoginComponent } from './features/auth/login/login.component';

import { DashboardComponent } from './features/dashboard/dashboard.component';
import { AccessDeniedComponent } from './features/access-denied/access-denied.component';

import { CreateComponent } from './features/products/create/create.component';
import { ListComponent } from './features/products/list/list.component';
import { EditComponent } from './features/products/edit/edit.component';
import { DetailsComponent } from './features/products/details/details.component';
import { GridComponent } from './features/products/grid/grid.component';

import { CreateCategoryComponent } from './features/category/create-category/create-category.component';
import { ListCategoryComponent } from './features/category/list-category/list-category.component';
import { EditCategoryComponent } from './features/category/edit-category/edit-category.component';
import { CreateSubCategoryComponent } from './features/sub-category/create/create-sub-category.component';
import { SubCategoryListComponent } from './features/sub-category/list/sub-category-list.component';
import { EditSubCategoryComponent } from './features/sub-category/edit/edit-sub-category.component';

import { WarehouseComponent } from './features/inventory/warehouse/warehouse.component';
import { CreateWarehouseComponent } from './features/inventory/create-warehouse/create-warehouse.component';
import { EditWarehouseComponent } from './features/inventory/edit-warehouse/edit-warehouse.component';
import { WarehouseDetailsComponent } from './features/inventory/warehouse-details/warehouse-details.component';
import { ReceivedOrdersComponent } from './features/inventory/received-orders/received-orders.component';
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

const routes: Routes = [
  { path: 'login', component: LoginComponent },
  {
    path: '',
    component: LayoutMainComponent,
    canActivate: [AuthGuard],
    canActivateChild: [AuthGuard, RoleGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },

      { path: 'dashboard', component: DashboardComponent, data: { allowedRoles: DASHBOARD_ACCESS_ROLES } },
      { path: 'access-denied', component: AccessDeniedComponent, data: { allowedRoles: DASHBOARD_ACCESS_ROLES } },

      { path: 'products/create', component: CreateComponent },
      { path: 'products/list', component: ListComponent },
      { path: 'products/grid', component: GridComponent },
      { path: 'products/edit/:id', component: EditComponent },
      { path: 'products/details/:id', component: DetailsComponent },

      { path: 'category/list', component: ListCategoryComponent },
      { path: 'category/create', component: CreateCategoryComponent },
      { path: 'category/edit/:id', component: EditCategoryComponent },
      { path: 'sub-category/list', component: SubCategoryListComponent },
      { path: 'sub-category/create', component: CreateSubCategoryComponent },
      { path: 'sub-category/edit/:id', component: EditSubCategoryComponent },

      { path: 'inventory/warehouse', component: WarehouseComponent },
      { path: 'inventory/current-stock', component: CurrentStockComponent },
      { path: 'inventory/create-warehouse', component: CreateWarehouseComponent },
      { path: 'inventory/edit-warehouse/:id', component: EditWarehouseComponent },
      { path: 'inventory/warehouse-details/:id', component: WarehouseDetailsComponent },
      { path: 'inventory/received-orders', component: ReceivedOrdersComponent },
      { path: 'inventory/create-received-order', component: CreateReceivedOrderComponent },
      { path: 'inventory/edit-received-order/:id', component: EditReceivedOrderComponent },
      { path: 'inventory/received-order-details/:id', component: ReceivedOrderDetailsComponent },

      { path: 'purchases/list', component: ListPurchaseComponent },
      { path: 'purchases/create', component: CreatePurchaseComponent },
      { path: 'purchases/details/:id', component: PurchaseDetailsComponent },
      { path: 'purchases/edit/:id', component: EditPurchaseComponent },
      { path: 'purchases/order', component: PurchaseOrderComponent },
      { path: 'purchases/order/create', component: CreatePurchaseOrderComponent },
      { path: 'purchases/return', component: PurchaseReturnComponent },
      { path: 'purchases/return/create', component: PurchaseReturnFormComponent },
      { path: 'purchases/return/edit/:id', component: PurchaseReturnFormComponent },
      { path: 'attributes/list', component: AttributeListComponent },
      { path: 'attributes/create', component: CreateAttributeComponent },
      { path: 'attributes/edit/:id', component: EditAttributeComponent },
      { path: 'attributes/details/:id', component: DetailsAttributeComponent },
      { path: 'attributes/values', component: AttributeValueListComponent },
      { path: 'attributes/values/create', component: CreateAttributeValueComponent },
      { path: 'attributes/values/edit/:id', component: EditAttributeValueComponent },
      {
        path: 'coupons',
        loadChildren: () => import('./features/coupons/coupons.module').then(m => m.CouponsModule)
      },
      {
        path: 'customers',
        canLoad: [RoleGuard],
        data: { allowedRoles: CUSTOMER_VIEW_ROLES },
        loadChildren: () => import('./features/customers/customers.module').then(m => m.CustomersModule)
      },
      {
        path: 'invoices',
        canLoad: [RoleGuard],
        data: { allowedRoles: SALES_ACCESS_ROLES },
        loadChildren: () => import('./features/invoices/invoices.module').then(m => m.InvoicesModule)
      },
      {
        path: 'payments',
        canLoad: [RoleGuard],
        data: { allowedRoles: SALES_ACCESS_ROLES },
        loadChildren: () => import('./features/payments/payments.module').then(m => m.PaymentsModule)
      },
      {
        path: 'reviews',
        canLoad: [RoleGuard],
        data: { allowedRoles: MODERATION_ACCESS_ROLES },
        loadChildren: () => import('./features/reviews/reviews.module').then(m => m.ReviewsModule)
      },
      {
        path: 'roles',
        loadChildren: () => import('./features/roles/roles.module').then(m => m.RolesModule)
      },
      {
        path: 'returns',
        canLoad: [RoleGuard],
        data: { allowedRoles: MODERATION_ACCESS_ROLES },
        loadChildren: () => import('./features/returns/returns.module').then(m => m.ReturnsModule)
      },
      {
        path: 'reports',
        canLoad: [RoleGuard],
        data: { allowedRoles: DASHBOARD_ACCESS_ROLES },
        loadChildren: () => import('./features/reports/reports.module').then(m => m.ReportsModule)
      },
      {
        path: 'settings',
        loadChildren: () => import('./features/settings/settings.module').then(m => m.SettingsModule)
      },
      {
        path: 'shipping-methods',
        loadChildren: () => import('./features/shipping-methods/shipping-methods.module').then(m => m.ShippingMethodsModule)
      },
      {
        path: 'shipments',
        canLoad: [RoleGuard],
        data: { allowedRoles: SALES_ACCESS_ROLES },
        loadChildren: () => import('./features/shipments/shipments.module').then(m => m.ShipmentsModule)
      },
      {
        path: 'users',
        loadChildren: () => import('./features/users/users.module').then(m => m.UsersModule)
      },

      {
        path: 'orders',
        canLoad: [RoleGuard],
        data: { allowedRoles: ORDER_VIEW_ROLES },
        loadChildren: () => import('./features/orders/orders.module').then(m => m.OrdersModule)
      }
    ]
  },

  { path: '**', redirectTo: 'login' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}
