import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-quantity-selector',
  templateUrl: './quantity-selector.component.html',
  styleUrls: ['./quantity-selector.component.css']
})
export class QuantitySelectorComponent {
  @Input() quantity = 1;
  @Input() min = 1;
  @Input() max: number | null = null;
  @Output() quantityChange = new EventEmitter<number>();

  decrease(): void {
    const nextQuantity = this.quantity - 1;

    if (nextQuantity < this.min) {
      return;
    }

    this.quantityChange.emit(nextQuantity);
  }

  increase(): void {
    const nextQuantity = this.quantity + 1;

    if (this.max !== null && nextQuantity > this.max) {
      return;
    }

    this.quantityChange.emit(nextQuantity);
  }
}
