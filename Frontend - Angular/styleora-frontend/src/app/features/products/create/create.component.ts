import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ProductService } from '../product.service';
import { Product } from '../product.model';
import { CategoryService } from '../../category/category.service';
import { Category } from '../../category/category.model';
import { SubCategory } from '../../sub-category/sub-category.model';
import { SubCategoryService } from '../../sub-category/sub-category.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

const PRODUCT_TAG_OPTIONS = [
  'New Arrival',
  'Best Seller',
  'Trending',
  'Featured',
  'Sale',
  'Limited Edition'
];

@Component({
  selector: 'app-create-product',
  templateUrl: './create.component.html',
  styleUrls: ['./create.component.css']
})
export class CreateComponent implements OnInit {
  categories: Category[] = [];
  subCategories: SubCategory[] = [];
  productTagOptions = PRODUCT_TAG_OPTIONS;
  errorMessage = '';
  successMessage = '';
  imagePreviewUrl = '';
  private selectedImageFile: File | null = null;

  selectedSizes: string[] = ['M', 'L'];
  selectedColors: string[] = ['#ff6c2f', '#22c55e', '#3b82f6'];

  productForm: Product = this.createEmptyProduct();

  constructor(
    private productService: ProductService,
    private categoryService: CategoryService,
    private subCategoryService: SubCategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCategories();
  }

  onSave(): void {
    this.errorMessage = '';
    this.successMessage = '';
    this.loadingService.show();

    const saveRequest = this.selectedImageFile
      ? this.productService.createProductWithUpload(
          this.productService.buildProductUploadFormData(this.productForm, this.selectedImageFile)
        )
      : this.productService.createProduct(this.productForm);

    saveRequest.pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: () => {
        this.successMessage = 'Product created successfully.';
        this.notificationService.showSuccess('Product created successfully.');
        this.router.navigate(['/products/list']);
      },
      error: () => {
        this.errorMessage = 'Failed to create product. Please review the form and try again.';
        this.notificationService.showError(this.errorMessage);
      }
    });
  }

  onReset(): void {
    this.errorMessage = '';
    this.successMessage = '';
    this.selectedImageFile = null;
    this.imagePreviewUrl = '';
    this.productForm = this.createEmptyProduct();
    this.subCategories = [];
    this.selectedSizes = ['M', 'L'];
    this.selectedColors = ['#ff6c2f', '#22c55e', '#3b82f6'];
  }

  onCategoryChange(): void {
    this.productForm.subCategoryId = null;
    this.productForm.subCategory = '';
    this.loadSubCategoriesForSelectedCategory();
  }

  onSubCategoryChange(): void {
    const selectedSubCategory = this.subCategories.find(
      (subCategory) => subCategory.id === this.productForm.subCategoryId
    );
    this.productForm.subCategory = selectedSubCategory?.subCategoryName || '';
  }

  onCancel(): void {
    this.router.navigate(['/products/list']);
  }

  onProductTagSelect(tag: string): void {
    this.productForm.tag = tag;
  }

  isSelectedProductTag(tag: string): boolean {
    return (this.productForm.tag || '').trim().toLowerCase() === tag.toLowerCase();
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];

    if (file) {
      this.selectedImageFile = file;
      const reader = new FileReader();

      reader.onload = () => {
        this.imagePreviewUrl = reader.result as string;
      };

      reader.readAsDataURL(file);
      return;
    }

    this.selectedImageFile = null;
    this.imagePreviewUrl = '';
  }

  private loadCategories(): void {
    const cachedCategories = this.categoryService.getCachedCategories();

    if (cachedCategories.length > 0) {
      this.categories = cachedCategories;
    }

    this.loadingService.show();

    this.categoryService.getAllCategories().pipe(
      finalize(() => this.loadingService.hide())
    ).subscribe({
      next: (categories) => {
        this.categories = categories || [];
        this.loadSubCategoriesForSelectedCategory();
      },
      error: () => {
        this.categories = [];
        this.loadSubCategoriesForSelectedCategory();
      }
    });
  }

  private loadSubCategoriesForSelectedCategory(): void {
    const selectedCategory = this.categories.find(
      (category) => category.categoryTitle === this.productForm.category
    );

    if (!selectedCategory?.id) {
      this.subCategories = [];
      return;
    }

    this.subCategoryService.getSubCategoriesByCategoryId(selectedCategory.id).subscribe({
      next: (subCategories) => {
        this.subCategories = subCategories || [];
      },
      error: () => {
        this.subCategories = [];
      }
    });
  }

  private createEmptyProduct(): Product {
    return {
      name: '',
      category: '',
      subCategoryId: null,
      subCategory: '',
      brand: '',
      weight: '',
      gender: '',
      description: '',
      tagNumber: '',
      stock: 0,
      tag: '',
      price: 0,
      discount: 0,
      tax: 0,
      imageUrl: ''
    };
  }
}