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

def spigot_install():
    sv=[]
    spigot_versions=[]
    number=0
    server_name=input(f"{BLUE}请输入服务器名称{NC}(仅支持数字和字母)：")
    ####TODO 检测服务器名称
    with os.popen(r"curl -fsSL 'https://hub.spigotmc.org/versions/' | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -Vr | uniq | head -n 10") as v:
        while True:
            version=v.readline()
            if not version:
                break
            spigot_versions.append(version.strip())
    while number<len(spigot_versions):
        number+=1
        sv.append((str(number),spigot_versions[number-1]))
    sr,selection=i.menu(
    "选择版本---Spigot",
    choices=sv
    )
    if sr==i.OK:
        last=sv[int(selection)-1][1]
        os.system(f"mkdir -p download/spigot-{last}-build && wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar -O download/spigot-{last}-build/BuildTools.jar && (cd download/spigot-{last}-build && java -jar BuildTools.jar --rev {last}) && mkdir -p mcserver/spigot-{last}-{server_name} && mv download/spigot-{last}-build/spigot-{last}.jar mcserver/spigot-{last}-{server_name}/server.jar && rm -rfv download/spigot-{last}-build")
    elif cr==i.CANDLE:
        pass
    else:
        print(f"{RED_BOLD}无效选项！{NC}")
def core_menu():
    while True:
        cr,selection=i.menu(
        "选择核心",
        choices=[
                 ("S","Spigot"),
                 ("P","Paper"),
                 ("F","Forge(未完成)"),###TODO
                 ("B","返回")
                 ###TODO 其它核心
                 ]
        )
        if cr==i.OK:
            match selection:
                case "S":
                    spigot_install()
                case "P":
                    paper_install()
                case "F":
                    forge_install()
                case "B":
                    break
                case _:
                    print(f"{RED}无效选项！{NC}")
        elif cr==i.CANDLE:
            break
        else:
            print(f"{RED_BOLD}无效选项！{NC}")
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