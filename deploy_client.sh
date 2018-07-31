#!/bin/bash
#title: deploy_client.sh
#author: wangxiyang
#date: 2018-07-02
#desc: auto deloy hadoop client
username=$USER
deploy_type=$TYPE
internal="internal.tar.gz"
external="external.tar.gz"
http_url="http://192.168.1.2:8088/download"

# 异常处理
function trap_exit() {
  trap "exit_procprocess $@" 0
}
trap_exit

function exit_procprocess() {
  local ret=$?
  kill -9 `pstree $$ -p | awk -F "[()]" '{for(i=1;i<=NF;i++)if($i~/[0-9]+/)print $i}' | grep -v $$` 2>/dev/null
  [[ -f $ERROR_INFO ]] && ret=1
  cat $ERROR_INFO 2>/dev/null
  exit $ret
}

function abnormal_exit() {
    echo "[FATAL]  $@"
    exit 1
}

function init_env() {
    egrep "^$username" /etc/password >& /dev/null
    if [[ $? -ne 0 ]]; then
      useradd $username
    fi

    mkdir -p /export/servers/hadoop
    cd /export/servers/hadoop

    if [[ $deploy_type == China ]]; then
      wget $http_url/$internal >& /dev/null
      [[ $? -ne 0 ]] && abnormal_exit "Wget packages was failed, please reexecute script."
      tar zxf $internal >& /dev/null
      cat internal-hosts.txt >> /etc/hosts
      /bin/rm -rf $internal
    elif [[ $deploy_type == America ]]; then
      wget $http_url/$external >& /dev/null
      [[ $? -ne 0 ]] && abnormal_exit "Wget packages was failed, please reexecute script."
      tar zxf $external >& /dev/null
      cat external-hosts.txt >> /etc/hosts
      /bin/rm -rf $external
    else
      abnormal_exit "Please choose the right type."
    fi

    return 0
}

function configure_env() {
  cp /home/$username/.bashrc /home/$username/.bashrc.bak
  sed -i '$a\export JAVA_HOME=/export/servers/hadoop/jdk1.8.0_71' /home/$username/.bashrc
  sed -i '$a\export JAVA_BIN=$JAVA_HOME/bin' /home/$username/.bashrc
  sed -i '$a\export CLASSPATH=$JAVA_HOME/lib' /home/$username/.bashrc
  sed -i '$a\export PATH=$PATH:$JAVA_HOME/bin' /home/$username/.bashrc
  sed -i '$a\export HADOOP_HOME=/export/servers/hadoop/hadoop-2.7.2' /home/$username/.bashrc
  sed -i '$a\export HADOOP_PID_DIR=$HADOOP_HOME/hadoop_pid_dir' /home/$username/.bashrc
  sed -i '$a\export HADOOP_MAPRED_HOME=$HADOOP_HOME' /home/$username/.bashrc
  sed -i '$a\export HADOOP_COMMON_HOME=$HADOOP_HOME' /home/$username/.bashrc
  sed -i '$a\export HADOOP_HDFS_HOME=$HADOOP_HOME' /home/$username/.bashrc
  sed -i '$a\export YARN_HOME=$HADOOP_HOME' /home/$username/.bashrc
  sed -i '$a\export HADOOP_YARN_HOME=$HADOOP_HOME' /home/$username/.bashrc
  sed -i '$a\export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' /home/$username/.bashrc
  sed -i '$a\export HDFS_CONF_DIR=$HADOOP_HOME/etc/hadoop' /home/$username/.bashrc
  sed -i '$a\export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop' /home/$username/.bashrc
  sed -i '$a\export JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native' /home/$username/.bashrc
  sed -i '$a\export HIVE_HOME=/export/servers/hadoop/hive-2.0.1' /home/$username/.bashrc
  sed -i '$a\export SPARK_HOME=/export/servers/hadoop/spark-2.1.1' /home/$username/.bashrc
  sed -i '$a\export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin:.' /home/$username/.bashrc
  source /home/$username/.bashrc
  return 0
}

if [[ `whoami` == "root" ]]; then
  init_env
  [[ $? -eq 0 ]] && echo "Init env successed."
  configure_env
  [[ $? -eq 0 ]] && echo "The Hadoop client has been installed."
else
  abnormal_exit "当前用户不具有root权限，请联系管理员。"
fi
