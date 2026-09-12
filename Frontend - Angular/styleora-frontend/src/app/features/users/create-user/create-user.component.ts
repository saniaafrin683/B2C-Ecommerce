import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { User } from '../user.model';
import { UserService } from '../user.service';

@Component({
  selector: 'app-create-user',
  templateUrl: './create-user.component.html',
  styleUrls: ['./create-user.component.css']
})
export class CreateUserComponent {
  submitting = false;
  errorMessage = '';

  readonly roles = ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'STAFF'];
  readonly statuses = ['ACTIVE', 'INACTIVE'];

  userForm: User = this.createInitialForm();

  constructor(
    private userService: UserService,
    private router: Router
  ) {}

  onSave(): void {
    this.errorMessage = '';

    if (!this.userForm.userCode.trim() ||
        !this.userForm.firstName.trim() ||
        !this.userForm.lastName.trim() ||
        !this.userForm.email.trim() ||
        !this.userForm.password.trim() ||
        !this.userForm.role.trim() ||
        !this.userForm.status.trim()) {
      this.errorMessage = 'User Code, First Name, Last Name, Email, Password, Role, and Status are required.';
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
      password: this.userForm.password.trim(),
      role: this.userForm.role.trim(),
      status: this.userForm.status.trim(),
      avatarUrl: (this.userForm.avatarUrl || '').trim()
    };

    this.userService.createUser(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/users/list']);
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Failed to create user.';
      }
    });
  }

  onReset(): void {
    this.userForm = this.createInitialForm();
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
