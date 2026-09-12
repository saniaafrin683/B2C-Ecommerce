import { Component } from '@angular/core';

interface ContactInfoCard {
  title: string;
  value: string;
  detail: string;
  icon: string;
}

interface SupportCard {
  title: string;
  description: string;
}

@Component({
  selector: 'app-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.css']
})
export class ContactComponent {
  readonly contactCards: ContactInfoCard[] = [
    {
      title: 'Address',
      value: 'Dhaka, Bangladesh',
      detail: 'Visit our office for customer care and general inquiries.',
      icon: 'bi-geo-alt'
    },
    {
      title: 'Phone',
      value: '+880 1710-000000',
      detail: 'Talk to the Styleora team for order and delivery support.',
      icon: 'bi-telephone'
    },
    {
      title: 'Email',
      value: 'support@styleora.com',
      detail: 'Send product, payment, or account questions any time.',
      icon: 'bi-envelope'
    },
    {
      title: 'Working Hours',
      value: 'Sat-Thu, 10:00 AM - 8:00 PM',
      detail: 'Our support team is available throughout the shopping week.',
      icon: 'bi-clock'
    }
  ];

  readonly supportCards: SupportCard[] = [
    {
      title: 'Customer Support',
      description: 'General help with account access, shopping guidance, and store questions.'
    },
    {
      title: 'Order Help',
      description: 'Track your order, confirm payment details, or get delivery assistance.'
    },
    {
      title: 'Return & Refund Help',
      description: 'Understand return eligibility and connect with our team for refund support.'
    }
  ];

  formSubmitted = false;

  submitForm(): void {
    this.formSubmitted = true;
  }
}
