import { Controller, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { CreateReviewDto } from './dto/review.dto';

@ApiTags('Reviews')
@Controller('reviews')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post(':orderId')
  async createReview(
    @GetUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviewsService.createReview(orderId, user.id, dto);
  }
}
