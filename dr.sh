#!/bin/bash

# ~/md/から ~/md/daily_report/2025/04 に移動
cd ~/md/daily_report/2025/04 || { echo "ディレクトリが存在しません。終了します。"; exit 1; }

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
case "$answer" in
  [Yy] | [Yy][Ee][Ss] )
    # ユーザーからコミットメッセージを入力
    read -p "コミットメッセージを入力してください: " commit_message
    ;;
  * )
    echo "コミットはキャンセルされました。終了します。"
    exit 0
esac

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
