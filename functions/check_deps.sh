#本函数用于检查依赖项的下载状态
check_deps() {
  pkg up
  for dep in ${DEPS}; do
    if command -v ${dep}; then
      echo -e "${GREEN}${dep}已经存在，无需安装${NC}"
    else
      echo -e "${YELLOW}未检测到${dep}，开始安装。。。"
      if [[ "${dep}" == "java" ]]; then
        pkg install openjdk-21 -y
      else
        pkg install ${dep} -y
      fi
    fi
  done
}