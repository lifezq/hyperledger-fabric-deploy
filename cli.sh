#!/bin/bash
#
# Distributed fabric deployment command line tools
#
# @Author Ryan
# @Link   github.com/lifezq
# @Datetime 2019-09-04
#

export PATH=${PWD}/bin:${PWD}/docker:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

function printHelp() {
  echo "Usage: "
  echo "  cli.sh [options] <fabric>    <init|install|uninstall>         \"Operate fabric, including init/install/uninstall\""
  echo "  cli.sh [options] <kafka>     <up|down>             <id|all>    \"Operate kafka, including up/down\""
  echo "  cli.sh [options] <orderer>   <up|down>             <id|all>    \"Operate orderer, including up/down\""
  echo "  cli.sh [options] <node>      <up|down|reload>             <orgid>     \"Operate node, including up/down/reload\""
  echo "  cli.sh [options] <channel>   <create|join|anchor|list|getinfo|fetch>  [peer] [org]    \"Operate channel, including create/join/anchor/list/getinfo/fetch\""
  echo "  cli.sh [options] <chaincode> <install|instantiate|invoke|query|upgrade|list>  [peer] [org]   \"Operate chaincode, including install/instantiate/invoke/query/upgrade/list\""
  echo "  cli.sh [options] <host>      <add|del|ls>          [host:ip]   \"Operate cli host map, including add/del/ls\""
  echo "Options:"
  echo "    -b <endorser> - specify an endorsement strategy (defaults to \"OR (Org{1,2,3}MSP)\")"
  echo "    -c <channel name> - channel name to use (defaults to \"test\")"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -s <dbtype> - the database backend to use: goleveldb or couchdb (default) "
  echo "    -l <language> - the chaincode language: golang (default) or node"
  echo "    -m <chaincode name> - the chaincode name: testcc (default)"
  echo "    -r <chaincode version> - the chaincode version: 1.0 (default)"
  echo "    -p <chaincode path> - the chaincode path: github.com/chaincode/chaincode_example02/go/ (default)"
  echo "    -g <chaincode init args> - the chaincode init args: {\"Args\":[\"init\",\"a\",\"100\",\"b\",\"200\"]} (default)"
  echo "    -o <consensus-type> - the consensus-type of the ordering service: solo (default), kafka, or etcdraft"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo "    -u <user@hostname> which host to deploy on"
  echo "    -a - launch certificate authorities (no certificate authorities are launched by default)"
  echo "    -v - verbose mode"
  echo "  cli.sh -h (print this message)"
  echo

  exit 0
}

which docker >&/dev/null
res=$?
dockerd=`ps -ef | grep dockerd | grep -v grep`
if [ "$res" -ne 0 -o "$dockerd" == "" ]; then
  tar -zxvf docker-18.09.5.tgz
  dockerd &
  sleep 3
fi

APP_NAME=`pwd | awk -F "/" '{print $NF}'`
DOCKER_TARNAME="docker-18.09.5.tgz"
# another container before giving up
CLI_TIMEOUT=2
# default for delay between commands
CLI_DELAY=1
# system channel name defaults to "test-sys-channel"
SYS_CHANNEL="test-sys-channel"
# channel name defaults to "test"
CHANNEL_NAME="test"
#
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
# org3 docker compose file
COMPOSE_FILE_ORG3=docker-compose-org3.yaml
# kafka and zookeeper compose file
COMPOSE_FILE_KAFKA=docker-compose-kafka.yaml
# two additional etcd/raft orderers
COMPOSE_FILE_RAFT2=docker-compose-etcdraft2.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=docker-compose-ca.yaml
# use golang as the default language for chaincode
LANGUAGE=golang
# default chain name set
CHAIN_NAME="testcc"
# default chain version set
CHAIN_VERSION=1.0
# default chain path set
CHAIN_PATH="github.com/chaincode/chaincode_example02/go/"
# default chain args set
CHAIN_ARGS='{"Args":["init","a","100","b","200"]}'
# default image tag
IMAGETAG="latest"
IMAGE_TAG_KAFKA="latest"
#
USER_HOSTNAME=""
# default consensus type
CONSENSUS_TYPE="kafka"
# default if couchdb
IF_COUCHDB="couchdb"
# default ORGCODE
ORGCODE="1"
# default endorser
ENDORSER='OR("Org1MSP.peer","Org2MSP.peer","Org3MSP.peer")'
# default CORE_PEER_TLS_ENABLED
CORE_PEER_TLS_ENABLED=true

source .env
source generate.lock
shiftcc=0
while getopts "h?b:c:t:d:s:l:m:r:p:g:i:u:o:av" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  b)
    ENDORSER=$OPTARG
    let  shiftcc+=2
    ;;
  c)
    CHANNEL_NAME=$OPTARG
    let  shiftcc+=2
    ;;
  t)
    CLI_TIMEOUT=$OPTARG
    let  shiftcc+=2
    ;;
  d)
    CLI_DELAY=$OPTARG
    let  shiftcc+=2
    ;;
  s)
    IF_COUCHDB=$OPTARG
    let  shiftcc+=2
    ;;
  l)
    LANGUAGE=$OPTARG
    let  shiftcc+=2
    ;;
  m)
    CHAIN_NAME=$OPTARG
    let  shiftcc+=2
    ;;
  r)
    CHAIN_VERSION=$OPTARG
    let  shiftcc+=2
    ;;
  p)
    CHAIN_PATH=$OPTARG
    let  shiftcc+=2
    ;;
  g)
    CHAIN_ARGS=$OPTARG
    let  shiftcc+=2
    ;;
  i)
    IMAGETAG=$(go env GOARCH)"-"$OPTARG
    let  shiftcc+=2
    ;;
  u)
    USER_HOSTNAME=$OPTARG
    let  shiftcc+=2
    ;;
  o)
    CONSENSUS_TYPE=$OPTARG
    let  shiftcc+=2
    ;;
  a)
    CERTIFICATE_AUTHORITIES=true
    let  shiftcc+=1
    ;;
  v)
    VERBOSE=true
    let  shiftcc+=1
    ;;
  esac
done

shift $shiftcc

function askProceedUninstall() {
    echo "This action will remove all the fabric system"
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y)
    echo "proceeding ..."
    ;;
  n | N)
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceedUninstall
    ;;
  esac
}

function fabric(){

  typeset -l DO

  DO=$1

  case "$DO" in
  init)
    read -p "input 3 numbers are respectively the quantity of kafka,orderer and node eg(3 3 3): " init_numbers
		typeset -l is_ca
		read -p "input is use ca issue node certificate: false (default) : " is_ca
		if [ $is_ca"x" == "truex" ];then
			read -p "input ca server address (host:port) : " ca_server
			read -p "input ca server account (user:pass) : " ca_account
			./generate-config.sh -a $ca_server -u $ca_account $init_numbers
		else
			./generate-config.sh $init_numbers
		fi
    ;;
  install)
    read -p "input install kafka host ip address eg(ip1 ip2): " kafka_ip
		read -p "input install orderer host ip address eg(ip1 ip2): " orderer_ip
		read -p "input install node host ip address eg(ip1 ip2): " node_ip
    source ".env"
		COMPOSE_FILE_KAFKA=docker-compose-kafka.yaml
		COMPOSE_FILE_ORDERER=docker-compose-orderer.yaml
		kid=1
		for ip in $kafka_ip;
		do
			sed -i "/      - \"zookeeper$kid.${DOMAIN_NAME}/d" $COMPOSE_FILE_KAFKA
			sed -i "/      - \"kafka$kid.${DOMAIN_NAME}/d" $COMPOSE_FILE_KAFKA
			sed -i "/      - \"kafka$kid.${DOMAIN_NAME}/d" $COMPOSE_FILE_ORDERER
			sed -i "39a\      - \"zookeeper$kid.${DOMAIN_NAME}:$ip\"" $COMPOSE_FILE_KAFKA
			echo "      - \"zookeeper$kid.${DOMAIN_NAME}:$ip\"">>$COMPOSE_FILE_KAFKA
			echo "      - \"kafka$kid.${DOMAIN_NAME}:$ip\"">>$COMPOSE_FILE_KAFKA
			echo "      - \"kafka$kid.${DOMAIN_NAME}:$ip\"">>$COMPOSE_FILE_ORDERER
			set -x
			./cli.sh host add zookeeper$kid.${DOMAIN_NAME}:$ip false >&/dev/null
			./cli.sh host add kafka$kid.${DOMAIN_NAME}:$ip false >&/dev/null
			set +x
			let kid+=1
		done

		kid=1
		for ip in $orderer_ip;
		do
			sed -i "/      - \"orderer$kid.${DOMAIN_NAME}/d" $COMPOSE_FILE_ORDERER
			echo "      - \"orderer$kid.${DOMAIN_NAME}:$ip\"">>$COMPOSE_FILE_ORDERER
			set -x
			./cli.sh host add orderer$kid.${DOMAIN_NAME}:$ip false >&/dev/null
			set +x
			let kid+=1
		done

		kid=1
		for ip in $node_ip;
		do
			for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    		do
				set -x
    		./cli.sh host add peer$i.org$kid.${DOMAIN_NAME}:$ip false >&/dev/null
				set +x
    		done
			let kid+=1
		done

		kid=1
		for ip in $kafka_ip;
		do
			./cli.sh -u root@$ip kafka up $kid
			let kid+=1
		done

		kid=1
		for ip in $orderer_ip;
		do
			./cli.sh -u root@$ip orderer up $kid
			let kid+=1
		done

		kid=1
		for ip in $node_ip;
		do
			./cli.sh -u root@$ip node up $kid
			let kid+=1
		done

		echo "kafka_ip=\"$kafka_ip\"">.fabric_install.lock
		echo "orderer_ip=\"$orderer_ip\"">>.fabric_install.lock
		echo "node_ip=\"$node_ip\"">>.fabric_install.lock

		echo "Wait 18 seconds for kafka cluster up..."
		sleep 18

    echo "Next will install the test chaincode"
  	read -p "Continue? [Y/n] " ans
  	case "$ans" in
  	y | Y | "")
  	  echo "proceeding ..."
  	  ;;
  	n | N)
  	  echo "exiting..."
  	  exit 1
  	  ;;
  	*)
  	  echo "invalid response"
  	  exit 1
  	  ;;
  	esac

    channel_name="test"
		./cli.sh -c $channel_name channel create
		res=$?
		if [ $res -ne 0 ];then
			exit 1
		fi

		kid=1
		for ip in $node_ip;
		do
			for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    		do
    		    ./cli.sh -c $channel_name channel join $i $kid >log.txt
				res=$?
				if [ $res -eq 0 ];then
					cat log.txt
				fi
    		done

			./cli.sh -c $channel_name channel anchor 0 $kid
			let kid+=1
		done

		chaincode_name="testcc"
    chaincode_version="1.0"
    chaincode_language="golang"
    chaincode_path="github.com/chaincode/chaincode_example02/go/"
    chaincode_args='{"Args":["init","a","100","b","200"]}'
    chaincode_endorser='OR("Org1MSP.peer","Org2MSP.peer","Org3MSP.peer")'
    
		kid=1
		for ip in $node_ip;
		do
			for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    		do
    		    ./cli.sh -c "$channel_name" -b "$chaincode_endorser" -l "$chaincode_language" -m "$chaincode_name" -r "$chaincode_version" -p "$chaincode_path" -g "$chaincode_args" chaincode install $i $kid>log.txt
				res=$?
				if [ $res -eq 0 ];then
					cat log.txt
				fi
			done

			let kid+=1
		done

		./cli.sh -c "$channel_name" -b "$chaincode_endorser" -l "$chaincode_language" -m "$chaincode_name" -r "$chaincode_version" -p "$chaincode_path" -g "$chaincode_args" chaincode instantiate 0 1
    ./cli.sh -c "$channel_name" -b "$chaincode_endorser" -l "$chaincode_language" -m "$chaincode_name" -r "$chaincode_version" -p "$chaincode_path" -g '{"Args":["query","a"]}' chaincode query 0 1
    ./cli.sh -c "$channel_name" -b "$chaincode_endorser" -l "$chaincode_language" -m "$chaincode_name" -r "$chaincode_version" -p "$chaincode_path" -g '{"Args":["invoke","a","b","10"]}' chaincode invoke 0 1
    ./cli.sh -c "$channel_name" -b "$chaincode_endorser" -l "$chaincode_language" -m "$chaincode_name" -r "$chaincode_version" -p "$chaincode_path" -g '{"Args":["query","a"]}' chaincode query 0 1
    res=$?
    if [ $res -eq 0 ];then
      echo "Fabric installation completed!"
      exit 0
    else
      echo "There were some errors during the installation, and unfortunately the installation was failed!"
      exit 1
    fi
    ;;
  uninstall)
    askProceedUninstall
    if [ ! -f .fabric_install.lock ];then
      exit 0
    fi
    source .fabric_install.lock
		res=$?
		if [ $res -ne 0 ];then
			echo "cannot uninstall, need to remove manually"
			exit 1
		fi
		kid=1
		for ip in $kafka_ip;
		do
			./cli.sh -u root@$ip kafka down $kid
			let kid+=1
		done

		kid=1
		for ip in $orderer_ip;
		do
			./cli.sh -u root@$ip orderer down $kid
			let kid+=1
		done

		kid=1
		for ip in $node_ip;
		do
			./cli.sh -u root@$ip node down $kid
			let kid+=1
		done
    echo "Fabric has been removed from the system!"
    ;;
  uninstallall)
    askProceedUninstall
    source .fabric_install.lock
		res=$?
		if [ $res -ne 0 ];then
			echo "cannot uninstall, need to remove manually"
			exit 1
		fi
		kid=1
		for ip in $kafka_ip;
		do
			./cli.sh -u root@$ip kafka down $kid
      ssh root@$ip "export PATH=~/$APP_NAME/docker:\$PATH;docker ps -a|awk '{print \$1}'|xargs docker stop;docker ps -a|awk '{print \$1}'|xargs docker rm -f;docker volume ls|awk '{print \$2}'|xargs docker volume rm -f"
			let kid+=1
		done

		kid=1
		for ip in $orderer_ip;
		do
			./cli.sh -u root@$ip orderer down $kid
      ssh root@$ip "export PATH=~/$APP_NAME/docker:\$PATH;docker ps -a|awk '{print \$1}'|xargs docker stop;docker ps -a|awk '{print \$1}'|xargs docker rm -f;docker volume ls|awk '{print \$2}'|xargs docker volume rm -f"
			let kid+=1
		done

		kid=1
		for ip in $node_ip;
		do
			./cli.sh -u root@$ip node down $kid
      ssh root@$ip "export PATH=~/$APP_NAME/docker:\$PATH;docker ps -a|awk '{print \$1}'|xargs docker stop;docker ps -a|awk '{print \$1}'|xargs docker rm -f;docker volume ls|awk '{print \$2}'|xargs docker volume rm -f"
			let kid+=1
		done

    for ip in $kafka_ip;
		do
      ssh root@$ip "ps -ef | grep dockerd|grep -v grep|awk '{print \$2}'>.dpid;cat .dpid|xargs kill -9>&/dev/null;rm -rf .dpid ~/$APP_NAME"
		done

		for ip in $orderer_ip;
		do
			ssh root@$ip "ps -ef | grep dockerd|grep -v grep|awk '{print \$2}'>.dpid;cat .dpid|xargs kill -9>&/dev/null;rm -rf .dpid ~/$APP_NAME"
		done

		for ip in $node_ip;
		do
			ssh root@$ip "ps -ef | grep dockerd|grep -v grep|awk '{print \$2}'>.dpid;cat .dpid|xargs kill -9>&/dev/null;rm -rf .dpid ~/$APP_NAME"
		done
    echo "Fabric has been removed from the system!"
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

function kafka(){
  
  typeset -l DO
  typeset -l KAFKA_ID

  DO=$1
  KAFKA_ID=$2
  KAFKA_PORT=8061
  KAFKA_DOCKER_FILE="./docker-compose-kafka.yaml"

  if [ "x"$KAFKA_ID == "x" ];then
        echo "kafka id should not be empty"
        exit 1
  fi

  if [ ! -z $USER_HOSTNAME ];then
      ipx=(${USER_HOSTNAME/@/ })
      ipex=`ifconfig | grep ${ipx[1]}`
      if [ -z "$ipex" ];then
          ssh-copy-id $USER_HOSTNAME >&/dev/null
          if [ "$DO" == "up" ];then
              ssh $USER_HOSTNAME "mkdir -p ~/$APP_NAME"
              SSDOCKER=`ssh $USER_HOSTNAME "ls ~/$APP_NAME|grep $DOCKER_TARNAME"`
              if [ -z "$SSDOCKER" ];then
                  scp $DOCKER_TARNAME $USER_HOSTNAME:~/$APP_NAME/
              fi
              if [ "$OFFLINE_DEPLOY" == "true" ];then
                  SSDOCKER=`ssh $USER_HOSTNAME "docker images | grep kafka"`
                  SFILE=("data/fabric-kafka-$IMAGE_TAG_KAFKA.tar" "data/fabric-zookeeper-$IMAGE_TAG_KAFKA.tar")
                  for SF in $SFILE;
                  do
                    if [ -f "$SF" ];then
                        scp $SF $USER_HOSTNAME:~/$APP_NAME/data/
                        ssh $USER_HOSTNAME "docker load -i ~/$APP_NAME/data/$SF"
                    else
                        echo "$SF not found"
                        exit 1
                    fi
                  done
              fi
              scp $KAFKA_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/
              scp ".env" $USER_HOSTNAME:~/$APP_NAME/
              scp "generate.lock" $USER_HOSTNAME:~/$APP_NAME/
              scp "cli.sh" $USER_HOSTNAME:~/$APP_NAME/
          fi
          ssh $USER_HOSTNAME "cd $APP_NAME;chmod +x cli.sh;./cli.sh kafka $DO $KAFKA_ID"
          exit 0
      fi
  fi

  case "$DO" in
  up)
    if [ $KAFKA_ID == "all" ];then
        echo "Id should be an integer when up"
        exit 1
    fi

    if [ $KAFKA_ID -le 0 -o $KAFKA_ID -gt $KAFKA_NUMBER ];then
          echo "Invalid id, or it must less than "$KAFKA_NUMBER
          exit 1
    fi

    for((i=2;i<=$KAFKA_ID;i++));
    do
      let KAFKA_PORT+=1
    done

    ZOO_SERVERS=""
    KAFKA_ZOOKEEPER_CONNECT=""
    for((i=1;i<=$KAFKA_NUMBER;i++));
    do
        ZOO_SERVERS+="server.$i=zookeeper$i.${DOMAIN_NAME}:2888:3888 "
        KAFKA_ZOOKEEPER_CONNECT+="zookeeper$i.${DOMAIN_NAME}:2181,"
    done

    sed -i "s/ZOO_MY_ID=[0-9]\{1,10\}/ZOO_MY_ID=$KAFKA_ID/g" $KAFKA_DOCKER_FILE
    sed -i "s/KAFKA_BROKER_ID=[0-9]\{1,10\}/KAFKA_BROKER_ID=$KAFKA_ID/g" $KAFKA_DOCKER_FILE
    sed -i "s/ kafka[0-9]\{1,10\}/ kafka$KAFKA_ID/g" $KAFKA_DOCKER_FILE
    sed -i "s/chaincode\/kafka[0-9]\{1,10\}/chaincode\/kafka$KAFKA_ID/g" $KAFKA_DOCKER_FILE
    # sed -i "s/- 8[0-9]\{1,10\}:[0-9]\{1,10\}/- $KAFKA_PORT:$KAFKA_PORT/g" $KAFKA_DOCKER_FILE
    sed -i "s/\/\/kafka[0-9]\{1,10\}.${DOMAIN_NAME}/\/\/kafka$KAFKA_ID.${DOMAIN_NAME}/g" $KAFKA_DOCKER_FILE
    # sed -i "s/OUTSIDE:\/\/:[0-9]\{1,10\}/OUTSIDE:\/\/:$KAFKA_PORT/g" $KAFKA_DOCKER_FILE
    sed -i "s/ zookeeper[0-9]\{1,10\}/ zookeeper$KAFKA_ID/g" $KAFKA_DOCKER_FILE
    sed -i "s/chaincode\/zookeeper[0-9]\{1,10\}/chaincode\/zookeeper$KAFKA_ID/g" $KAFKA_DOCKER_FILE
    sed -i "s/ZOO_SERVERS=.*/ZOO_SERVERS=$ZOO_SERVERS/g" $KAFKA_DOCKER_FILE
    sed -i "s/KAFKA_ZOOKEEPER_CONNECT=.*/KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT%,}/g" $KAFKA_DOCKER_FILE

    echo "Up.......kafka "$KAFKA_ID
    docker-compose -f $KAFKA_DOCKER_FILE up -d
    ;;
  down)
    echo "Down.......kafka "$KAFKA_ID
    docker-compose -f $KAFKA_DOCKER_FILE down --volumes
    if [ $KAFKA_ID == "all" ];then
        DEX=`docker ps -a|grep fabric-kafka|awk '{print $1}'`
        if [ "${DEX}x" != "x" ];then
            docker ps -a|grep "fabric-kafka"|awk '{print $1}'|xargs docker stop
            docker ps -a|grep "fabric-kafka"|awk '{print $1}'|xargs docker rm -f
            docker volume ls|grep kafka|awk '{print $2}'|xargs docker volume rm -f
        fi

        DEX=`docker ps -a|grep fabric-zookeeper|awk '{print $1}'`
        if [ "${DEX}x" != "x" ];then
            docker ps -a|grep "fabric-zookeeper"|awk '{print $1}'|xargs docker stop
            docker ps -a|grep "fabric-zookeeper"|awk '{print $1}'|xargs docker rm -f
            docker volume ls|grep zookeeper|awk '{print $2}'|xargs docker volume rm -f
        fi
        rm -rf ./chaincode/kafka ./chaincode/zookeeper
        exit 0
    fi
    
    DEX=`docker ps -a|grep kafka$KAFKA_ID|awk '{print $1}'`
    if [ "${DEX}x" != "x" ];then
        docker ps -a|grep "kafka"$KAFKA_ID|awk '{print $1}'|xargs docker stop
        docker ps -a|grep "kafka"$KAFKA_ID|awk '{print $1}'|xargs docker rm -f
        docker volume ls|grep kafka$KAFKA_ID|awk '{print $2}'|xargs docker volume rm -f
    fi

    DEX=`docker ps -a|grep zookeeper$KAFKA_ID|awk '{print $1}'`
    if [ "${DEX}x" != "x" ];then
        docker ps -a|grep "zookeeper"$KAFKA_ID|awk '{print $1}'|xargs docker stop
        docker ps -a|grep "zookeeper"$KAFKA_ID|awk '{print $1}'|xargs docker rm -f
        docker volume ls|grep zookeeper$KAFKA_ID|awk '{print $2}'|xargs docker volume rm -f
    fi
    rm -rf ./chaincode/kafka/kafka$KAFKA_ID ./chaincode/zookeeper/zookeeper$KAFKA_ID
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

function orderer(){
  
  typeset -l DO
  typeset -l ORDERER_ID

  DO=$1
  ORDERER_ID=$2
  ORDERER_PORT=8001
  ORDERER_BASE_DOCKER_FILE="./base/docker-compose-orderer.yaml"
  ORDERER_DOCKER_FILE="./docker-compose-orderer.yaml"

  if [ "x"$ORDERER_ID == "x" ];then
        echo "orderer id should not be empty"
        exit 1
  fi

  if [ ! -z $USER_HOSTNAME ];then
      ipx=(${USER_HOSTNAME/@/ })
      ipex=`ifconfig | grep ${ipx[1]}`
      if [ -z "$ipex" ];then
          ssh-copy-id $USER_HOSTNAME >&/dev/null
          if [ "$DO" == "up" ];then
              ssh $USER_HOSTNAME "mkdir -p ~/$APP_NAME/base && mkdir -p ~/$APP_NAME/channel-artifacts &&  mkdir -p ~/$APP_NAME/crypto-config/ordererOrganizations/${DOMAIN_NAME}/orderers"
              SSDOCKER=`ssh $USER_HOSTNAME "ls ~/$APP_NAME|grep $DOCKER_TARNAME"`
              if [ -z "$SSDOCKER" ];then
                  scp $DOCKER_TARNAME $USER_HOSTNAME:~/$APP_NAME/
              fi
              if [ "$OFFLINE_DEPLOY" == "true" ];then
                  SSDOCKER=`ssh $USER_HOSTNAME "docker images | grep kafka"`
                  SFILE=("data/fabric-orderer-$IMAGETAG.tar")
                  for SF in $SFILE;
                  do
                    if [ -f "$SF" ];then
                        scp $SF $USER_HOSTNAME:~/$APP_NAME/data/
                        ssh $USER_HOSTNAME "docker load -i ~/$APP_NAME/data/$SF"
                    else
                        echo "$SF not found"
                        exit 1
                    fi
                  done
              fi
              scp -r "./base/orderer-base.yaml" $USER_HOSTNAME:~/$APP_NAME/base/
              scp -r $ORDERER_BASE_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/base/
              scp -r $ORDERER_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/
              scp -r channel-artifacts/genesis.block $USER_HOSTNAME:~/$APP_NAME/channel-artifacts/
              scp -r crypto-config/ordererOrganizations/${DOMAIN_NAME}/orderers/orderer$ORDERER_ID.${DOMAIN_NAME} $USER_HOSTNAME:~/$APP_NAME/crypto-config/ordererOrganizations/${DOMAIN_NAME}/orderers/
              scp ".env" $USER_HOSTNAME:~/$APP_NAME/
              scp "generate.lock" $USER_HOSTNAME:~/$APP_NAME/
              scp "cli.sh" $USER_HOSTNAME:~/$APP_NAME/
          fi
          ssh $USER_HOSTNAME "cd $APP_NAME;chmod +x cli.sh;./cli.sh orderer $DO $ORDERER_ID"
          exit 0
      fi
  fi

  if [ $ORDERER_ID != "all" ];then

        if [ $ORDERER_ID -le 0 -o $ORDERER_ID -gt $ORDERER_NUMBER ];then
            echo "Invalid id, or it must less than "$ORDERER_NUMBER
            exit 1
        fi

        for((i=2;i<=$ORDERER_ID;i++));
        do
          let ORDERER_PORT+=1
        done

        KAFKA_PORT=8061
        for((i=1;i<=$KAFKA_NUMBER;i++));
        do
            ORDERER_KAFKA_BROKERS+="kafka$i.${DOMAIN_NAME}:$KAFKA_PORT,"
            let KAFKA_PORT+=1
        done

        sed -i "s/orderer[0-9]\{1,10\}/orderer$ORDERER_ID/g" $ORDERER_BASE_DOCKER_FILE
        # sed -i "s/- [0-9]\{1,10\}:7050/- $ORDERER_PORT:7050/g" $ORDERER_BASE_DOCKER_FILE
        # sed -i "s/ORDERER_KAFKA_BROKERS=.*/ORDERER_KAFKA_BROKERS=[${ORDERER_KAFKA_BROKERS%,}]/g" "./base/orderer-base.yaml"
        sed -i "s/ orderer[0-9]\{1,10\}/ orderer$ORDERER_ID/g" $ORDERER_DOCKER_FILE
  fi

  case "$DO" in
  up)
    if [ $ORDERER_ID == "all" ];then
        echo "Id should be an integer when up"
        exit 1
    fi
    echo "Up.......orderer "$ORDERER_ID
    IMAGE_TAG=$IMAGETAG docker-compose -f $ORDERER_DOCKER_FILE up -d
    ;;
  down)
    echo "Down.......orderer "$ORDERER_ID
    IMAGE_TAG=$IMAGETAG docker-compose -f $ORDERER_DOCKER_FILE down --volumes
    if [ $ORDERER_ID == "all" ];then
        DEX=`docker ps -a|grep fabric-orderer|awk '{print $1}'`
        if [ "${DEX}x" != "x" ];then
            docker ps -a|grep "fabric-orderer"|awk '{print $1}'|xargs docker stop
            docker ps -a|grep "fabric-orderer"|awk '{print $1}'|xargs docker rm -f
            docker volume ls|grep orderer|awk '{print $2}'|xargs docker volume rm -f
        fi
        rm -rf ./chaincode/orderer
        exit 0
    fi
    
    DEX=`docker ps -a|grep orderer$ORDERER_ID|awk '{print $1}'`
    if [ "${DEX}x" != "x" ];then
        docker ps -a|grep "orderer"$ORDERER_ID|awk '{print $1}'|xargs docker stop
        docker ps -a|grep "orderer"$ORDERER_ID|awk '{print $1}'|xargs docker rm -f
        docker volume ls|grep orderer$ORDERER_ID|awk '{print $2}'|xargs docker volume rm -f
    fi
    rm -rf ./chaincode/orderer/orderer$ORDERER_ID.${DOMAIN_NAME}
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

function node(){
  
  typeset -l DO
  typeset -l ORG_ID
  
  DO=$1
  ORG_ID=$2

  COUCH_DOCKER_FILE="./docker-compose-couch.yaml"
  PEER_DOCKER_FILE="./docker-compose-peer.yaml"
  ORDERER_DOCKER_FILE="./docker-compose-orderer.yaml"
  BASE_PEER_DOCKER_FILE="./base/docker-compose-peer.yaml"

  if [ "x"$ORG_ID == "x" ];then
        echo "orgid should be an integer"
        exit 1
  fi

  if [ $ORG_ID == "all" ];then
        echo "orgid should be an integer"
        exit 1
  fi

  if [ $ORG_ID -le 0 -o $ORG_ID -gt $ORG_NUMBER ];then
        echo "Invalid orgid, or it must less than "$ORG_NUMBER
        exit 1
  fi

  if [ ! -z $USER_HOSTNAME ];then
      ipx=(${USER_HOSTNAME/@/ })
      ipex=`ifconfig | grep ${ipx[1]}`
      if [ -z "$ipex" ];then
          ssh-copy-id $USER_HOSTNAME >&/dev/null
          if [ "$DO" == "up" ];then
              ssh $USER_HOSTNAME "mkdir -p ~/$APP_NAME/base && mkdir -p ~/$APP_NAME/crypto-config/peerOrganizations/org$ORG_ID.${DOMAIN_NAME}/peers"
              SSDOCKER=`ssh $USER_HOSTNAME "ls ~/$APP_NAME|grep $DOCKER_TARNAME"`
              if [ -z "$SSDOCKER" ];then
                  scp $DOCKER_TARNAME $USER_HOSTNAME:~/$APP_NAME/
              fi
              if [ "$OFFLINE_DEPLOY" == "true" ];then
                  SSDOCKER=`ssh $USER_HOSTNAME "docker images | grep kafka"`
                  SFILE=("data/fabric-peer-$IMAGETAG.tar" "data/fabric-couchdb-$IMAGE_TAG_KAFKA.tar" "data/fabric-ccenv-latest.tar" "data/fabric-baseos-amd64-$IMAGE_TAG_KAFKA.tar")
                  for SF in $SFILE;
                  do
                    if [ -f "$SF" ];then
                        scp $SF $USER_HOSTNAME:~/$APP_NAME/data/
                        ssh $USER_HOSTNAME "docker load -i ~/$APP_NAME/data/$SF"
                    else
                        echo "$SF not found"
                        exit 1
                    fi
                  done
              fi
              scp -r "./base/peer-base.yaml" $USER_HOSTNAME:~/$APP_NAME/base/
              scp "./base/.hosts" $USER_HOSTNAME:~/$APP_NAME/base/
              scp -r $COUCH_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/
              scp -r $PEER_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/
              scp -r $ORDERER_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/
              scp -r $BASE_PEER_DOCKER_FILE $USER_HOSTNAME:~/$APP_NAME/base/
              scp -r crypto-config/peerOrganizations/org$ORG_ID.${DOMAIN_NAME}/peers/* $USER_HOSTNAME:~/$APP_NAME/crypto-config/peerOrganizations/org$ORG_ID.${DOMAIN_NAME}/peers/
              scp ".env" $USER_HOSTNAME:~/$APP_NAME/
              scp "generate.lock" $USER_HOSTNAME:~/$APP_NAME/
              scp "cli.sh" $USER_HOSTNAME:~/$APP_NAME/
          elif [ "$DO" == "reload" ];then
              scp "./base/.hosts" $USER_HOSTNAME:~/$APP_NAME/base/
          fi
          ssh $USER_HOSTNAME "cd $APP_NAME;chmod +x cli.sh;./cli.sh node $DO $ORG_ID"
          exit 0
      fi
  fi

  case "$DO" in
  up)
    echo "Up.......peer node org "$ORG_ID
    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        sed -i "s/couchdb${i}[0-9]\{1,10\}/couchdb${i}$ORG_ID/g" $COUCH_DOCKER_FILE
    done
    sed -i "s/org[0-9]\{1,10\}\.${DOMAIN_NAME}/org$ORG_ID\.${DOMAIN_NAME}/g" $COUCH_DOCKER_FILE
    sed -i "s/org[0-9]\{1,10\}\.${DOMAIN_NAME}/org$ORG_ID\.${DOMAIN_NAME}/g" $PEER_DOCKER_FILE
    sed -i "s/org[0-9]\{1,10\}\.${DOMAIN_NAME}/org$ORG_ID\.${DOMAIN_NAME}/g" $BASE_PEER_DOCKER_FILE
    sed -i "s/Org[0-9]\{1,10\}MSP/Org${ORG_ID}MSP/g" $BASE_PEER_DOCKER_FILE
    IMAGE_TAG=$IMAGETAG docker-compose -f $COUCH_DOCKER_FILE -f $PEER_DOCKER_FILE up -d
    sleep 2
    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        docker cp peer$i.org$ORG_ID.${DOMAIN_NAME}:/etc/hosts ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
    done
    ORDERERS=`sed -n '/"orderer.*/p' $ORDERER_DOCKER_FILE`
    
    HOSTS=`cat base/.hosts`
    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        for o in $ORDERERS;
        do
          if [ $o != "-" ]; then
            oo=${o//\"/}
            oo=(${oo//:/ })
            sed -i "/${oo[0]}/d" ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
            echo ${oo[1]}" "${oo[0]} >>./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
          fi 
        done

        for h in $HOSTS;
            do
            h=(${h//:/ })
            sed -i "/${h[0]}/d" ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
            echo ${h[1]}" "${h[0]} >>./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
        done
    done

    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        docker cp ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME} peer$i.org$ORG_ID.${DOMAIN_NAME}:/etc/hosts.new
        docker exec peer$i.org$ORG_ID.${DOMAIN_NAME} cp /etc/hosts.new /etc/hosts
    done
    rm -f ./hosts_peer*
    ;;
  down)
    echo "Down.......peer node org "$ORG_ID
    IMAGE_TAG=$IMAGETAG docker-compose -f $COUCH_DOCKER_FILE -f $PEER_DOCKER_FILE down --volumes
    DEX=`docker ps -a|grep org$ORG_ID|awk '{print $1}'`
    if [ "${DEX}x" != "x" ];then
        docker ps -a|grep "org"$ORG_ID|awk '{print $1}'|xargs docker stop
        docker ps -a|grep "org"$ORG_ID|awk '{print $1}'|xargs docker rm -f
        docker volume ls|grep org$ORG_ID|awk '{print $2}'|xargs docker volume rm -f >&/dev/null
    fi
    
    DEX=`docker ps -a|grep cli|awk '{print $1}'`
    if [ "${DEX}x" != "x" ];then
        BLOCKS=`docker exec cli ls | grep .block`
        for b in $BLOCKS;
        do
          docker exec cli cp $b /opt/gopath/src/github.com/chaincode/
        done
        docker ps -a|grep "cli"|awk '{print $1}'|xargs docker stop
        docker ps -a|grep "cli"|awk '{print $1}'|xargs docker rm -f
    fi

    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        DEX=`docker ps -a|grep couchdb${i}$ORG_ID|awk '{print $1}'`
        if [ "${DEX}x" != "x" ];then
            docker ps -a|grep "couchdb"${i}$ORG_ID|awk '{print $1}'|xargs docker stop
            docker ps -a|grep "couchdb"${i}$ORG_ID|awk '{print $1}'|xargs docker rm -f
            docker volume ls|grep couchdb${i}$ORG_ID|awk '{print $2}'|xargs docker volume rm -f >&/dev/null
        fi
    done
    rm -rf chaincode/peer/*org$ORG_ID.${DOMAIN_NAME}
    ;;
  reload)
    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        docker cp peer$i.org$ORG_ID.${DOMAIN_NAME}:/etc/hosts ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
    done

    HOSTS=`cat base/.hosts`
    for((i=0;i<$PER_ORG_NODE_COUNT;i++));
    do
        for h in $HOSTS;
            do
            h=(${h//:/ })
            sed -i "/${h[0]}/d" ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
            echo ${h[1]}" "${h[0]} >>./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME}
        done
        docker cp ./hosts_peer$i.org$ORG_ID.${DOMAIN_NAME} peer$i.org$ORG_ID.${DOMAIN_NAME}:/etc/hosts.new
        docker exec peer$i.org$ORG_ID.${DOMAIN_NAME} cp /etc/hosts.new /etc/hosts
    done
    rm -f ./hosts_peer*
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

function clireload() {
    BLOCKS=`docker exec cli ls | grep .block`
    for b in $BLOCKS;
    do
      docker exec cli cp $b /opt/gopath/src/github.com/chaincode/
    done
    docker ps -a|grep "cli"|awk '{print $1}'|xargs docker stop
    docker ps -a|grep "cli"|awk '{print $1}'|xargs docker rm -f
    sleep 3
    cliok
}

function cliok() {
    CLI=`docker ps|grep cli|awk '{print $1}'`
    if [ $CLI"x" == "x" ];then
        host fresh
        IMAGE_TAG=$IMAGETAG SYS_CHANNEL=$SYS_CHANNEL docker-compose -f "docker-compose-cli.yaml" up -d
        docker cp core.yaml cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/
        BLOCKS=`docker exec cli ls /opt/gopath/src/github.com/chaincode/| grep .block`
        for b in $BLOCKS;
        do
          docker exec cli cp /opt/gopath/src/github.com/chaincode/$b ./
        done
    fi
}

function generateChannelTxAndAnchorPeers(){

    echo
    echo "#################################################################"
    echo "### Generating channel configuration transaction '"$CHANNEL_NAME".tx' ###"
    echo "#################################################################"

    which configtxgen
    res0=$?
    which cryptogen
    res1=$?
    which fabric-ca-client
    res2=$?
    if [ "$res0" -ne 0 -o "$res1" -ne 0 -o "$res2" -ne 0 ]; then
      tar -zxvf bin.tar.gz
    fi

    cp bin/configtxgen-$IMAGETAG bin/configtxgen >&/dev/null
    cp bin/cryptogen-$IMAGETAG bin/cryptogen >&/dev/null

    set -x
    configtxgen -profile CustomOrgsChannel -outputCreateChannelTx ./channel-artifacts/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi

    for((i=1;i<=$ORG_NUMBER;i++));
    do
        echo
        echo "#################################################################"
        echo "#######    Generating anchor peer update for Org${i}MSP   ##########"
        echo "#################################################################"
        set -x
        configtxgen -profile CustomOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org${i}MSP${CHANNEL_NAME}anchors.tx -channelID $CHANNEL_NAME -asOrg Org${i}MSP
        res=$?
        set +x
        if [ $res -ne 0 ]; then
          echo "Failed to generate anchor peer update for Org${i}MSP..."
          exit 1
        fi
    done
}

function channel() {

  typeset -l DO

  DO=$1
  PEER=$2
  ORG=$3
  PEER=${PEER:="0"}
  ORG=${ORG:="1"}

  cliok

  case "$DO" in
  create)
      generateChannelTxAndAnchorPeers
      clireload
      docker exec cli scripts/script.sh createChannel $CHANNEL_NAME $PEER $ORG
    ;;
  join)
      docker exec cli scripts/script.sh joinChannel $CHANNEL_NAME $PEER $ORG
    ;;
  anchor)
      docker exec cli scripts/script.sh updateAnchorPeers $CHANNEL_NAME $PEER $ORG
    ;;
  list)
      docker exec cli scripts/script.sh listChannel
    ;;
  getinfo)
      docker exec cli scripts/script.sh getinfoChannel $CHANNEL_NAME
    ;;
  fetch)
      docker exec cli scripts/script.sh fetchChannel $CHANNEL_NAME
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

function chaincode() {

  typeset -l DO

  DO=$1
  PEER=$2
  ORG=$3
  PEER=${PEER:="0"}
  ORG=${ORG:="1"}

  cliok

  case "$DO" in
  install)
      docker exec cli scripts/script.sh installChaincode $CHANNEL_NAME $PEER $ORG $LANGUAGE $CHAIN_NAME $CHAIN_VERSION $CHAIN_ARGS $CHAIN_PATH
    ;;
  instantiate)
      docker exec cli scripts/script.sh instantiateChaincode $CHANNEL_NAME $PEER $ORG $LANGUAGE $CHAIN_NAME $CHAIN_VERSION $CHAIN_ARGS $CHAIN_PATH $ENDORSER
    ;;
  invoke)
      docker exec cli scripts/script.sh chaincodeInvoke $CHANNEL_NAME $PEER $ORG $LANGUAGE $CHAIN_NAME $CHAIN_VERSION $CHAIN_ARGS
    ;;
  query)
      docker exec cli scripts/script.sh chaincodeQuery $CHANNEL_NAME $PEER $ORG $LANGUAGE $CHAIN_NAME $CHAIN_VERSION $CHAIN_ARGS
    ;;
  upgrade)
      docker exec cli scripts/script.sh upgradeChaincode $CHANNEL_NAME $PEER $ORG $LANGUAGE $CHAIN_NAME $CHAIN_VERSION $CHAIN_ARGS $CHAIN_PATH $ENDORSER
    ;;
  list)
      docker exec cli scripts/script.sh listChaincode $CHANNEL_NAME $PEER $ORG $LANGUAGE $CHAIN_NAME $CHAIN_VERSION $CHAIN_ARGS
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

function host() {

  typeset -l DO

  DO=$1
  HH=$2
  CLI_RELOAD=$3
  CLI_RELOAD=${CLI_RELOAD:="true"}
  HOST_FILE="base/.hosts"
  HOSTS=`cat $HOST_FILE`
  CLI_FILE="docker-compose-cli.yaml"
  HOST_PREFIX="      - "
  

  case "$DO" in
  add)

      if [ $HH"x" == "" ];then
        echo "host can not be empty"
        exit 1
      fi

       hhtmp=(${HH/:/ })
       sed -i "/${hhtmp[0]}/d" $HOST_FILE
      
      
      for h in $HOSTS;
      do
        sed -i '/extra_hosts:/{:a;n;/.*/d;/-/!ba}' $CLI_FILE
      done

      for((i=0;i<3;i++));
      do
        sed -i '/extra_hosts:/{:a;n;/.*/d;/-/!ba}' $CLI_FILE
      done

      sed -i "/extra_hosts:.*/d" $CLI_FILE
      echo "    extra_hosts:">>$CLI_FILE
      echo $HH>>$HOST_FILE
      HOSTS=`cat $HOST_FILE`
      for h in $HOSTS;
      do
        echo "$HOST_PREFIX$h">>$CLI_FILE
      done

      if [ "$CLI_RELOAD" == "true" ];then
          clireload
      fi
      echo "added host "$HH

    ;;
  del)

      if [ $HH"x" == "" ];then
        echo "host can not be empty"
        exit 1
      fi

      echo "">$HOST_FILE
      found=0
      for h in $HOSTS;
       do
        if [ $HH"x" != $h"x" ];then
          echo $HH>>$HOST_FILE
        else
          found=1
        fi
       done

      if [ $found -eq 1 ];then
          for h in $HOSTS;
          do
            sed -i '/extra_hosts:/{:a;n;/.*/d;/-/!ba}' $CLI_FILE
          done

          for((i=0;i<3;i++));
          do
            sed -i '/extra_hosts:/{:a;n;/.*/d;/-/!ba}' $CLI_FILE
          done

          sed -i "/extra_hosts:.*/d" $CLI_FILE

           echo "    extra_hosts:">>$CLI_FILE
           HOSTS=`cat $HOST_FILE`
           found=0
           for h in $HOSTS;
            do
            found=1
              echo "$HOST_PREFIX$h">>$CLI_FILE
            done

            if [ $found -eq 0 ];then
                sed -i "/extra_hosts:.*/d" $CLI_FILE
            fi

           clireload
      fi
      
       echo "deled host "$HH
    ;;
  ls)
      for h in $HOSTS;
       do
          echo $h 
       done
    ;;
  fresh)
      for h in $HOSTS;
      do
        sed -i '/extra_hosts:/{:a;n;/.*/d;/-/!ba}' $CLI_FILE
      done

      for((i=0;i<3;i++));
      do
        sed -i '/extra_hosts:/{:a;n;/.*/d;/-/!ba}' $CLI_FILE
      done

      sed -i "/extra_hosts:.*/d" $CLI_FILE

      echo "    extra_hosts:">>$CLI_FILE
      HOSTS=`cat $HOST_FILE`
      found=0
      for h in $HOSTS;
      do
       found=1
         echo "$HOST_PREFIX$h">>$CLI_FILE
      done

      if [ $found -eq 0 ];then
          sed -i "/extra_hosts:.*/d" $CLI_FILE
      fi
    ;;
  *)
      echo "Command not found"
      exit 1
    ;;
  esac
}

# do
typeset -l ACTION
ACTION=$1
shift
case "$ACTION" in
  fabric)
    fabric $1
    exit 0
    ;;
  kafka)
    kafka $1 $2
    exit 0
    ;;
  orderer)
    orderer $1 $2
    exit 0
    ;;
  node)
    node $1 $2
    exit 0
    ;;
  channel)
    channel $1 $2 $3 $4
    exit 0
    ;;
  chaincode)
    chaincode $1 $2 $3 $4
    exit 0
    ;;
  host)
    host $1 $2 $3
    exit 0
    ;;
  *)
    printHelp
    exit 1
    ;;
esac