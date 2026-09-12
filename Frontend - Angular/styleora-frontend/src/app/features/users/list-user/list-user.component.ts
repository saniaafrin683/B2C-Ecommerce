import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { User } from '../user.model';
import { UserService } from '../user.service';

@Component({
  selector: 'app-list-user',
  templateUrl: './list-user.component.html',
  styleUrls: ['./list-user.component.css']
})
export class ListUserComponent implements OnInit {
  users: User[] = [];
  filteredUsers: User[] = [];
  loading = false;
  errorMessage = '';
  searchTerm = '';
  selectedRole = 'ALL';
  selectedStatus = 'ALL';

  readonly roles = ['ALL', 'SUPER_ADMIN', 'ADMIN', 'MANAGER', 'STAFF'];
  readonly statuses = ['ALL', 'ACTIVE', 'INACTIVE'];

  constructor(
    private userService: UserService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadUsers();
  }

  loadUsers(): void {
    this.loading = true;
    this.errorMessage = '';

    this.userService.getUsers().subscribe({
      next: (users) => {
        this.users = users || [];
        this.applyFilters();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to load users.';
      }
    });
  }

  applyFilters(): void {
    const searchValue = this.searchTerm.trim().toLowerCase();

    this.filteredUsers = this.users.filter((user) => {
      const matchesSearch = !searchValue || [
        user.userCode,
        user.firstName,
        user.lastName,
        user.email,
        user.phone
      ].some((value) => (value || '').toLowerCase().includes(searchValue));

      const matchesRole = this.selectedRole === 'ALL' || user.role === this.selectedRole;
      const matchesStatus = this.selectedStatus === 'ALL' || user.status === this.selectedStatus;

      return matchesSearch && matchesRole && matchesStatus;
    });
  }

  onCreate(): void {
    this.router.navigate(['/users/create']);
  }

  onEdit(user: User): void {
    this.router.navigate(['/users/edit', user.id]);
  }

  onDetails(user: User): void {
    this.router.navigate(['/users/details', user.id]);
  }

  onDelete(id: number): void {
    const confirmed = confirm('Are you sure you want to delete this user?');
    if (!confirmed) {
      return;
    }

    this.userService.deleteUser(id).subscribe({
      next: () => this.loadUsers(),
      error: () => {
        this.errorMessage = 'Failed to delete user.';
      }
    });
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

  getFullName(user: User): string {
    return `${user.firstName || ''} ${user.lastName || ''}`.trim() || 'Unnamed User';
  }

  getInitials(user: User): string {
    const initials = `${user.firstName?.charAt(0) || ''}${user.lastName?.charAt(0) || ''}`.toUpperCase();
    return initials || 'U';
  }
}
