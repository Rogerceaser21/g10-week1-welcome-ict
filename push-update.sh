#!/bin/bash
# Publish the deck.
#
# THE FILE IN THIS FOLDER IS THE SOURCE OF TRUTH.
#
# By default this script publishes g10-week1-welcome-ict.html exactly as it
# stands here: it bumps DECK_VERSION, commits and pushes. It does not look in
# ~/Downloads at all.
#
# Only --from-downloads pulls a browser-exported copy in, and even then it
# REFUSES a copy that is not newer than the file in this folder. The old script
# copied the newest ~/Downloads/g10-week1-welcome-ict*.html over the repo file
# every single run, with no comparison of any kind, so a download from earlier
# in the day would silently publish over newer work. On 1 September 2026 that
# nearly destroyed a finished rebuild. It cannot happen now.
#
#   ./push-update.sh                            publish what is in this folder
#   ./push-update.sh -m "what changed"          ... with your own commit message
#   ./push-update.sh --from-downloads           pull the newest ~/Downloads export first
#   ./push-update.sh --from-downloads --force   ... even if it is older (asks you first)
#
set -euo pipefail
cd "$(dirname "$0")"

DECK=g10-week1-welcome-ict.html
FROM_DOWNLOADS=0
FORCE=0
MSG="deck update"

while [ $# -gt 0 ]; do
  case "$1" in
    --from-downloads|-d) FROM_DOWNLOADS=1 ;;
    --force) FORCE=1 ;;
    -m) shift; MSG="${1:-deck update}" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; echo "Try: $0 --help"; exit 2 ;;
  esac
  shift
done

[ -f "$DECK" ] || { echo "No $DECK in $(pwd). Nothing to publish."; exit 1; }

if [ "$FROM_DOWNLOADS" -eq 1 ]; then
  NEWEST=$(ls -t "$HOME"/Downloads/g10-week1-welcome-ict*.html 2>/dev/null | head -1 || true)
  if [ -z "$NEWEST" ]; then
    echo "--from-downloads was asked for, but there is no g10-week1-welcome-ict*.html in ~/Downloads."
    exit 1
  fi
  DL_TIME=$(stat -f %m "$NEWEST")
  REPO_TIME=$(stat -f %m "$DECK")
  echo "download : $NEWEST"
  echo "           $(date -r "$DL_TIME" '+%Y-%m-%d %H:%M:%S')"
  echo "repo file: $DECK"
  echo "           $(date -r "$REPO_TIME" '+%Y-%m-%d %H:%M:%S')"
  if cmp -s "$NEWEST" "$DECK"; then
    echo "They are byte for byte identical. Nothing to pull in; publishing the repo file."
  elif [ "$DL_TIME" -le "$REPO_TIME" ]; then
    echo
    echo "REFUSED: that download is not newer than the file in this folder."
    echo "Publishing it would throw away work. Re-export from the live deck, or,"
    echo "if you really mean to go back to that copy, run:"
    echo "    $0 --from-downloads --force"
    if [ "$FORCE" -eq 1 ]; then
      printf '\n--force was given. Overwrite the newer repo file with the older download? [y/N] '
      read -r ANSWER
      case "$ANSWER" in
        y|Y|yes|YES) cp "$NEWEST" "$DECK"; echo "Overwritten on your say-so." ;;
        *) echo "Left alone. Nothing published."; exit 1 ;;
      esac
    else
      exit 1
    fi
  else
    cp "$NEWEST" "$DECK"
    echo "Pulled the newer download in."
  fi
fi

# Bump DECK_VERSION so every browser purges its locally stored edits (the pushed
# file already carries them baked in; a stale restore could garble the new deck).
NEW_VERSION="v$(date +%Y%m%d-%H%M%S)"
sed -i '' "s/const DECK_VERSION = '[^']*'/const DECK_VERSION = '$NEW_VERSION'/" "$DECK"
grep -q "const DECK_VERSION = '$NEW_VERSION'" "$DECK" || { echo "DECK_VERSION bump failed. Nothing published."; exit 1; }
echo "DECK_VERSION is now $NEW_VERSION"

git add -A && git commit -m "$MSG ($NEW_VERSION)" && git push
echo "Pushed. Live in about 30 seconds at the same URL."
