import os

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 加粗颜色
BOLD='\033[1m'
RED_BOLD='\033[1;31m'
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'

print(f"真的要***{RED_BOLD}卸载{NC}***管理系统吗？卸载后您的服务器数据将{RED_BOLD}永久丢失{NC}！！！\n[y/N]")
reply=input()
if reply in ["Y","y"]:
    print("确认卸载")
    os.chdir(os.path.expanduser('~'))
    os.system("rm -rfv xnlr && rm .xnlr")
elif reply in ["N","n",""]:
    print("取消卸载")
    print("退出程序")
else:
    print("无效选项！！！")