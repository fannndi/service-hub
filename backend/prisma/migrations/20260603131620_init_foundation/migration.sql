-- CreateEnum
CREATE TYPE "AccountStatus" AS ENUM ('active', 'suspended', 'deleted');

-- CreateEnum
CREATE TYPE "DeviceType" AS ENUM ('android', 'ios');

-- CreateEnum
CREATE TYPE "DeliveryMethod" AS ENUM ('walk_in', 'courier_pickup');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('waiting_device', 'device_received', 'diagnosing', 'waiting_approval', 'waiting_sparepart', 'repairing', 'quality_check', 'waiting_payment', 'completed', 'cancelled', 'disputed');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('unpaid', 'partially_paid', 'paid', 'refunded');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('transfer_bank', 'qris', 'cash', 'ewallet');

-- CreateEnum
CREATE TYPE "PaymentType" AS ENUM ('deposit', 'final_payment', 'refund');

-- CreateEnum
CREATE TYPE "PaymentRecordStatus" AS ENUM ('pending', 'confirmed', 'failed', 'refunded');

-- CreateEnum
CREATE TYPE "SparePartStatus" AS ENUM ('available', 'preorder', 'discontinued');

-- CreateEnum
CREATE TYPE "OrderItemStatus" AS ENUM ('pending', 'confirmed', 'replaced', 'cancelled');

-- CreateEnum
CREATE TYPE "ShipmentType" AS ENUM ('pickup', 'return', 'warranty_pickup');

-- CreateEnum
CREATE TYPE "ShipmentStatus" AS ENUM ('scheduled', 'picked_up', 'in_transit', 'delivered', 'failed');

-- CreateEnum
CREATE TYPE "DisputeType" AS ENUM ('warranty_claim', 'service_quality', 'wrong_diagnosis', 'other');

-- CreateEnum
CREATE TYPE "DisputeStatus" AS ENUM ('open', 'store_accepted', 'store_rejected', 'escalated', 'resolved', 'closed');

-- CreateEnum
CREATE TYPE "CreatedByType" AS ENUM ('customer', 'store_admin', 'system');

-- CreateEnum
CREATE TYPE "ApplicationStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "FeeBearerType" AS ENUM ('customer', 'store', 'platform');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "full_name" VARCHAR(150) NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "avatar_url" VARCHAR(255),
    "address" TEXT,
    "account_status" "AccountStatus" NOT NULL DEFAULT 'active',
    "is_first_login" BOOLEAN NOT NULL DEFAULT true,
    "is_credential_sent" BOOLEAN NOT NULL DEFAULT false,
    "credential_plain_enc" TEXT,
    "login_attempt_count" SMALLINT NOT NULL DEFAULT 0,
    "locked_until" TIMESTAMPTZ,
    "last_login_at" TIMESTAMPTZ,
    "password_changed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "store_admins" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "full_name" VARCHAR(150) NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_first_login" BOOLEAN NOT NULL DEFAULT false,
    "last_login_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "store_admins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stores" (
    "id" TEXT NOT NULL,
    "store_name" VARCHAR(150) NOT NULL,
    "address" TEXT NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "operational_hours" JSONB NOT NULL DEFAULT '{}',
    "config" JSONB NOT NULL DEFAULT '{}',
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "rating_avg" DECIMAL(3,2) NOT NULL DEFAULT 0,
    "total_completed" INTEGER NOT NULL DEFAULT 0,
    "penalty_points" INTEGER NOT NULL DEFAULT 0,
    "verified_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "stores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "store_applications" (
    "id" TEXT NOT NULL,
    "store_name" VARCHAR(150) NOT NULL,
    "applicant_name" VARCHAR(150) NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "address" TEXT NOT NULL,
    "business_license_url" VARCHAR(255),
    "id_card_url" VARCHAR(255) NOT NULL,
    "status" "ApplicationStatus" NOT NULL DEFAULT 'pending',
    "reviewed_by" TEXT,
    "review_note" TEXT,
    "applied_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_at" TIMESTAMPTZ,

    CONSTRAINT "store_applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "spareparts" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "brand" VARCHAR(80) NOT NULL,
    "device_model" VARCHAR(100) NOT NULL,
    "part_type" VARCHAR(60) NOT NULL,
    "part_name" VARCHAR(150) NOT NULL,
    "price" DECIMAL(12,2) NOT NULL,
    "qty" INTEGER NOT NULL DEFAULT 0,
    "qty_reserved" INTEGER NOT NULL DEFAULT 0,
    "status" "SparePartStatus" NOT NULL DEFAULT 'available',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "spareparts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_orders" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "order_number" VARCHAR(30) NOT NULL,
    "device_type" "DeviceType" NOT NULL,
    "brand" VARCHAR(80) NOT NULL,
    "device_model" VARCHAR(100) NOT NULL,
    "delivery_method" "DeliveryMethod" NOT NULL,
    "delivery_address" TEXT,
    "status" "OrderStatus" NOT NULL DEFAULT 'waiting_device',
    "payment_status" "PaymentStatus" NOT NULL DEFAULT 'unpaid',
    "total_estimasi" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "discount_amount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "final_price" DECIMAL(12,2),
    "service_fee" DECIMAL(12,2),
    "diagnosis_note" TEXT,
    "warranty_days" INTEGER,
    "warranty_expired_at" TIMESTAMPTZ,
    "sla_deadline" TIMESTAMPTZ,
    "sla_warned_at" TIMESTAMPTZ,
    "sla_breach_count" SMALLINT NOT NULL DEFAULT 0,
    "coupon_id" TEXT,
    "is_warranty_order" BOOLEAN NOT NULL DEFAULT false,
    "parent_order_id" TEXT,
    "completed_at" TIMESTAMPTZ,
    "cancelled_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "service_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "sparepart_id" TEXT,
    "service_type" VARCHAR(100) NOT NULL,
    "complaint" TEXT NOT NULL,
    "item_price" DECIMAL(12,2) NOT NULL,
    "final_item_price" DECIMAL(12,2),
    "status" "OrderItemStatus" NOT NULL DEFAULT 'pending',
    "technician_note" TEXT,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_tracking" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "status" "OrderStatus" NOT NULL,
    "note" TEXT,
    "created_by_type" "CreatedByType" NOT NULL,
    "created_by_id" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "service_tracking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "payment_method" "PaymentMethod" NOT NULL,
    "payment_type" "PaymentType" NOT NULL,
    "status" "PaymentRecordStatus" NOT NULL DEFAULT 'pending',
    "proof_url" VARCHAR(255),
    "confirmed_by" TEXT,
    "confirmed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shipments" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "shipment_type" "ShipmentType" NOT NULL,
    "courier_name" VARCHAR(80),
    "tracking_number" VARCHAR(100),
    "pickup_address" TEXT NOT NULL,
    "destination_address" TEXT NOT NULL,
    "status" "ShipmentStatus" NOT NULL DEFAULT 'scheduled',
    "scheduled_at" TIMESTAMPTZ,
    "delivered_at" TIMESTAMPTZ,
    "shipping_fee" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "fee_bearer" "FeeBearerType" NOT NULL DEFAULT 'customer',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shipments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reviews" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "rating" SMALLINT NOT NULL,
    "comment" TEXT,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coupons" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "review_id" TEXT NOT NULL,
    "code" VARCHAR(20) NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL DEFAULT 10000,
    "is_used" BOOLEAN NOT NULL DEFAULT false,
    "used_at" TIMESTAMPTZ,
    "used_on_order_id" TEXT,
    "expired_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "coupons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "disputes" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "dispute_type" "DisputeType" NOT NULL,
    "description" TEXT NOT NULL,
    "evidence_urls" JSONB NOT NULL DEFAULT '[]',
    "status" "DisputeStatus" NOT NULL DEFAULT 'open',
    "store_response" TEXT,
    "platform_decision" TEXT,
    "resolution" TEXT,
    "warranty_order_id" TEXT,
    "resolved_at" TIMESTAMPTZ,
    "sla_deadline" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "disputes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_sessions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token_hash" VARCHAR(64) NOT NULL,
    "device_info" JSONB,
    "ip_address" VARCHAR(45),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "last_active_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "failed_notifications" (
    "id" TEXT NOT NULL,
    "recipient_type" VARCHAR(20) NOT NULL,
    "recipient_id" TEXT NOT NULL,
    "channel" VARCHAR(20) NOT NULL DEFAULT 'whatsapp',
    "message_type" VARCHAR(50) NOT NULL,
    "payload" JSONB NOT NULL,
    "attempt_count" SMALLINT NOT NULL DEFAULT 0,
    "last_error" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "failed_notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_number_key" ON "users"("phone_number");

-- CreateIndex
CREATE UNIQUE INDEX "store_admins_store_id_phone_number_key" ON "store_admins"("store_id", "phone_number");

-- CreateIndex
CREATE INDEX "spareparts_store_id_idx" ON "spareparts"("store_id");

-- CreateIndex
CREATE INDEX "spareparts_brand_device_model_part_type_idx" ON "spareparts"("brand", "device_model", "part_type");

-- CreateIndex
CREATE UNIQUE INDEX "service_orders_order_number_key" ON "service_orders"("order_number");

-- CreateIndex
CREATE UNIQUE INDEX "service_orders_coupon_id_key" ON "service_orders"("coupon_id");

-- CreateIndex
CREATE INDEX "service_orders_user_id_idx" ON "service_orders"("user_id");

-- CreateIndex
CREATE INDEX "service_orders_store_id_idx" ON "service_orders"("store_id");

-- CreateIndex
CREATE INDEX "service_orders_status_idx" ON "service_orders"("status");

-- CreateIndex
CREATE UNIQUE INDEX "shipments_tracking_number_key" ON "shipments"("tracking_number");

-- CreateIndex
CREATE UNIQUE INDEX "reviews_order_id_key" ON "reviews"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "coupons_review_id_key" ON "coupons"("review_id");

-- CreateIndex
CREATE UNIQUE INDEX "coupons_code_key" ON "coupons"("code");

-- CreateIndex
CREATE UNIQUE INDEX "disputes_order_id_key" ON "disputes"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_sessions_token_hash_key" ON "user_sessions"("token_hash");

-- CreateIndex
CREATE INDEX "user_sessions_user_id_is_active_idx" ON "user_sessions"("user_id", "is_active");

-- AddForeignKey
ALTER TABLE "store_admins" ADD CONSTRAINT "store_admins_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "spareparts" ADD CONSTRAINT "spareparts_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_orders" ADD CONSTRAINT "service_orders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_orders" ADD CONSTRAINT "service_orders_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_orders" ADD CONSTRAINT "service_orders_coupon_id_fkey" FOREIGN KEY ("coupon_id") REFERENCES "coupons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "service_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_sparepart_id_fkey" FOREIGN KEY ("sparepart_id") REFERENCES "spareparts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_tracking" ADD CONSTRAINT "service_tracking_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "service_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "service_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shipments" ADD CONSTRAINT "shipments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "service_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "service_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_review_id_fkey" FOREIGN KEY ("review_id") REFERENCES "reviews"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disputes" ADD CONSTRAINT "disputes_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "service_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disputes" ADD CONSTRAINT "disputes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disputes" ADD CONSTRAINT "disputes_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_sessions" ADD CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
