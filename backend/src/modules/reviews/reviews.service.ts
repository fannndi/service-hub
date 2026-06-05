import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import {
  OrderNotFoundException,
  DuplicateReviewException,
} from '../../common/exceptions';
import { customAlphabet } from 'nanoid';

const nid = customAlphabet('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 6);

interface CreateReviewDto {
  rating: number;
  comment?: string;
}

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async createReview(orderId: string, userId: string, dto: CreateReviewDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId, status: 'completed' },
    });
    if (!order) throw new OrderNotFoundException();

    const existing = await this.prisma.review.findUnique({ where: { orderId } });
    if (existing) throw new DuplicateReviewException();

    const result = await this.prisma.$transaction(async (tx) => {
      const review = await tx.review.create({
        data: {
          orderId, userId, storeId: order.storeId,
          rating: dto.rating, comment: dto.comment,
        },
      });

      const agg = await tx.review.aggregate({
        where: { storeId: order.storeId },
        _avg: { rating: true },
        _count: { rating: true },
      });
      await tx.store.update({
        where: { id: order.storeId },
        data: { ratingAvg: agg._avg.rating ?? 0 },
      });

      const code = `RWD-${Date.now().toString(36).toUpperCase()}-${nid().slice(0, 4)}`;
      const coupon = await tx.coupon.create({
        data: {
          userId,
          reviewId: review.id,
          code,
          amount: 10000,
          expiredAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });

      return { review, coupon };
    });

    return result;
  }
}
