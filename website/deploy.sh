#!/bin/bash
# Deploy razvi.dev website to Cloudflare Pages
# Usage: ./deploy.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="razvi"

echo "Deploying to Cloudflare Pages ($PROJECT_NAME)..."
wrangler pages deploy "$SCRIPT_DIR" --project-name="$PROJECT_NAME"
echo "Done! Site live at https://razvi.dev"
