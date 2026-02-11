#本函数用于下载服务器

#下载服务器菜单
install_server() {
  while true; do
    CHOICE=(dialog --clear --title "Aether_Craft" \
    --menu "选择服务器核心" \
    12 50 5 \
    1  "Fabric" \
    2  "Spigot" \
    3  "Vanilla" \
    4  "Bedrock" \
    5  "取消安装" \
    2>&1 >/dev/tty)

    case $CHOISE in
      1) install_fabric ;;
      2) install_spigot ;;
      3) install_vanilla ;;
      4) install_bedrock ;;
      5|"") break ;;
    esac
  done
}
#Java版服务器下载函数
download_java_server() {
  case $1 in
    "fabric") download_fabric $2;;
  esac
}
###################################################
###################################################
######################Fabric#######################
#下载Fabric
install_fabric() {
  while true; do
    CHOICE=(dialog --clear --title "Aether_Craft" \
    --menu "下载正式版/快照版" \
    12 50 5 \
    1  "正式版" \
    2  "快照版" \
    3  "取消" \
    2>&1 >/dev/tty)
    case $CHOICE in
      1) download_java_server "fabric" "true" ;;
      2) download_java_server "fabric" "snapshot" ;;
      3|"") break ;;
    esac
  done
}
#下载核心
download_fabric() {
  case $1 in
  "true")
    ;;
  esac
}