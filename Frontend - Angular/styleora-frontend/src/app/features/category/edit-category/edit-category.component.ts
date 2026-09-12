import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { CategoryService } from '../category.service';
import { Category } from '../category.model';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

@Component({
  selector: 'app-edit-category',
  templateUrl: './edit-category.component.html',
  styleUrls: ['./edit-category.component.css']
})
export class EditCategoryComponent implements OnInit {

  categoryId!: number;
  loading: boolean = false;
  submitting: boolean = false;
  selectedFileName: string = '';

  categoryForm: Category = {
    categoryTitle: '',
    createdBy: '',
    stock: 0,
    tagId: '',
    description: '',
    imageUrl: ''
  };

  createdByOptions: string[] = ['Seller', 'Admin', 'Other'];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private categoryService: CategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.categoryId = +id;
        this.loadCategoryById();
      } else {
        this.notificationService.showError('Invalid category id.');
        this.router.navigate(['/category/list']);
      }
    });
  }

  loadCategoryById(): void {
    this.loading = true;
    this.loadingService.show();

    this.categoryService.getCategoryById(this.categoryId).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Category) => {
        this.categoryForm = res;
        this.selectedFileName = '';
      },
      error: () => {
        this.notificationService.showError('Failed to load category data.');
        this.router.navigate(['/category/list']);
      }
    });
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;

    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      this.selectedFileName = file.name;

      const reader = new FileReader();
      reader.onload = () => {
        this.categoryForm.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    } else {
      this.selectedFileName = '';
    }
  }

  onUpdate(): void {
    this.submitting = true;
    this.loadingService.show();

    this.categoryService.updateCategory(this.categoryId, this.categoryForm).pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Category updated successfully.');
        this.router.navigate(['/category/list']);
      },
      error: () => {
        this.notificationService.showError('Failed to update category.');
      }
    });
  }

  onReset(): void {
    this.loadCategoryById();
    this.selectedFileName = '';
  }

  onCancel(): void {
    this.router.navigate(['/category/list']);
  }
}
