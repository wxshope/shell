#!/usr/bin/env bash
#!/usr/bin/env bash
export RUST_BACKTRACE=full
export RUST_LOG=info
ip=$(hostname -I | awk '{print $1}'|awk -F. '{print "worker--" $3"--"$4}')
url="aleo1.damominer.hk:9090"
Address="aleoxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
path="/root/dev/snarkos"
pid=$(ps -ef | grep ${Address} | grep -v grep | awk '{print $2}')
if [ x"$pid" = "x" ]; then
  echo -e  "${datetime}  DamoMiner START  successfully!"
  nohup ${path}/damominer --address ${Address} --proxy ${url} --worker ${ip} &
else
  echo  -e "${datetime}  DamoMiner RUNNING  successfully!"
fi
wait
