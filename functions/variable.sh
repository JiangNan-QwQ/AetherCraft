#本文件用于存储脚本所需常量与变量
#####################################
############常量######################

#定义常量：脚本运行需要的目录#用于main.sh
DIRS=["xnlr/download","xnlr/logs","xnlr/mcservers"]
#定义常量：颜色字体#用于所有
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NC="\033[0m"
#定义常量：需要的程序#用于check_deps.sh
DEPS=["java","dialog","jq","wget"]