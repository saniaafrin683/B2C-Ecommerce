import { Component } from '@angular/core';
import { BLOG_POSTS, BlogPost } from '../blog-posts.data';

@Component({
  selector: 'app-blog',
  templateUrl: './blog.component.html',
  styleUrls: ['./blog.component.css']
})
export class BlogComponent {
  readonly posts: BlogPost[] = BLOG_POSTS;

  getVisualTheme(category: string): string {
    switch (category) {
      case 'Style Guide':
        return 'theme-style-guide';
      case 'Buying Tips':
        return 'theme-buying-tips';
      case 'Accessories':
        return 'theme-accessories';
      case 'Lifestyle':
        return 'theme-lifestyle';
      default:
        return 'theme-default';
    }
  }
}
