#!/usr/bin/env bash

export FILEPATH="/root/dev/snarkos"
export CONF="/etc/supervisor/conf.d/"
export INFO="[${Green}Info${Font}]"
export PROXY="https://ghproxy.com"
function repair_openssl() {
  OPENSSL_VERSION=$(openssl version)

  # shellcheck disable=SC2076
  if [[ $OPENSSL_VERSION =~ "1.1.1" ]]; then
    echo -e "${INFO} OpenSSL 版本正常!"
  else
    echo -e "${INFO} 开始安装 OpenSSL 1.1.1..."
    # 从 Impish builds 下载 openssl 二进制包

    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate http://security.ubuntu.com/ubuntu/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2.16_amd64.deb      -O openssl_1.1.1f-1ubuntu2.16_amd64.deb ||
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://mirrors.ustc.edu.cn/ubuntu/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2.16_amd64.deb     -O openssl_1.1.1f-1ubuntu2.16_amd64.deb
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb   -O libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb ||
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://mirrors.ustc.edu.cn/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb  -O libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb    -O libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb ||
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate https://mirrors.ustc.edu.cn/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb   -O libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb

    # 安装下载的二进制包
    dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
    dpkg -i libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb
    dpkg -i openssl_1.1.1f-1ubuntu2.16_amd64.deb

    # 清理下载的文件
    rm openssl_1.1.1f-1ubuntu2.16_amd64.deb
    rm libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb
    rm libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb

    echo -e "${INFO} 安装 OpenSSL 1.1.1 成功!"
  fi
}

function version() {
  if [ ! -d ${FILEPATH} ]; then
    mkdir -pv ${FILEPATH}
  fi
  VERSION=$(curl -k -sL {PROXY}/https://api.github.com/repos/damomine/aleominer/releases | jq -r ".[0].tag_name")
  echo "VERSION=${VERSION}"
  SHELL_VERSION=$(cat ${FILEPATH}/version.txt)
}

function Install() {
  sudo apt install  jq pkg-config curl supervisor wget -y 
  if [ -f ${FILEPATH}/damominer ]; then
    echo "已经安装过锄头"
  else
    version
    echo "没有安装锄头,开始下载安装"
    if [ ! -d ${FILEPATH} ]; then
      mkdir -pv ${FILEPATH}
    fi
    cd ${FILEPATH}
    repair_openssl
    if [ ! -f ${FILEPATH}/damominer_${VERSION}.tar ]; then
      wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate {PROXY}/https://github.com/damomine/aleominer/releases/download/$VERSION/damominer_linux_$VERSION.tar
      tar -xvf damominer_linux_${VERSION}.tar
      chmod a+x ${FILEPATH}/damominer
      rm damominer_linux_${VERSION}.tar
      rm README.md
      rm md5res
      rm run_gpu.sh
      SHELL_NEW_VERSION=$(echo ${VERSION} | awk -Fv '{print $2}')
      echo ${SHELL_NEW_VERSION} >${FILEPATH}/version.txt
    fi

    if [ ! -f ${FILEPATH}/run-damominer.sh ]; then
      wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate {PROXY}/https://github.com/wxshope/shell/raw/master/run-damominer.sh
      chmod +x run-damominer.sh
    fi

    if [ ! -f ${CONF}/damominer.conf ]; then
      wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate {PROXY}/https://github.com/wxshope/shell/raw/master/damominer.conf
      mv damominer.conf ${CONF}
    fi

    chmod a+x ${FILEPATH}/damominer

    read -p "请输入您的钱包地址 > " wallet
    sleep 1

    sed -i "s/aleoxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/$wallet/g" ${FILEPATH}/run-damominer.sh
    sleep 1 
    read -rp "(默认: asiahk.damominer.hk:9090):" URL
    sed -i "s/aleo1.damominer.hk:9090/$URL/g" ${FILEPATH}/run-damominer.sh
  fi
}

function UPdata() {
  version
  if [ ! -d ${FILEPATH} ]; then
    mkdir -pv ${FILEPATH}
  fi
  cd ${FILEPATH}
  repair_openssl
  SHELL_NEW_VERSION=$(echo ${VERSION} | awk -Fv '{print $2}')
  if [[ ${SHELL_NEW_VERSION} != ${SHELL_VERSION} ]]; then
    wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate ${PROXY}/https://github.com/damomine/aleominer/releases/download/$VERSION/damominer_linux_$VERSION.tar
    tar -xvf damominer_linux_${VERSION}.tar
    chmod a+x ${FILEPATH}/damominer
    supervisorctl restart damominer
    rm damominer_linux_${VERSION}.tar
    rm README.md
    rm md5res
    rm run_gpu.sh
    echo ${SHELL_NEW_VERSION} >${FILEPATH}/version.txt
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
