#!/bin/bash
# セッション終了(Stop)時の自動コミット＋バックアップローテーション
# 1. 変更ファイルを .claude/backups/ にタイムスタンプ付きでコピー
# 2. 各系列で最新5件を残して古いバックアップを削除
# 3. git に全変更を自動コミット
DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$DIR" || exit 0
[ -d .git ] || exit 0
# 変更がなければ何もしない
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

TS=$(date +%Y-%m-%d_%H%M%S)
mkdir -p .claude/backups

backup() { # $1=対象ファイル $2=プレフィックス $3=拡張子
  if [ -f "$1" ] && [ -n "$(git status --porcelain -- "$1")" ]; then
    cp "$1" ".claude/backups/$2_${TS}.$3"
  fi
}
backup index.html index html
backup seed_data.js seed_data js
backup CLAUDE.md CLAUDE md

prune() { # 最新5件を残して削除（パターンは展開させる）
  ls -t $1 2>/dev/null | tail -n +6 | while read -r f; do rm -f "$f"; done
}
prune '.claude/backups/index_*.html'
prune '.claude/backups/seed_data_*.js'
prune '.claude/backups/CLAUDE_*.md'

git add -A >/dev/null 2>&1
if git commit -m "auto: セッション自動バックアップ ${TS}" >/dev/null 2>&1; then
  echo "{\"systemMessage\":\"自動バックアップ完了: コミット ${TS}\"}"
fi
exit 0
