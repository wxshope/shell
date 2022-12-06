#!/usr/bin/env bash
export RUST_BACKTRACE=full
export RUST_LOG=info
ip=$(hostname -I | awk '{print $1}')
url="aleo1.damominer.hk:9090"
Address="aleo1ysrrdxz0pr2674vw9z0fvk6v8hc95kkwj23fffun522e2zl5mqqsj7duv6"
path="/root/dev/snarkos"
pid=$(ps -ef | grep ${Address} | grep -v grep  | awk '{print $2}')
if [ x"$pid" = "x" ] ;then
  nohup  ${path}/damominer --address ${Address} --proxy ${url} --worker ${ip}  &
else
  echo "${datetime}  lotus RUNNING  successfully!"
fi
wait