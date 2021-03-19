#!/bin/bash
echo "推送笔记到git"
time=$(date "+%Y-%m-%d %H:%M:%S")
git add .

read -t 30 -p "输入提交注释:" msg
if [! "$msg"] ; then
  echo "[commit message]  默认提交,提交人$(whoami),提交时间 ${time}"
  git commit -m "默认提交,提交人:$(whoami),提交时间 ${time}"
else
  echo "[commit message] $msg, 提交人: $(whoami), 提交时间: ${time}"
  git commit -m "$msg, 提交人: $(whoami), 提交时间: ${time}"
fi

git push origin master

echo "auto push file to github."
