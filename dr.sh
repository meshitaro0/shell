#!/bin/bash

# 前稼働日を計算する関数
get_previous_working_day() {
  local days_off=$1 # コマンドライン引数で渡された休暇日数
  local target_date=$(date +%Y%m%d) # 実行日
  local weekday=$(date -d "$target_date" +%u) # 曜日番号 (1:月曜日, ..., 7:日曜日)

  # 月曜日の場合は金曜日まで遡る
  if [ "$weekday" -eq 1 ]; then
    target_date=$(date -d "$target_date -3 day" +%Y%m%d) # 月曜→金曜
  else
    # 他の日の場合は前日に遡る
    target_date=$(date -d "$target_date -1 day" +%Y%m%d)
  fi

  # 休暇日数分をさらに遡る (平日のみ)
  while [ "$days_off" -gt 0 ]; do
    target_date=$(date -d "$target_date -1 day" +%Y%m%d)
    weekday=$(date -d "$target_date" +%u)
    # 月曜～金曜のみカウント
    if [ "$weekday" -ge 1 ] && [ "$weekday" -le 5 ]; then
      days_off=$((days_off - 1))
    fi
  done

  echo "$target_date"
}

# コマンドライン引数から休暇日数を取得（デフォルトは0）
days_off=${1:-0}

# 前稼働日の計算
previous_working_day=$(get_previous_working_day "$days_off")
year=$(echo "$previous_working_day" | cut -c1-4)
month=$(echo "$previous_working_day" | cut -c5-6)
day=$(echo "$previous_working_day" | cut -c7-8)
previous_working_day_formatted="${year:2}${month}${day}" # 例: 250411形式

# 次の火曜日を計算
get_next_tuesday() {
  today=$(date +%Y%m%d) # 実行日
  weekday=$(date +%u)   # 曜日番号 (1:月曜日, ..., 7:日曜日)

  # 火曜日は曜日番号2。実行日が火曜日の場合は当日を返す
  if [ "$weekday" -eq 2 ]; then
    echo "$today"
    return
  fi

  # 次の火曜日までの日数を計算
  days_until_tuesday=$(( (9 - weekday) % 7 ))
  next_tuesday=$(date -d "+${days_until_tuesday} days" +%Y%m%d)
  echo "$next_tuesday"
}

next_tuesday=$(get_next_tuesday)
next_year=$(echo "$next_tuesday" | cut -c1-4)
next_month=$(echo "$next_tuesday" | cut -c5-6)
next_day=$(echo "$next_tuesday" | cut -c7-8)
formatted_next_tuesday="${next_year:2}${next_month}${next_day}"

# 動的ディレクトリとファイル名の設定
dest_dir="D:/012345/mtg/$formatted_next_tuesday"
dest_file="$dest_dir/$previous_working_day_formatted.pdf"

# ~/md/から ~/md/daily_report/2025/04 に移動
cd ~/md/daily_report/2025/04 || { echo "ディレクトリが存在しません。終了します。"; exit 1; }

# daily_report.pdfを複製
mkdir -p "$dest_dir" || { echo "ディレクトリの作成に失敗しました。終了します。"; exit 1; }
cp daily_report.pdf "$dest_file" || { echo "ファイルの複製に失敗しました。終了します。"; exit 1; }
echo "daily_report.pdfを$dest_fileに複製しました。"

# gitリポジトリの確認
if [ ! -d .git ]; then
  echo "このディレクトリはGitリポジトリではありません。終了します。"
  exit 1
fi

# 全ての変更をステージング
git add .

# ステージングされた内容を表示
echo "以下のファイルがステージングされています:"
git status --short

# ユーザーにcommitしてよいかを確認
read -p "この内容をコミットしてもよろしいですか？(y/n): " answer
if [[ "$answer" != "y" && "$answer" != "yes" ]]; then
  echo "コミットはキャンセルされました。終了します。"
  exit 0
fi

# ユーザーからコミットメッセージを入力
read -p "コミットメッセージを入力してください: " commit_message

# コミットを実行
git commit -m "$commit_message"
echo "コミットが完了しました。"

# masterブランチに移動
git checkout master || { echo "masterブランチへの切り替えに失敗しました。終了します。"; exit 1; }

# devブランチをmasterにマージ
git merge dev || { echo "マージに失敗しました。終了します。"; exit 1; }
echo "マージが成功しました。"

# devブランチに戻る
git checkout dev || { echo "devブランチへの切り替えに失敗しました。終了します。"; exit 1; }
echo "devブランチに戻りました。"
