-- Add CHECK constraints for data integrity
-- BR-06: Matching engine requires non-negative stock

ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_nonneg CHECK (qty >= 0);
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_reserved_nonneg CHECK (qty_reserved >= 0);
ALTER TABLE reviews ADD CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5);
