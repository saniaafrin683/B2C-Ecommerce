import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { FeaturedCategoriesComponent } from './featured-categories/featured-categories.component';
import { HeroSliderComponent } from './hero-slider/hero-slider.component';
import { HotDealBannerComponent } from './hot-deal-banner/hot-deal-banner.component';
import { HomeRoutingModule } from './home-routing.module';
import { HomeComponent } from './home.component';
import { NewArrivalsComponent } from './new-arrivals/new-arrivals.component';
import { TrendingProductsComponent } from './trending-products/trending-products.component';
import { SharedModule } from '../../shared/shared.module';

@NgModule({
  declarations: [
    HomeComponent,
    HeroSliderComponent,
    FeaturedCategoriesComponent,
    NewArrivalsComponent,
    TrendingProductsComponent,
    HotDealBannerComponent
  ],
  imports: [CommonModule, SharedModule, HomeRoutingModule]
})
export class HomeModule {}
