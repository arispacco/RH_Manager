#!/bin/bash
#
# build-apk.sh — Push changes to GitHub and trigger APK build in the cloud.
#
# Usage:
#   ./build-apk.sh                 → debug build
#   ./build-apk.sh release         → release build
#   ./build-apk.sh "fix scanner"   → debug build with custom commit message
#   ./build-apk.sh release "v2"    → release build with custom commit message
#

set -e

# ── Config ─────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$REPO_DIR/flutter_app"
BRANCH="$(git -C "$REPO_DIR" branch --show-current)"
REPO="freddychoudja/RH_Manager"

# ── Parse args ─────────────────────────────────────────────────
BUILD_MODE="debug"
COMMIT_MSG=""

for arg in "$@"; do
  if [ "$arg" = "release" ]; then
    BUILD_MODE="release"
  else
    COMMIT_MSG="$arg"
  fi
done

if [ -z "$COMMIT_MSG" ]; then
  COMMIT_MSG="build: update $(date +%Y-%m-%d_%H:%M)"
fi

# ── Colors ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 AttendanceOS APK Builder            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Analyze locally first ──────────────────────────────
echo -e "${YELLOW}[1/4]${NC} Analyzing code locally..."
cd "$FLUTTER_DIR"

if flutter analyze --no-fatal-infos 2>&1 | tail -1 | grep -q "No issues"; then
  echo -e "${GREEN}  ✓ No issues found${NC}"
else
  echo -e "${RED}  ✗ Analysis found issues. Fix them before building.${NC}"
  flutter analyze --no-fatal-infos
  exit 1
fi

# ── Step 2: Git add + commit + push ───────────────────────────
echo -e "${YELLOW}[2/4]${NC} Pushing to GitHub (branch: $BRANCH)..."
cd "$REPO_DIR"
git add -A
git diff --cached --quiet && echo -e "${GREEN}  ✓ No changes to commit${NC}" || {
  git commit -m "$COMMIT_MSG"
  echo -e "${GREEN}  ✓ Committed: $COMMIT_MSG${NC}"
}
git push origin "$BRANCH"
echo -e "${GREEN}  ✓ Pushed to origin/$BRANCH${NC}"

# ── Step 3: Trigger the workflow ──────────────────────────────
echo -e "${YELLOW}[3/4]${NC} Triggering GitHub Actions build ($BUILD_MODE)..."

if ! command -v gh &> /dev/null; then
  echo -e "${RED}  ✗ GitHub CLI (gh) not installed.${NC}"
  echo -e "  Install: ${BLUE}sudo apt install gh${NC}"
  echo -e "  Then:    ${BLUE}gh auth login${NC}"
  echo ""
  echo -e "  Alternatively, trigger manually at:"
  echo -e "  ${BLUE}https://github.com/$REPO/actions/workflows/build-apk.yml${NC}"
  exit 0
fi

gh workflow run build-apk.yml \
  --repo "$REPO" \
  --ref "$BRANCH" \
  --field build_mode="$BUILD_MODE"

echo -e "${GREEN}  ✓ Build triggered!${NC}"

# ── Step 4: Wait & download ──────────────────────────────────
echo -e "${YELLOW}[4/4]${NC} Waiting for build to complete..."
echo -e "  This takes ~5-8 minutes on GitHub servers."
echo ""

sleep 10  # Give GitHub time to register the run

# Get the latest run ID
RUN_ID=$(gh run list --repo "$REPO" --workflow build-apk.yml --limit 1 --json databaseId -q '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
  echo -e "${RED}  Could not find the run. Check manually:${NC}"
  echo -e "  ${BLUE}https://github.com/$REPO/actions${NC}"
  exit 1
fi

echo -e "  Run ID: $RUN_ID"
echo -e "  Live:   ${BLUE}https://github.com/$REPO/actions/runs/$RUN_ID${NC}"
echo ""

# Watch the run
gh run watch "$RUN_ID" --repo "$REPO" --exit-status && {
  echo ""
  echo -e "${GREEN}  ✓ Build successful!${NC}"
  echo -e "${YELLOW}  Downloading APK...${NC}"

  mkdir -p "$REPO_DIR/builds"
  gh run download "$RUN_ID" --repo "$REPO" --dir "$REPO_DIR/builds/"

  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✅ APK downloaded to builds/ folder    ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
  echo ""
  ls -lh "$REPO_DIR/builds/"*/*.apk 2>/dev/null
} || {
  echo -e "${RED}  ✗ Build failed. Check the logs:${NC}"
  echo -e "  ${BLUE}https://github.com/$REPO/actions/runs/$RUN_ID${NC}"
  exit 1
}
