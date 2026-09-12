import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ProductService } from '../product.service';
import { Product } from '../product.model';
import { CategoryService } from '../../category/category.service';
import { Category } from '../../category/category.model';
import { SubCategory } from '../../sub-category/sub-category.model';
import { SubCategoryService } from '../../sub-category/sub-category.service';
import { LoadingService } from '../../../shared/services/loading.service';
import { NotificationService } from '../../../shared/services/notification.service';

const ALLOWED_CATEGORY_TITLES = ['Women', 'Men', 'Kids', 'Fashion', 'Showpiece'];
const PRODUCT_TAG_OPTIONS = [
  'New Arrival',
  'Best Seller',
  'Trending',
  'Featured',
  'Sale',
  'Limited Edition'
];

@Component({
  selector: 'app-edit-product',
  templateUrl: './edit.component.html',
  styleUrls: ['./edit.component.css']
})
export class EditComponent implements OnInit {

  productId!: number;
  categories: Category[] = [];
  subCategories: SubCategory[] = [];
  productTagOptions = PRODUCT_TAG_OPTIONS;
  loading: boolean = false;
  submitting: boolean = false;
  imagePreviewUrl = '';
  private selectedImageFile: File | null = null;

  productForm: Product = {
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

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private productService: ProductService,
    private categoryService: CategoryService,
    private subCategoryService: SubCategoryService,
    private loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadCategories();
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');

      if (id) {
        this.productId = +id;
        this.loadProductById();
      } else {
        this.notificationService.showError('Invalid product id.');
        this.router.navigate(['/products/list']);
      }
    });
  }

  loadProductById(): void {
    this.loading = true;
    this.loadingService.show();

    this.productService.getProductById(this.productId).pipe(
      finalize(() => {
        this.loading = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: (res: Product) => {
        this.productForm = this.buildEditableProduct(res);
        this.imagePreviewUrl = res.imageUrl || '';
        this.selectedImageFile = null;
        this.loadSubCategoriesForSelectedCategory(false);
      },
      error: () => {
        this.notificationService.showError('Failed to load product data.');
        this.router.navigate(['/products/list']);
      }
    });
  }

  onUpdate(): void {
    const normalizedProduct = this.buildEditableProduct(this.productForm);
    console.log('[Styleora Admin][Product Edit] update payload', normalizedProduct);
    this.submitting = true;
    this.loadingService.show();

    const updateRequest = this.selectedImageFile
      ? this.productService.updateProductWithUpload(
          this.productId,
          this.productService.buildProductUploadFormData(normalizedProduct, this.selectedImageFile)
        )
      : this.productService.updateProduct(this.productId, normalizedProduct);

    updateRequest.pipe(
      finalize(() => {
        this.submitting = false;
        this.loadingService.hide();
      })
    ).subscribe({
      next: () => {
        this.notificationService.showSuccess('Product updated successfully.');
        this.router.navigate(['/products/list'], {
          queryParams: { refresh: Date.now() }
        });
      },
      error: () => {
        this.notificationService.showError('Failed to update product.');
      }
    });
  }

  onReset(): void {
    this.loadProductById();
  }

  onCategoryChange(): void {
    this.productForm.subCategoryId = null;
    this.productForm.subCategory = '';
    this.loadSubCategoriesForSelectedCategory(true);
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
    this.imagePreviewUrl = this.productForm.imageUrl || '';
  }

  private loadCategories(): void {
    const cachedCategories = this.categoryService.getCachedCategories();
    this.categories = this.filterAllowedCategories(cachedCategories);
    this.loadSubCategoriesForSelectedCategory(false);

    this.categoryService.getAllCategories().subscribe({
      next: (categories) => {
        this.categories = this.filterAllowedCategories(categories || []);
        this.loadSubCategoriesForSelectedCategory(false);
      },
      error: () => {
        this.categories = this.filterAllowedCategories([]);
        this.loadSubCategoriesForSelectedCategory(false);
      }
    });
  }

  private filterAllowedCategories(categories: Category[]): Category[] {
    const categoryMap = new Map(
      (categories || [])
        .filter((category) => ALLOWED_CATEGORY_TITLES.includes((category.categoryTitle || '').trim()))
        .map((category) => [(category.categoryTitle || '').trim().toLowerCase(), category] as const)
    );

    return ALLOWED_CATEGORY_TITLES.map((title) => {
      const matchedCategory = categoryMap.get(title.toLowerCase());
      return matchedCategory || {
        categoryTitle: title,
        createdBy: '',
        stock: 0,
        tagId: '',
        description: '',
        imageUrl: ''
      };
    });
  }

  private loadSubCategoriesForSelectedCategory(resetSelection: boolean): void {
    const selectedCategory = this.categories.find(
      (category) => category.categoryTitle === this.productForm.category
    );

    if (!selectedCategory?.id) {
      this.subCategories = [];
      if (resetSelection) {
        this.productForm.subCategoryId = null;
        this.productForm.subCategory = '';
      }
      return;
    }

    this.subCategoryService.getSubCategoriesByCategoryId(selectedCategory.id).subscribe({
      next: (subCategories) => {
        this.subCategories = subCategories || [];

        const stillExists = this.subCategories.some(
          (subCategory) => subCategory.id === this.productForm.subCategoryId
        );

        if (!stillExists) {
          this.productForm.subCategoryId = null;
          this.productForm.subCategory = '';
        } else if (!this.productForm.subCategory) {
          this.onSubCategoryChange();
        }
      },
      error: () => {
        this.subCategories = [];
        if (resetSelection) {
          this.productForm.subCategoryId = null;
          this.productForm.subCategory = '';
        }
      }
    });
  }

  private buildEditableProduct(product: Product): Product {
    return {
      ...product,
      name: (product?.name || '').trim(),
      category: (product?.category || '').trim(),
      subCategoryId: product?.subCategoryId ?? null,
      subCategory: (product?.subCategory || '').trim(),
      brand: (product?.brand || '').trim(),
      weight: (product?.weight || '').trim(),
      gender: (product?.gender || '').trim(),
      description: (product?.description || '').trim(),
      tagNumber: (product?.tagNumber || '').trim(),
      stock: this.normalizeInteger(product?.stock),
      tag: (product?.tag || '').trim(),
      price: this.normalizeDecimal(product?.price),
      discount: this.normalizeDecimal(product?.discount),
      tax: this.normalizeDecimal(product?.tax),
      imageUrl: (product?.imageUrl || '').trim()
    };
  }

  private normalizeInteger(value: number | string | null | undefined): number {
    const normalizedValue = Number(value);
    if (!Number.isFinite(normalizedValue)) {
      return 0;
    }

    return Math.max(0, Math.floor(normalizedValue));
  }

  private normalizeDecimal(value: number | string | null | undefined): number {
    const normalizedValue = Number(value);
    if (!Number.isFinite(normalizedValue)) {
      return 0;
    }

    return Math.max(0, normalizedValue);
  }
}
