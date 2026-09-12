export interface Review {
  id: number;
  reviewCode: string;
  productId: number;
  productName: string;
  customerId: number;
  customerName: string;
  customerEmail: string;
  rating: number;
  reviewTitle: string;
  reviewMessage: string;
  reviewStatus: string;
  reviewDate: string;
  replyMessage: string;
  createdAt: string;
  updatedAt: string;
}
