#!/bin/bash

# =============================================
# Environment Switcher for ServisGadget
# =============================================
# Usage:
#   ./switch-env.sh local      - Switch to local development
#   ./switch-env.sh production  - Switch to production
#   ./switch-env.sh status      - Show current environment
#
# Requirements:
#   - Folder secrets/ di root project
#   - secrets/.env.local dan secrets/.env.production harus ada

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
SECRETS_DIR="$SCRIPT_DIR/secrets"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_status() {
    if [ -f "$ENV_FILE" ]; then
        DB_URL=$(grep DATABASE_URL "$ENV_FILE" | cut -d'=' -f2-)
        if echo "$DB_URL" | grep -q "supabase.co"; then
            echo -e "${BLUE}Current Environment: PRODUCTION${NC}"
            echo -e "Database: Supabase"
        elif echo "$DB_URL" | grep -q "localhost\|postgres:"; then
            echo -e "${GREEN}Current Environment: LOCAL${NC}"
            echo -e "Database: Local PostgreSQL (Docker)"
        else
            echo -e "${YELLOW}Current Environment: UNKNOWN${NC}"
            echo -e "Database: $DB_URL"
        fi
    else
        echo -e "${YELLOW}No .env file found${NC}"
        echo -e "Run: ${GREEN}./switch-env.sh local${NC}"
    fi
}

switch_to_local() {
    echo -e "${GREEN}Switching to LOCAL environment...${NC}"
    
    if [ -f "$SECRETS_DIR/.env.local" ]; then
        cp "$SECRETS_DIR/.env.local" "$ENV_FILE"
        echo -e "${GREEN}✓ Switched to LOCAL environment${NC}"
        echo -e "  Database: PostgreSQL (Docker)"
        echo -e "  Redis: Redis (Docker)"
        echo -e "  API URL: http://localhost:3000"
        echo ""
        echo -e "Next steps:"
        echo -e "  ${BLUE}docker compose up -d --build${NC}"
        echo -e "  ${BLUE}docker compose exec backend npx prisma db push${NC}"
        echo -e "  ${BLUE}docker compose exec backend npx prisma db seed${NC}"
    else
        echo -e "${RED}✗ secrets/.env.local not found${NC}"
        echo -e "Make sure folder secrets/ exists in root project"
        echo -e "Folder ini di-share manual dari anggota tim lain"
        exit 1
    fi
}

switch_to_production() {
    echo -e "${BLUE}Switching to PRODUCTION environment...${NC}"
    
    if [ -f "$SECRETS_DIR/.env.production" ]; then
        cp "$SECRETS_DIR/.env.production" "$ENV_FILE"
        
        # Check if secrets are still placeholders
        if grep -q "\[GENERATE\|PLACEHOLDER" "$ENV_FILE"; then
            echo -e "${YELLOW}⚠ WARNING: secrets/.env.production contains placeholders!${NC}"
            echo -e "Edit secrets/.env.production and replace all [PLACEHOLDER] values"
            echo -e "Then run: ${BLUE}./switch-env.sh production${NC}"
        fi
        
        echo -e "${BLUE}✓ Switched to PRODUCTION environment${NC}"
        echo -e "  Database: PostgreSQL (VPS)"
        echo -e "  API URL: https://[your-domain]"
        echo ""
        echo -e "Next steps:"
        echo -e "  ${BLUE}docker compose up -d --build${NC}"
        echo -e "  ${BLUE}docker compose exec backend npx prisma db push${NC}"
        echo -e "  ${BLUE}docker compose exec backend npx prisma db seed${NC}"
    else
        echo -e "${RED}✗ secrets/.env.production not found${NC}"
        echo -e "Make sure folder secrets/ exists in root project"
        echo -e "Folder ini di-share manual dari anggota tim lain"
        exit 1
    fi
}

# Main
case "${1:-status}" in
    local|dev)
        switch_to_local
        ;;
    production|prod)
        switch_to_production
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {local|production|status}"
        echo ""
        echo "  local      - Switch to local development (Docker)"
        echo "  production - Switch to production (VPS)"
        echo "  status     - Show current environment"
        exit 1
        ;;
esac
