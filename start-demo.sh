#!/usr/bin/env bash
set -e

PROJECT_DIR=/mnt/c/Users/FANNNDI/Documents/service-hub
LOG=/tmp/cf.log

echo "=== ServisGadget Demo Starter ==="
echo ""

# Step 1: Ensure .env exists
echo "[1/6] Checking .env..."
cd "$PROJECT_DIR"
if [ ! -f .env ]; then
  echo "  Creating .env from secrets..."
  bash switch-env.sh local
  sed -i 's|@localhost:5432/|@postgres:5432/|' .env
  sed -i 's|REDIS_HOST=localhost|REDIS_HOST=redis|' .env
  echo "  .env created"
else
  echo "  .env exists"
fi

# Step 2: Start Docker containers
echo ""
echo "[2/6] Starting Docker containers..."
docker compose up -d
echo "  Waiting for backend..."
sleep 5
until curl -sf http://localhost:3000/v1/health > /dev/null 2>&1; do
  echo "  ..."
  sleep 3
done
echo "  Backend OK"

# Step 3: Kill any existing cloudflared
echo ""
echo "[3/6] Cleaning up old tunnels..."
tmux kill-session -t cloud 2>/dev/null || true
pkill -f cloudflared 2>/dev/null || true
echo "  Done"

# Step 4: Start Cloudflare tunnel
echo ""
echo "[4/6] Starting Cloudflare tunnel..."
tmux new-session -d -s cloud
sleep 2
tmux send-keys -t cloud "cd $PROJECT_DIR && cloudflared tunnel --url http://localhost:3000 2>&1 | tee $LOG" Enter
echo "  Waiting for tunnel URL..."

TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" 2>/dev/null | grep -v api.trycloudflare | head -1)
  if [ -n "$TUNNEL_URL" ]; then break; fi
  sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
  echo "  ERROR: Failed to get tunnel URL"
  echo "  Check: tmux attach -t cloud"
  exit 1
fi
echo "  Tunnel: $TUNNEL_URL"

# Step 5: Update tunel.txt
echo ""
echo "[5/6] Updating tunel.txt..."
echo "${TUNNEL_URL}/v1" > tunel.txt
cat tunel.txt
echo "  tunel.txt updated (not committed)"

# Step 6: Summary
echo ""
echo "========================================="
echo "  DEMO READY"
echo "========================================="
echo ""
echo "  Tunnel:  $TUNNEL_URL"
echo "  Backend: http://localhost:3000"
echo "  Health:  curl $TUNNEL_URL/v1/health"
echo "  Swagger: http://localhost:3000/docs"
echo ""
echo "  Login:"
echo "    Platform Admin: /admin  -> admin / admin"
echo "    Store Admin:    /store-login (create from platform admin)"
echo "    Customer:       /login (stealth booking)"
echo ""
echo "  Tunnel session: tmux attach -t cloud"
echo "  Stop: tmux kill-session -t cloud && docker compose down"
echo ""
