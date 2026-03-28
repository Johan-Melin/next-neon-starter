#!/usr/bin/env bash
# bootstrap.sh — Create and link a Vercel project + Neon database for next-neon-starter
set -euo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[info]${NC}  $*"; }
success() { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC}  $*"; }
die()     { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ─── 1. Preflight ────────────────────────────────────────────────────────────
info "Checking Vercel CLI…"
command -v vercel >/dev/null 2>&1 || die "Vercel CLI not found. Install: npm i -g vercel"
vercel --version

info "Checking authentication…"
VERCEL_USER=$(vercel whoami 2>/dev/null) || die "Not logged in. Run: vercel login"
success "Logged in as: $VERCEL_USER"

# ─── 2. Project name ─────────────────────────────────────────────────────────
DEFAULT_PROJECT=$(basename "$(pwd)")
read -rp "$(echo -e "${CYAN}Project name${NC} [${DEFAULT_PROJECT}]: ")" PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_PROJECT}"

# ─── 3. Team / scope ─────────────────────────────────────────────────────────
info "Available teams:"
vercel teams ls 2>/dev/null || true
echo ""
read -rp "$(echo -e "${CYAN}Team scope${NC} (leave blank for personal account): ")" TEAM_SCOPE
SCOPE_FLAG=""
[ -n "$TEAM_SCOPE" ] && SCOPE_FLAG="--scope $TEAM_SCOPE"

# ─── 4. Link or create Vercel project ────────────────────────────────────────
if [ -f ".vercel/project.json" ]; then
  warn ".vercel/project.json already exists — using existing linkage."
  cat .vercel/project.json
else
  info "Linking project to Vercel…"
  # shellcheck disable=SC2086
  vercel link --yes $SCOPE_FLAG --project "$PROJECT_NAME" || {
    info "Project not found — creating it…"
    # shellcheck disable=SC2086
    vercel link --yes $SCOPE_FLAG --project "$PROJECT_NAME" --no-pull
  }
  success "Linked: $PROJECT_NAME"
fi

# ─── 5. Provision Neon via Vercel integration ─────────────────────────────────
info "Provisioning Neon Postgres via Vercel integration…"
echo ""
echo -e "${YELLOW}This will open an interactive prompt. Accept the terms and choose your plan.${NC}"
echo ""

if vercel integration add neon $SCOPE_FLAG 2>/dev/null; then
  success "Neon integration added."
else
  warn "Could not add Neon automatically (may already be installed, or requires Dashboard)."
  echo ""
  echo "  If not yet provisioned, add it manually:"
  echo "  → https://vercel.com/integrations/neon"
  echo ""
  read -rp "Press Enter once Neon is provisioned and DATABASE_URL is set in Vercel… "
fi

# ─── 6. Pull env vars (first pass — gets DATABASE_URL) ───────────────────────
info "Pulling environment variables…"
vercel env pull .env.local --yes
success "Wrote .env.local"

# ─── 7. Generate and store AUTH_SECRET ───────────────────────────────────────
if grep -qE '^AUTH_SECRET=.+' .env.local 2>/dev/null; then
  success "AUTH_SECRET already set — skipping."
else
  info "Generating AUTH_SECRET…"
  AUTH_SECRET_VAL="$(node -e "console.log(require('node:crypto').randomBytes(32).toString('base64url'))")"
  printf "%s" "$AUTH_SECRET_VAL" | vercel env add AUTH_SECRET development preview production
  unset AUTH_SECRET_VAL
  success "AUTH_SECRET stored in Vercel."

  info "Pulling env vars again to include AUTH_SECRET…"
  vercel env pull .env.local --yes
fi

# ─── 8. Verify required keys ──────────────────────────────────────────────────
info "Verifying required environment variables…"
TEMPLATE_FILE=""
for candidate in .env.example .env.sample .env.template; do
  [ -f "$candidate" ] && { TEMPLATE_FILE="$candidate"; break; }
done

if [ -z "$TEMPLATE_FILE" ]; then
  warn "No env template found (.env.example / .env.sample / .env.template) — skipping key check."
else
  MISSING=$(comm -23 \
    <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$TEMPLATE_FILE" | cut -d'=' -f1 | sort -u) \
    <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env.local      | cut -d'=' -f1 | sort -u))

  if [ -n "$MISSING" ]; then
    die "Missing required keys in .env.local:\n$MISSING\n\nAdd them in Vercel and re-run: vercel env pull .env.local --yes"
  fi
  success "All required env keys present."
fi

# ─── 9. Apply database schema ────────────────────────────────────────────────
if [ -f "db/schema.sql" ]; then
  info "Applying db/schema.sql to Neon…"

  # Extract DATABASE_URL from .env.local
  DB_URL=$(grep -E '^DATABASE_URL=' .env.local | cut -d'=' -f2- | tr -d '"'\''')

  if [ -z "$DB_URL" ]; then
    warn "DATABASE_URL not found in .env.local — skipping schema apply."
    warn "Run manually: psql \"\$DATABASE_URL\" -f db/schema.sql"
  elif command -v psql >/dev/null 2>&1; then
    psql "$DB_URL" -f db/schema.sql
    success "Schema applied."
  else
    warn "psql not found — skipping schema apply."
    warn "Run manually: psql \"\$DATABASE_URL\" -f db/schema.sql"
  fi
fi

# ─── 10. Summary ─────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} Bootstrap complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Linked project : ${CYAN}${PROJECT_NAME}${NC}"
echo -e "  Env file       : ${CYAN}.env.local${NC}"
echo -e "  Schema         : ${CYAN}db/schema.sql${NC}"
echo ""
echo -e "  Next step: ${YELLOW}npm run dev${NC}"
echo ""
