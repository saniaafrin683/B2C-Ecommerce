import { Component, OnDestroy, OnInit } from '@angular/core';

interface HeroSlide {
  eyebrow: string;
  title: string;
  description: string;
  image: string;
  shopLink: string;
  accent: string;
}

@Component({
  selector: 'app-hero-slider',
  templateUrl: './hero-slider.component.html',
  styleUrls: ['./hero-slider.component.css']
})
export class HeroSliderComponent implements OnInit, OnDestroy {
  readonly slides: HeroSlide[] = [
    {
      eyebrow: 'Summer Collection',
      title: 'Fresh silhouettes for everyday style and festive plans.',
      description: 'Explore elevated women, men, and kidswear styled with the warm, polished storefront feel of a modern Bangladeshi fashion house.',
      image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1600&q=80',
      shopLink: '/shop',
      accent: 'Women, Men, Kids'
    },
    {
      eyebrow: 'Family Edit',
      title: 'Comfortable fashion essentials curated for the whole family.',
      description: 'From relaxed weekend looks to dressed-up wardrobe staples, Styleora keeps the catalog clean, wearable, and gift-ready.',
      image: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1600&q=80',
      shopLink: '/shop',
      accent: 'Family Edit'
    },
    {
      eyebrow: 'Home And Fashion',
      title: 'Style your wardrobe and your space from one destination.',
      description: 'Pair fashion-led apparel with decorative showpieces in a storefront built for easy discovery and quick seasonal browsing.',
      image: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1600&q=80',
      shopLink: '/shop/showpiece',
      accent: 'Fashion + Showpiece'
    }
  ];

  currentSlide = 0;
  private slideIntervalId: number | undefined;

  get activeSlide(): HeroSlide {
    return this.slides[this.currentSlide];
  }

  ngOnInit(): void {
    this.slideIntervalId = window.setInterval(() => {
      this.currentSlide = (this.currentSlide + 1) % this.slides.length;
    }, 5000);
  }

  ngOnDestroy(): void {
    if (this.slideIntervalId) {
      window.clearInterval(this.slideIntervalId);
    }
  }

  goToSlide(index: number): void {
    this.currentSlide = index;
    this.restartAutoSlide();
  }

  previousSlide(): void {
    this.currentSlide = (this.currentSlide - 1 + this.slides.length) % this.slides.length;
    this.restartAutoSlide();
  }

  nextSlide(): void {
    this.currentSlide = (this.currentSlide + 1) % this.slides.length;
    this.restartAutoSlide();
  }

  private restartAutoSlide(): void {
    if (this.slideIntervalId) {
      window.clearInterval(this.slideIntervalId);
    }

    this.slideIntervalId = window.setInterval(() => {
      this.currentSlide = (this.currentSlide + 1) % this.slides.length;
    }, 5000);
  }
}
