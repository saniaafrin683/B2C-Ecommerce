import { Component } from '@angular/core';

interface FeaturedCategory {
  label: string;
  route: string;
 description: string;
  image: string;
}

@Component({
  selector: 'app-featured-categories',
  templateUrl: './featured-categories.component.html',
  styleUrls: ['./featured-categories.component.css']
})
export class FeaturedCategoriesComponent {

  readonly categories: FeaturedCategory[] = [
    {
      label: 'Women',
      route: '/shop/women',
      description: 'Elegant daily wear, festive edits, and polished wardrobe staples.',
      image: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=80'
    },

    {
      label: 'Men',
      route: '/shop/men',
      description: 'Refined casualwear and sharp essentials for everyday rotation.',
      image: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=900&q=80'
    },

    {
      label: 'Fashion',
      route: '/shop/fashion',
      description: 'Trend-led collections for quick seasonal wardrobe refreshes.',
      image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=900&q=80'
    },

    {
      label: 'Showpiece',
      route: '/shop/showpiece',
      description: 'Decor pieces that add warmth, texture, and gifting appeal.',
      image: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80'
    }
  ];

  trackByLabel(_: number, category: FeaturedCategory): string {
    return category.label;
  }
}