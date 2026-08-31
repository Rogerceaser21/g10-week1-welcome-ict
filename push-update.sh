#!/bin/bash
# After editing the live deck (E to edit, then Cmd+S downloads a copy), run this to publish it.
# It takes the newest downloaded copy from ~/Downloads, replaces the deck, commits, pushes.
set -e
cd "$(dirname "$0")"
NEWEST=$(ls -t ~/Downloads/g10-week1-welcome-ict*.html 2>/dev/null | head -1)
if [ -z "$NEWEST" ]; then echo "No downloaded deck copy found in ~/Downloads."; exit 1; fi
cp "$NEWEST" g10-week1-welcome-ict.html
# Bump DECK_VERSION so every browser purges its locally stored edits (the pushed
# file already carries them baked in; a stale restore could garble the new deck).
sed -i '' "s/const DECK_VERSION = '[^']*'/const DECK_VERSION = 'v$(date +%Y%m%d-%H%M%S)'/" g10-week1-welcome-ict.html
git add -A && git commit -m "inline edits" && git push
echo "Pushed. Live in about 30 seconds at the same URL."
