import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { User } from '../user.model';
import { UserService } from '../user.service';

@Component({
  selector: 'app-details-user',
  templateUrl: './details-user.component.html',
  styleUrls: ['./details-user.component.css']
})
export class DetailsUserComponent implements OnInit {
  userId!: number;
  loading = false;
  errorMessage = '';
  user: User | null = null;

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
        this.user = user;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load user details.';
      }
    });
  }

  onBack(): void {
    this.router.navigate(['/users/list']);
  }

  onEdit(): void {
    this.router.navigate(['/users/edit', this.userId]);
  }

  getStatusClass(status: string): string {
    return (status || '').toUpperCase() === 'ACTIVE' ? 'pill-success' : 'pill-danger';
  }

  getRoleClass(role: string): string {
    switch ((role || '').toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'role-super-admin';
      case 'ADMIN':
        return 'role-admin';
      case 'MANAGER':
        return 'role-manager';
      default:
        return 'role-staff';
    }
  }

  getFullName(): string {
    return `${this.user?.firstName || ''} ${this.user?.lastName || ''}`.trim();
  }

  getInitials(): string {
    const initials = `${this.user?.firstName?.charAt(0) || ''}${this.user?.lastName?.charAt(0) || ''}`.toUpperCase();
    return initials || 'U';
  }
}
