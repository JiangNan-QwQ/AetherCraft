import os
import dialog  #pip install pythondialog
import json
import time

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

def forge_install():
    pass #TODO

def install(core):
    sv=[]
    versions=[]
    number=0
    while True:
        server_name=input(f"{BLUE}请输入服务器名称{NC}(仅支持数字和字母)：")
        if server_name.isalnum():
            break
        print(f"{RED}无效输入！请输入字母或数字！{NC}")
        time.sleep(1)
    if core=='spigot':
        with os.popen(r"curl -fsSL 'https://hub.spigotmc.org/versions/' | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -Vr | uniq") as v:
            while True:
                version = v.readline()
                if not version:
                    break
                versions.append(version.strip())
    elif core=='paper':
        pass #TODO
    elif core=='fabric':
        with os.popen(r"curl -fsSL 'https://meta.fabricmc.net/v2/versions/game' | sort -Vr | uniq") as v:
            data=json.load(v)
            stable_versions=[item['version'] for item in data
                             if item.get('stable') is True]
            while True:
                version = stable_versions.readline()
                if not version:
                    break
                versions.append(version.strip())
    while number<len(versions):
        number+=1
        sv.append((str(number),versions[number-1]))
    sr,selection=i.menu(
    "选择版本",
    choices=sv
    )
    if sr==i.OK:
        last=sv[int(selection)-1][1]
        os.system(f"mkdir -p download/{core}-{last}-build && wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar####TODO -O download/spigot-{last}-build/BuildTools.jar && (cd download/spigot-{last}-build && java -jar BuildTools.jar --rev {last}) && mkdir -p mcserver/spigot-{last}-{server_name} && mv download/spigot-{last}-build/spigot-{last}.jar mcserver/spigot-{last}-{server_name}/server.jar && touch mcserver/spigot-{last}-{server_name}/eula.txt && rm -rfv download/spigot-{last}-build")####TODO
        with open (f"mcserver/spigot-{last}-{server_name}/eula.txt","w",encoding="utf-8") as file:
            file.write("eula=True")
    elif sr==i.CANDLE:
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
                 ('F','Fabric')
                 ("F","Forge(未完成)"),###TODO
                 ("B","返回")
                 ###TODO 其它核心
                 ]
        )
        if cr==i.OK:
            match selection:
                case "S":
                    install('spigot')
                case "P":
                    install('paper')
                case 'F':
                    install('fabric')
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