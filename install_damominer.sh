#!/usr/bin/env bash

export FILEPATH="/root/dev/snarkos"
export CONF="/etc/supervisor/conf.d/"
echo "判断是否安装锄头"

function version() {
    if [ ! -d ${FILEPATH} ]; then
      mkdir -pv ${FILEPATH}
    fi
  VERSION=$(curl -k -sL https://proxy.jeongen.com/https://api.github.com/repos/damomine/aleominer/releases | jq -r ".[0].tag_name")
  echo "VERSION=${VERSION}"
  SHELL_VERSION=$(cat ${FILEPATH}/version.txt)
}

function Install() {
  sudo apt install mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl supervisor clang build-essential hwloc libhwloc-dev wget -y && sudo apt upgrade -y
  if [ -f ${FILEPATH}/damominer ]; then
    echo "已经安装过锄头"
  else
    version
    if [ ! -d ${FILEPATH} ]; then
      mkdir -pv ${FILEPATH}
    fi
    echo "没有安装锄头,开始下载安装"

    if [ ! -f ${FILEPATH}/damominer_${VERSION}.tar ]; then
      wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://proxy.jeongen.com/https://github.com/damomine/aleominer/releases/download/$VERSION/damominer_linux_$VERSION.tar
      tar -xvf damominer_linux_${VERSION}.tar
      chmod a+x ${FILEPATH}/damominer
      rm damominer_linux_${VERSION}.tar
      rm README.md
      rm md5res
      rm run_gpu.sh
    fi

    if [ ! -f ${FILEPATH}/run-damominer.sh ]; then
      wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://proxy.jeongen.com/https://github.com/wxshope/shell/raw/master/run-damominer.sh
      chmod +x run-damominer.sh
    fi

    if [ ! -f ${CONF}/damominer.conf ]; then
      wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://proxy.jeongen.com/https://github.com/wxshope/shell/raw/master/damominer.conf
      mv damominer.conf ${CONF}
    fi

    chmod a+x ${FILEPATH}/damominer

    read -p "请输入您的钱包地址 > " wallet
    sleep 4

    sed -i "s/aleoxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/$wallet/g" ${FILEPATH}/run-damominer.sh
  fi
}

function UPdata() {
  version
  if [ ! -d ${FILEPATH} ]; then
      mkdir -pv ${FILEPATH}
  fi
  SHELL_NEW_VERSION=$(echo ${VERSION} | awk -Fv '{print $2}')
  if [[ ${SHELL_NEW_VERSION} != ${SHELL_VERSION} ]]; then
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://proxy.jeongen.com/https://github.com/damomine/aleominer/releases/download/$VERSION/damominer_linux_$VERSION.tar
    tar -xvf damominer_linux_${VERSION}.tar
    chmod a+x ${FILEPATH}/damominer
    supervisorctl restart damominer
    rm damominer_linux_${VERSION}.tar
    rm README.md
    rm md5res
    rm run_gpu.sh
    echo ${SHELL_NEW_VERSION} > ${FILEPATH}/version.txt
  else
    echo -e "${INFO} 当前已是最新版本[ ${SHELL_NEW_VERSION} ]!"
  fi

}

if [ X$1 = "Xinstall" ]; then
  echo "開始部署 damominer 程序"
  Install
  systemctl restart supervisor
  echo -e "部署完成"
  exit 0
elif [ X$1 = "Xupdate" ]; then
  echo "開始更新 damominer 程序"
  UPdata
  echo -e "完成更新"
  exit 0
else
  echo "操作指令不正確  推出"
  echo "輸入正確的指令   update OR install"
  exit 0
fi
