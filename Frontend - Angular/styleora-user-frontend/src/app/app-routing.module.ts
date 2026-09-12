import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';

const routes: Routes = [
  {
    path: '',
    loadChildren: () => import('./features/home/home.module').then(m => m.HomeModule)
  },
  {
    path: 'shop',
    loadChildren: () => import('./features/products/products.module').then(m => m.ProductsModule)
  },
  {
    path: 'products',
    redirectTo: 'shop',
    pathMatch: 'full'
  },
  {
    path: 'product/:id',
    loadChildren: () => import('./features/product-details/product-details.module').then(m => m.ProductDetailsModule)
  },
  {
    path: 'category/:categoryName/:subCategory',
    redirectTo: 'shop/:categoryName/:subCategory',
    pathMatch: 'full'
  },
  {
    path: 'category/:categoryName',
    redirectTo: 'shop/:categoryName',
    pathMatch: 'full'
  },
  {
    path: 'category',
    loadChildren: () => import('./features/category/category.module').then(m => m.CategoryModule)
  },
  {
    path: 'cart',
    loadChildren: () => import('./features/cart/cart.module').then(m => m.CartModule)
  },
  {
    path: 'wishlist',
    loadChildren: () => import('./features/wishlist/wishlist.module').then(m => m.WishlistModule)
  },
  {
    path: 'checkout',
    canActivate: [AuthGuard],
    loadChildren: () => import('./features/checkout/checkout.module').then(m => m.CheckoutModule)
  },

  // ✅ ADD HERE (before wildcard)
  {
    path: 'order-success',
    loadChildren: () =>
      import('./features/order-success/order-success.module')
        .then(m => m.OrderSuccessModule)
  },

  {
    path: 'login',
    loadChildren: () => import('./features/auth/auth.module').then(m => m.AuthModule),
    data: { authMode: 'login' }
  },
  {
    path: 'register',
    loadChildren: () => import('./features/auth/auth.module').then(m => m.AuthModule),
    data: { authMode: 'register' }
  },
  {
    path: 'my-orders',
    canActivate: [AuthGuard],
    loadChildren: () => import('./features/orders/orders.module').then(m => m.OrdersModule)
  },
  {
    path: 'my-reviews',
    canActivate: [AuthGuard],
    loadChildren: () => import('./features/my-reviews/my-reviews.module').then(m => m.MyReviewsModule)
  },
  {
    path: 'profile',
    canActivate: [AuthGuard],
    loadChildren: () => import('./features/profile/profile.module').then(m => m.ProfileModule)
  },
  {
    path: 'blog',
    loadChildren: () => import('./features/blog/blog.module').then(m => m.BlogModule)
  },
  {
    path: 'contact',
    loadChildren: () => import('./features/contact/contact.module').then(m => m.ContactModule)
  },
  {
    path: 'hot-deal',
    loadChildren: () =>
      import('./features/hot-deal/hot-deal.module')
        .then(m => m.HotDealModule)
  },

  // ❗ ALWAYS LAST
  {
    path: '**',
    redirectTo: ''
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes, { scrollPositionRestoration: 'enabled' })],
  exports: [RouterModule]
})
export class AppRoutingModule {}
