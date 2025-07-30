import os
import dialog
#颜色
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

i=dialog.Dialog(dialog="dialog")

def core_menu():
    while True:
        cr,selection=i.menu(
        "选择核心",
        choices=[("S","Spigot"),
                 ("P","Paper"),
                 ("F","Forge(未完成)"),###TODO
                 ###TODO 其它核心
                 ]
        )
        if cr==i.OK:
            
def menu():
    while True:
        re,selection=i.menu(
        "下载服务器",
        choices=[("C","选择一个服务器核心"),
                 ("B","返回")
                 ]
        )
        if re==i.OK:
            match selection:
                case "C":
                    core_menu()
                case "B":
                    break
                case _:
                    print(f"{RED}无效选项！{NC}")
        elif re==i.CANDLE:
            break
        else:
            print(f"{RED_BOLD}无效选项！{NC}")
menu()