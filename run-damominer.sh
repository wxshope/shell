#!/usr/bin/env bash
#!/usr/bin/env bash
export RUST_BACKTRACE=full
export RUST_LOG=info
ip=$(hostname -I | awk '{print $1}')
url="aleo1.damominer.hk:9090"
Address="aleoxxxxxxxxx"
path="/root/dev/snarkos"
pid=$(ps -ef | grep ${Address} | grep -v grep | awk '{print $2}')
if [ x"$pid" = "x" ]; then
  echo -e  "${datetime}  DamoMiner START  successfully!"
  nohup ${path}/damominer --address ${Address} --proxy ${url} --worker ${ip} &
else
  echo  -e "${datetime}  DamoMiner RUNNING  successfully!"
fi
wait
