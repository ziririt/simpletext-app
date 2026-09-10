#!/bin/bash
cd "$HOME/development/simpletext_app" || exit 1
export PATH="$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
bash tool/verify.sh 2>&1 | tail -25
echo "=== COMMIT ==="
git add -A
git commit -F _m.txt 2>&1 | tail -5
git push origin main 2>&1 | sed -e 's#https://[^ ]*@#https://***@#g' | tail -5
rm -f _m.txt _c.sh
echo "=== DONE ==="
