#!/bin/bash

# =============================================
# Environment Switcher for ServisGadget
# =============================================
# Usage:
#   ./switch-env.sh local     - Switch to local development
#   ./switch-env.sh production - Switch to production
#   ./switch-env.sh status     - Show current environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
    fi
}

switch_to_local() {
    echo -e "${GREEN}Switching to LOCAL environment...${NC}"
    
    if [ -f "$SCRIPT_DIR/.env.local" ]; then
        cp "$SCRIPT_DIR/.env.local" "$ENV_FILE"
        echo -e "${GREEN}✓ Switched to LOCAL environment${NC}"
        echo -e "  Database: PostgreSQL (Docker)"
        echo -e "  Redis: Redis (Docker)"
        echo -e "  API URL: http://localhost:3000"
        echo ""
        echo -e "Run: ${BLUE}docker compose up -d${NC} to start services"
    else
        echo -e "${YELLOW}✗ .env.local not found${NC}"
        exit 1
    fi
}

switch_to_production() {
    echo -e "${BLUE}Switching to PRODUCTION environment...${NC}"
    
    if [ -f "$SCRIPT_DIR/.env.production" ]; then
        cp "$SCRIPT_DIR/.env.production" "$ENV_FILE"
        echo -e "${BLUE}✓ Switched to PRODUCTION environment${NC}"
        echo -e "  Database: Supabase PostgreSQL"
        echo -e "  API URL: https://api.servisgadget.com"
        echo ""
        echo -e "${YELLOW}⚠ Make sure to update JWT secrets before deploying!${NC}"
    else
        echo -e "${YELLOW}✗ .env.production not found${NC}"
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
        echo "  production - Switch to production (Supabase)"
        echo "  status     - Show current environment"
        exit 1
        ;;
esac
