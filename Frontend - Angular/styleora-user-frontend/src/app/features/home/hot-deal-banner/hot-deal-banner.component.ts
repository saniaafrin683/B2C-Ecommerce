import { Component, Input } from '@angular/core';

interface DealCountdown {
  days: string;
  hours: string;
  minutes: string;
  seconds: string;
}

@Component({
  selector: 'app-hot-deal-banner',
  templateUrl: './hot-deal-banner.component.html',
  styleUrls: ['./hot-deal-banner.component.css']
})
export class HotDealBannerComponent {
  @Input() countdown: DealCountdown = { days: '00', hours: '00', minutes: '00', seconds: '00' };
}
