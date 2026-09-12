import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { User } from '../user.model';
import { UserService } from '../user.service';

@Component({
  selector: 'app-edit-user',
  templateUrl: './edit-user.component.html',
  styleUrls: ['./edit-user.component.css']
})
export class EditUserComponent implements OnInit {
  userId!: number;
  loading = false;
  submitting = false;
  errorMessage = '';
  private initialFormSnapshot: User = this.createInitialForm();

  readonly roles = ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'STAFF'];
  readonly statuses = ['ACTIVE', 'INACTIVE'];

  userForm: User = this.createInitialForm();

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.userId = +id;
        this.loadUser();
      } else {
        this.router.navigate(['/users/list']);
      }
    });
  }

  loadUser(): void {
    this.loading = true;
    this.errorMessage = '';

    this.userService.getUserById(this.userId).subscribe({
      next: (user) => {
        this.userForm = {
          ...user,
          password: ''
        };
        this.initialFormSnapshot = { ...this.userForm };
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load user.';
      }
    });
  }

  onSave(): void {
    this.errorMessage = '';

    if (!this.userForm.userCode.trim() ||
        !this.userForm.firstName.trim() ||
        !this.userForm.lastName.trim() ||
        !this.userForm.email.trim() ||
        !this.userForm.role.trim() ||
        !this.userForm.status.trim()) {
      this.errorMessage = 'User Code, First Name, Last Name, Email, Role, and Status are required.';
      return;
    }

    this.submitting = true;

    const payload: User = {
      ...this.userForm,
      userCode: this.userForm.userCode.trim(),
      firstName: this.userForm.firstName.trim(),
      lastName: this.userForm.lastName.trim(),
      email: this.userForm.email.trim(),
      phone: (this.userForm.phone || '').trim(),
      password: (this.userForm.password || '').trim(),
      role: this.userForm.role.trim(),
      status: this.userForm.status.trim(),
      avatarUrl: (this.userForm.avatarUrl || '').trim()
    };

    this.userService.updateUser(this.userId, payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/users/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to update user.';
      }
    });
  }

  onReset(): void {
    this.userForm = { ...this.initialFormSnapshot, password: '' };
    this.errorMessage = '';
  }

  onCancel(): void {
    this.router.navigate(['/users/list']);
  }

  private createInitialForm(): User {
    return {
      id: 0,
      userCode: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      password: '',
      role: 'ADMIN',
      status: 'ACTIVE',
      avatarUrl: ''
    };
  }
}
