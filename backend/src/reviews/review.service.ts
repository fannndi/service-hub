import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReviewService {
  constructor(private prisma: PrismaService) {}

  async createReview(orderId: string, userId: string, rating: number, comment?: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.serviceOrder.findUnique({ where: { id: orderId } });
      if (!order) throw new NotFoundException('Order tidak ditemukan');
      if (order.status !== 'completed') throw new ConflictException('Order belum selesai');

      const existing = await tx.review.findUnique({ where: { orderId } });
      if (existing) throw new ConflictException({ code: 'DUPLICATE_REVIEW', message: 'Review sudah ada' });

      // Create review
      const review = await tx.review.create({
        data: { orderId, userId, storeId: order.storeId, rating, comment },
      });

      // Bug B8 fix: Update store ratingAvg
      const agg = await tx.review.aggregate({ _avg: { rating: true }, _count: { id: true }, where: { storeId: order.storeId } });
      await tx.store.update({
        where: { id: order.storeId },
        data: { ratingAvg: agg._avg.rating ?? rating, reviewCount: agg._count.id },
      });

      // Bug B9 fix: Create reward coupon in same transaction
      const coupon = await tx.coupon.create({
        data: {
          code: `RVW-${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
          amount: 50000,
          type: 'fixed',
          expiredAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          userId,
          storeId: order.storeId,
          reviewId: review.id,
        },
      });

      return { review, coupon };
    });
  }

  // Bug B6 fix: Ownership check
  async validateCoupon(code: string, userId: string) {
    const coupon = await this.prisma.coupon.findUnique({ where: { code } });
    if (!coupon) throw new NotFoundException('Kupon tidak ditemukan');
    if (coupon.userId !== userId) throw new ConflictException({ code: 'COUPON_NOT_OWNED', message: 'Kupon ini bukan milikmu.' });
    if (coupon.isUsed) throw new ConflictException({ code: 'COUPON_USED', message: 'Kupon sudah dipakai.' });
    if (coupon.expiredAt < new Date()) throw new ConflictException({ code: 'COUPON_EXPIRED', message: 'Kupon kadaluarsa.' });
    return coupon;
  }
}
