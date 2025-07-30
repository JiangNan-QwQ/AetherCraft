import dialog####pip install pythondialog
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

x=dialog.Dialog(dialog="dialog")

def menu():
    while True:
        re,selection=x.menu(
            "AetherCraft",
            choices=[
                ("I","下载服务器"),
                ("S","启动服务器"),
                ("C","管理服务器"),
                ("B","备份/恢复服务器"),
                ("U","卸载整个管理系统"),
                ("E","退出管理系统")
                      ]
                                 )
        if re==x.OK:
            match selection:
                case "I":
                    os.system("python functions/install.py")
                case "S":
                    os.system("python functions/start.py")
                case "C":
                    os.system("python functions/config.py")
                case "B":
                    os.system("python functions/backup.py")
                case "U":
                    os.system("python functions/uninstall.py")
                    print(f"{BLUE}再见，期待与您的再次相遇。\nBy：江南_XnLr{NC}")
                    break
                case "E":
                    #print("保存日志文件。。。。")  ###TODO
                    print(f"{BLUE}再见{NC}")
                    break
                case _:
                    print(f"{RED}无效选项{NC}")
        elif re==x.CANCEL:
            print(f"{RED}无效选项{NC}")
        else:
            print(f"{RED}无效选项{NC}")

menu()