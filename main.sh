#!/usr/bin/env bash
#加载变量
source $HOME/xnlr/functions/variable.sh
#加载检查程序函数
source $HOME/xnlr/functions/check_deps.sh



#检查目录是否存在
for dir in ${DIRS}; do
  if [[ -d "$HOME/${dir}" ]]; then
    :
  else
    echo -e "${YELLOW}目录 ${dir} 不存在，创建。。。"
    mkdir -p "$HOME/${dir}"
  fi
done

#检查程序
check_deps

#选择面板
while true; do
  CHOICE=$(dialog -- clear --title "Aether_Craft" \
    -- "选择操作" \
    12 50 5 \
    1  "启动服务器" \
    2  "下载服务器" \
    3  "服务器管理" \
    4  "退出" \
    2>&1 >/dev/tty)

  case $CHOICE in
    1) start_server ;;
    2) install_server ;;
    3) control_server ;;
    4|"") echo "再见。。。"&&exit ;;
  esac
done