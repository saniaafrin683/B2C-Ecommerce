import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { BLOG_POSTS, BlogPost } from '../blog-posts.data';

@Component({
  selector: 'app-blog-details',
  templateUrl: './blog-details.component.html',
  styleUrls: ['./blog-details.component.css']
})
export class BlogDetailsComponent implements OnInit {
  post: BlogPost | null = null;
  relatedPosts: BlogPost[] = [];

  constructor(
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    const postId = this.route.snapshot.paramMap.get('id') || '';
    this.post = BLOG_POSTS.find((item) => item.id === postId) || null;

    if (!this.post) {
      this.router.navigate(['/blog']);
      return;
    }

    this.relatedPosts = BLOG_POSTS.filter((item) => item.id !== this.post?.id).slice(0, 2);
  }
}
