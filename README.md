## Fabric deploy
--------------------------------------------------------------    
fabric安装命令行工具，可动态自定义安装分布式fabric系统至不同节点。目前支持fabric版本1.4.2和1.2.1

#### 全自动fabric分布式安装
```
[root@localhost fabric-deploy]# ./cli.sh fabric init
input 2 numbers are respectively the quantity of orderer and node eg(1 1): 3 3
input is use ca issue node certificate: false (default) : true
input ca server address (host:port) : localhost:7054
input ca server account (user:pass) : admin:123123
This script will guide you through the generation of the fabric organization network configuration
Continue? [Y/n] y
proceeding ...

[root@localhost fabric-deploy]# ./cli.sh fabric install
input install orderer host ip address eg(ip1 ip2): 192.168.56.106 192.168.56.105 192.168.56.104
input install node host ip address eg(ip1 ip2): 192.168.56.101
+ ./cli.sh host add zookeeper1.test.com:192.168.56.106
proceeding ...
===================== Query successful on peer0.org1 on channel 'test' ===================== 
Fabric installation completed!

[root@localhost fabric-deploy]# ./cli.sh fabric uninstall
This action will remove all the fabric system
Continue? [Y/n] y
proceeding ...
Fabric has been removed from the system!
```

#### 配置变量，编辑.env文件配置系统参数

#### cli.sh命令参考

```
[root@localhost fabric-deploy]# ./cli.sh -h
Usage: 
  cli.sh [options] <fabric>    <init|install|uninstall>         "Operate fabric, including init/install/uninstall"
  cli.sh [options] <kafka>     <up|down>             <id|all>    "Operate kafka, including up/down"
  cli.sh [options] <orderer>   <up|down>             <id|all>    "Operate orderer, including up/down"
  cli.sh [options] <node>      <up|down|reload>             <orgid>     "Operate node, including up/down/reload"
  cli.sh [options] <channel>   <create|join|anchor|list|getinfo|fetch>  [peer] [org]    "Operate channel, including create/join/anchor/list/getinfo/fetch"
  cli.sh [options] <chaincode> <install|instantiate|invoke|query|upgrade|list>  [peer] [org]   "Operate chaincode, including install/instantiate/invoke/query/upgrade/list"
  cli.sh [options] <host>      <add|del|ls>          [host:ip]   "Operate cli host map, including add/del/ls"
Options:
    -b <endorser> - specify an endorsement strategy (defaults to "OR (Org{1,2,3}MSP)")
    -c <channel name> - channel name to use (defaults to "test")
    -t <timeout> - CLI timeout duration in seconds (defaults to 10)
    -d <delay> - delay duration in seconds (defaults to 3)
    -s <dbtype> - the database backend to use: goleveldb or couchdb (default) 
    -l <language> - the chaincode language: golang (default) or node
    -m <chaincode name> - the chaincode name: testcc (default)
    -r <chaincode version> - the chaincode version: 1.0 (default)
    -p <chaincode path> - the chaincode path: github.com/chaincode/chaincode_example02/go/ (default)
    -g <chaincode init args> - the chaincode init args: {"Args":["init","a","100","b","200"]} (default)
    -o <consensus-type> - the consensus-type of the ordering service: solo (default), kafka, or etcdraft
    -i <imagetag> - the tag to be used to launch the network (defaults to "latest")
    -u <user@hostname> which host to deploy on
    -a - launch certificate authorities (no certificate authorities are launched by default)
    -v - verbose mode
  cli.sh -h (print this message)


[root@localhost fabric-deploy]# ./cli.sh kafka up 1
Up.......kafka 1
Creating volume "net_zookeeper1.test.com" with default driver
Creating volume "net_kafka1.test.com" with default driver
Creating zookeeper1.test.com ... done
Creating kafka1.test.com     ... done
[root@localhost fabric-deploy]# ./cli.sh -u root@centos7-6  kafka up 2
docker-compose-kafka.yaml                                                                                                                                                  100% 2429     2.7MB/s   00:00    
.env                                                                                                                                                                       100%  192   385.8KB/s   00:00    
generate.lock                                                                                                                                                              100%   45    98.1KB/s   00:00    
cli.sh                                                                                                                                                                     100%   23KB  25.2MB/s   00:00    
Up.......kafka 2
Creating volume "net_zookeeper2.test.com" with default driver
Creating volume "net_kafka2.test.com" with default driver
Creating zookeeper2.test.com ... done
Creating kafka2.test.com     ... done
[root@localhost fabric-deploy]# ./cli.sh -u root@centos7-5  kafka up 3
docker-compose-kafka.yaml                                                                                                                                                  100% 2429   808.5KB/s   00:00    
.env                                                                                                                                                                       100%  192    19.3KB/s   00:00    
generate.lock                                                                                                                                                              100%   45     7.9KB/s   00:00    
cli.sh                                                                                                                                                                     100%   23KB   5.7MB/s   00:00    
Up.......kafka 3
Creating volume "net_zookeeper3.test.com" with default driver
Creating volume "net_kafka3.test.com" with default driver
Creating zookeeper3.test.com ... done
Creating kafka3.test.com     ... done
[root@localhost fabric-deploy]# ./cli.sh orderer up 1
Up.......orderer 1
Creating volume "net_orderer1.test.com" with default driver
WARNING: Found orphan containers (kafka1.test.com, zookeeper1.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating orderer1.test.com ... done
[root@localhost fabric-deploy]# ./cli.sh -u root@centos7-6 orderer up 2
orderer-base.yaml                                                                                                                                                          100% 1504     1.9MB/s   00:00    
docker-compose-orderer.yaml                                                                                                                                                100%  733     1.0MB/s   00:00    
docker-compose-orderer.yaml                                                                                                                                                100%  658   825.6KB/s   00:00    
genesis.block                                                                                                                                                              100%   21KB  14.4MB/s   00:00    
bfe7df99952836fd5d295e1b4b809a2976719568c253efac8060fe1abf238f82_sk                                                                                                        100%  241   150.1KB/s   00:00    
orderer2.test.com-cert.pem                                                                                                                                            100% 1086     1.1MB/s   00:00    
ca.test.com-cert.pem                                                                                                                                                  100%  786   664.8KB/s   00:00    
Admin@test.com-cert.pem                                                                                                                                               100% 1099   909.2KB/s   00:00    
tlsca.test.com-cert.pem                                                                                                                                               100%  786   784.7KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786   687.0KB/s   00:00    
server.crt                                                                                                                                                                 100% 1131     1.2MB/s   00:00    
server.key                                                                                                                                                                 100%  241   244.3KB/s   00:00    
.env                                                                                                                                                                       100%  192   380.8KB/s   00:00    
generate.lock                                                                                                                                                              100%   45    86.6KB/s   00:00    
cli.sh                                                                                                                                                                     100%   23KB  19.5MB/s   00:00    
Up.......orderer 2
Creating volume "net_orderer2.test.com" with default driver
Found orphan containers (kafka2.test.com, zookeeper2.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating orderer2.test.com ... done
[root@localhost fabric-deploy]# ./cli.sh -u root@centos7-5 orderer up 3
orderer-base.yaml                                                                                                                                                          100% 1504     2.2MB/s   00:00    
docker-compose-orderer.yaml                                                                                                                                                100%  733    45.6KB/s   00:00    
docker-compose-orderer.yaml                                                                                                                                                100%  658     1.0MB/s   00:00    
genesis.block                                                                                                                                                              100%   21KB   4.1MB/s   00:00    
0953183fd4d04e2c683b9efce3acaef1fb9b221f5e78cb2ddaca881bb809378f_sk                                                                                                        100%  241   205.9KB/s   00:00    
orderer3.test.com-cert.pem                                                                                                                                            100% 1086     1.0MB/s   00:00    
ca.test.com-cert.pem                                                                                                                                                  100%  786   620.1KB/s   00:00    
Admin@test.com-cert.pem                                                                                                                                               100% 1099   819.8KB/s   00:00    
tlsca.test.com-cert.pem                                                                                                                                               100%  786   716.9KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786   296.6KB/s   00:00    
server.crt                                                                                                                                                                 100% 1131     1.1MB/s   00:00    
server.key                                                                                                                                                                 100%  241   267.5KB/s   00:00    
.env                                                                                                                                                                       100%  192   294.4KB/s   00:00    
generate.lock                                                                                                                                                              100%   45    85.7KB/s   00:00    
cli.sh                                                                                                                                                                     100%   23KB  22.2MB/s   00:00    
Up.......orderer 3
Creating volume "net_orderer3.test.com" with default driver
Found orphan containers (kafka3.test.com, zookeeper3.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating orderer3.test.com ... done
[root@localhost fabric-deploy]# ./cli.sh -u root@centos7-6 node up 1
peer-base.yaml                                                                                                                                                             100% 1017   786.4KB/s   00:00    
.hosts                                                                                                                                                                     100%  239    27.5KB/s   00:00    
docker-compose-couch.yaml                                                                                                                                                  100% 3514   363.4KB/s   00:00    
docker-compose-peer.yaml                                                                                                                                                   100%  805    91.9KB/s   00:00    
docker-compose-peer.yaml                                                                                                                                                   100% 3124   358.4KB/s   00:00    
df0bdd9d23427c8295b1e82598ec983144e98dd43e35b3826d2a0c23295f1949_sk                                                                                                        100%  241   184.7KB/s   00:00    
peer0.org1.test.com-cert.pem                                                                                                                                          100% 1115     1.3MB/s   00:00    
ca.org1.test.com-cert.pem                                                                                                                                             100%  786   946.1KB/s   00:00    
Admin@org1.test.com-cert.pem                                                                                                                                          100% 1139     1.2MB/s   00:00    
tlsca.org1.test.com-cert.pem                                                                                                                                          100%  786   858.0KB/s   00:00    
config.yaml                                                                                                                                                                100%  258   206.3KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786   778.9KB/s   00:00    
server.crt                                                                                                                                                                 100% 1155     1.0MB/s   00:00    
server.key                                                                                                                                                                 100%  241   154.6KB/s   00:00    
d57ba62c5403ce5ab58e0fd53087c256e10bbcbe084c5e2ad62389a849e46d1e_sk                                                                                                        100%  241   222.0KB/s   00:00    
peer1.org1.test.com-cert.pem                                                                                                                                          100% 1115   925.0KB/s   00:00    
ca.org1.test.com-cert.pem                                                                                                                                             100%  786   831.1KB/s   00:00    
Admin@org1.test.com-cert.pem                                                                                                                                          100% 1139   909.3KB/s   00:00    
tlsca.org1.test.com-cert.pem                                                                                                                                          100%  786   308.7KB/s   00:00    
config.yaml                                                                                                                                                                100%  258   242.9KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786   544.9KB/s   00:00    
server.crt                                                                                                                                                                 100% 1155   172.7KB/s   00:00    
server.key                                                                                                                                                                 100%  241   193.5KB/s   00:00    
dc3ff995b1f19d5736aadef1b78b1bca1c395ec7f5e5e4481f695d1844625fa1_sk                                                                                                        100%  241   283.0KB/s   00:00    
peer2.org1.test.com-cert.pem                                                                                                                                          100% 1115     1.4MB/s   00:00    
ca.org1.test.com-cert.pem                                                                                                                                             100%  786   874.2KB/s   00:00    
Admin@org1.test.com-cert.pem                                                                                                                                          100% 1139     1.4MB/s   00:00    
tlsca.org1.test.com-cert.pem                                                                                                                                          100%  786   747.8KB/s   00:00    
config.yaml                                                                                                                                                                100%  258   114.7KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786     1.1MB/s   00:00    
server.crt                                                                                                                                                                 100% 1155     1.2MB/s   00:00    
server.key                                                                                                                                                                 100%  241   302.7KB/s   00:00    
.env                                                                                                                                                                       100%  192   397.7KB/s   00:00    
generate.lock                                                                                                                                                              100%   45    99.1KB/s   00:00    
cli.sh                                                                                                                                                                     100%   23KB  21.5MB/s   00:00    
Up.......peer node org 1
Creating volume "net_couchdb01" with default driver
Creating volume "net_couchdb11" with default driver
Creating volume "net_couchdb21" with default driver
Creating volume "net_peer0.org1.test.com" with default driver
Creating volume "net_peer1.org1.test.com" with default driver
Creating volume "net_peer2.org1.test.com" with default driver
Found orphan containers (orderer2.test.com, kafka2.test.com, zookeeper2.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating couchdb11 ... done
Creating couchdb01                ... done
Creating couchdb21                ... done
Creating peer1.org1.test.com ... done
Creating peer0.org1.test.com ... done
Creating peer2.org1.test.com ... done
[root@localhost fabric-deploy]# ./cli.sh -u root@centos7-5 node up 2
peer-base.yaml                                                                                                                                                             100% 1017     1.5MB/s   00:00    
.hosts                                                                                                                                                                     100%  239   272.7KB/s   00:00    
docker-compose-couch.yaml                                                                                                                                                  100% 3514     6.3MB/s   00:00    
docker-compose-peer.yaml                                                                                                                                                   100%  805     1.1MB/s   00:00    
docker-compose-peer.yaml                                                                                                                                                   100% 3124     5.0MB/s   00:00    
db42201c8275bdd90903881dc3057f91d174d14fcb1ed4ec35f483c3cb2d70f0_sk                                                                                                        100%  241   229.3KB/s   00:00    
peer0.org2.test.com-cert.pem                                                                                                                                          100% 1115   959.5KB/s   00:00    
ca.org2.test.com-cert.pem                                                                                                                                             100%  786   684.3KB/s   00:00    
Admin@org2.test.com-cert.pem                                                                                                                                          100% 1139   907.8KB/s   00:00    
tlsca.org2.test.com-cert.pem                                                                                                                                          100%  786   752.5KB/s   00:00    
config.yaml                                                                                                                                                                100%  258   269.9KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786     1.3MB/s   00:00    
server.crt                                                                                                                                                                 100% 1155     1.0MB/s   00:00    
server.key                                                                                                                                                                 100%  241   262.7KB/s   00:00    
a0309ba4988722976b6e748a39d900106bdd40f440c089042fffbf7ee475bc25_sk                                                                                                        100%  241   251.3KB/s   00:00    
peer1.org2.test.com-cert.pem                                                                                                                                          100% 1115     1.0MB/s   00:00    
ca.org2.test.com-cert.pem                                                                                                                                             100%  786   747.1KB/s   00:00    
Admin@org2.test.com-cert.pem                                                                                                                                          100% 1139     1.2MB/s   00:00    
tlsca.org2.test.com-cert.pem                                                                                                                                          100%  786   798.5KB/s   00:00    
config.yaml                                                                                                                                                                100%  258   269.3KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786   557.3KB/s   00:00    
server.crt                                                                                                                                                                 100% 1155     1.0MB/s   00:00    
server.key                                                                                                                                                                 100%  241   242.4KB/s   00:00    
2a56acd3484062a41cef2e3095cd807bdb5286444fd5a400aeb58e954e7dafe1_sk                                                                                                        100%  241   257.4KB/s   00:00    
peer2.org2.test.com-cert.pem                                                                                                                                          100% 1115     1.2MB/s   00:00    
ca.org2.test.com-cert.pem                                                                                                                                             100%  786   597.1KB/s   00:00    
Admin@org2.test.com-cert.pem                                                                                                                                          100% 1139     1.1MB/s   00:00    
tlsca.org2.test.com-cert.pem                                                                                                                                          100%  786   708.4KB/s   00:00    
config.yaml                                                                                                                                                                100%  258   294.2KB/s   00:00    
ca.crt                                                                                                                                                                     100%  786     1.0MB/s   00:00    
server.crt                                                                                                                                                                 100% 1155     1.4MB/s   00:00    
server.key                                                                                                                                                                 100%  241   360.7KB/s   00:00    
.env                                                                                                                                                                       100%  192   118.1KB/s   00:00    
generate.lock                                                                                                                                                              100%   45    92.9KB/s   00:00    
cli.sh                                                                                                                                                                     100%   23KB  23.0MB/s   00:00    
Up.......peer node org 2
Creating volume "net_couchdb02" with default driver
Creating volume "net_couchdb12" with default driver
Creating volume "net_couchdb22" with default driver
Creating volume "net_peer0.org2.test.com" with default driver
Creating volume "net_peer1.org2.test.com" with default driver
Creating volume "net_peer2.org2.test.com" with default driver
Found orphan containers (orderer3.test.com, kafka3.test.com, zookeeper3.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating couchdb02                ... done
Creating couchdb12 ... done
Creating couchdb22                ... done
Creating peer1.org2.test.com ... done
Creating peer2.org2.test.com ... done
Creating peer0.org2.test.com ... done
[root@localhost fabric-deploy]# ./cli.sh node up 3
Up.......peer node org 3
Creating volume "net_couchdb03" with default driver
Creating volume "net_couchdb13" with default driver
Creating volume "net_couchdb23" with default driver
Creating volume "net_peer0.org3.test.com" with default driver
Creating volume "net_peer1.org3.test.com" with default driver
Creating volume "net_peer2.org3.test.com" with default driver
WARNING: Found orphan containers (orderer1.test.com, kafka1.test.com, zookeeper1.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating couchdb13                ... done
Creating couchdb03                ... done
Creating couchdb23 ... done
Creating peer2.org3.test.com ... done
Creating peer0.org3.test.com ... done
Creating peer1.org3.test.com ... done
[root@localhost fabric-deploy]# ./cli.sh channel create 0 2
WARNING: Found orphan containers (peer1.org3.test.com, peer0.org3.test.com, peer2.org3.test.com, couchdb03, couchdb23, couchdb13, orderer1.test.com, kafka1.test.com, zookeeper1.test.com) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Creating cli ... done
Channel name : mychannel Org:2
+ peer channel create -o orderer1.test.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem
+ res=0
+ set +x
2019-09-03 11:19:13.894 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:19:14.003 UTC [cli.common] readBlock -> INFO 002 Got status: &{SERVICE_UNAVAILABLE}
2019-09-03 11:19:14.008 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2019-09-03 11:19:14.209 UTC [cli.common] readBlock -> INFO 004 Got status: &{SERVICE_UNAVAILABLE}
2019-09-03 11:19:14.212 UTC [channelCmd] InitCmdFactory -> INFO 005 Endorser and orderer connections initialized
2019-09-03 11:19:14.413 UTC [cli.common] readBlock -> INFO 006 Got status: &{SERVICE_UNAVAILABLE}
2019-09-03 11:19:14.416 UTC [channelCmd] InitCmdFactory -> INFO 007 Endorser and orderer connections initialized
2019-09-03 11:19:14.622 UTC [cli.common] readBlock -> INFO 008 Received block: 0
===================== Channel 'mychannel' created ===================== 

[root@localhost fabric-deploy]# ./cli.sh channel join 0 2
Channel name : mychannel Org:2
+ peer channel join -b mychannel.block
+ res=0
+ set +x
2019-09-03 11:19:17.452 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:19:17.637 UTC [channelCmd] executeJoin -> INFO 002 Successfully submitted proposal to join channel
===================== peer0.org2 joined channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh channel anchor 0 2
Channel name : mychannel Org:2
+ peer channel update -o orderer1.test.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem
+ res=0
+ set +x
2019-09-03 11:19:25.720 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:19:25.805 UTC [channelCmd] update -> INFO 002 Successfully submitted channel update
===================== Anchor peers updated for org 'Org2MSP' on channel 'mychannel' ===================== 

[root@localhost fabric-deploy]# ./cli.sh chaincode install 0 2
Channel name : mychannel Org:2
+ peer chaincode install -n mycc -v 1.0 -l golang -p github.com/chaincode/chaincode_example02/go/
+ res=0
+ set +x
2019-09-03 11:19:32.591 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 001 Using default escc
2019-09-03 11:19:32.591 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default vscc
2019-09-03 11:19:33.128 UTC [chaincodeCmd] install -> INFO 003 Installed remotely response:<status:200 payload:"OK" > 
===================== Chaincode is installed on peer0.org2 ===================== 

[root@localhost fabric-deploy]# ./cli.sh chaincode instantiate 0 2
Channel name : mychannel Org:2
+ peer chaincode instantiate -o orderer1.test.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem -C mychannel -n mycc -l golang -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P 'OR("Org1MSP.peer","Org2MSP.peer","Org3MSP.peer")'
+ res=0
+ set +x
2019-09-03 11:19:39.332 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 001 Using default escc
2019-09-03 11:19:39.332 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default vscc
===================== Chaincode is instantiated on peer0.org2 on channel 'mychannel' with Endoser OR("Org1MSP.peer","Org2MSP.peer","Org3MSP.peer")===================== 

[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 2
Channel name : mychannel Org:2
===================== Querying on peer0.org2 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org2 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

100
===================== Query successful on peer0.org2 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["invoke","a","b","10"]}' chaincode invoke 0 2
Channel name : mychannel Org:2
+ peer chaincode invoke -o orderer1.test.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org2.test.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.test.com/peers/peer0.org2.test.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
+ res=0
+ set +x
2019-09-03 11:20:35.025 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200 
===================== Invoke transaction successful on peer0.org2 on channel 'mychannel' ===================== 

[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 2
Channel name : mychannel Org:2
===================== Querying on peer0.org2 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org2 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

90
===================== Query successful on peer0.org2 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh channel join
Channel name : mychannel Org:1
+ peer channel join -b mychannel.block
+ res=0
+ set +x
2019-09-03 11:21:01.866 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:21:02.053 UTC [channelCmd] executeJoin -> INFO 002 Successfully submitted proposal to join channel
===================== peer0.org1 joined channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh channel anchor
Channel name : mychannel Org:1
+ peer channel update -o orderer1.test.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem
+ res=0
+ set +x
2019-09-03 11:21:07.658 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:21:07.712 UTC [channelCmd] update -> INFO 002 Successfully submitted channel update
===================== Anchor peers updated for org 'Org1MSP' on channel 'mychannel' ===================== 

[root@localhost fabric-deploy]# ./cli.sh chaincode install
Channel name : mychannel Org:1
+ peer chaincode install -n mycc -v 1.0 -l golang -p github.com/chaincode/chaincode_example02/go/
+ res=0
+ set +x
2019-09-03 11:21:17.596 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 001 Using default escc
2019-09-03 11:21:17.596 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default vscc
2019-09-03 11:21:17.973 UTC [chaincodeCmd] install -> INFO 003 Installed remotely response:<status:200 payload:"OK" > 
===================== Chaincode is installed on peer0.org1 ===================== 

[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 1
Channel name : mychannel Org:1
===================== Querying on peer0.org1 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org1 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

90
===================== Query successful on peer0.org1 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["invoke","a","b","10"]}' chaincode invoke 0 1
Channel name : mychannel Org:1
+ peer chaincode invoke -o orderer1.test.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.test.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.test.com/peers/peer0.org1.test.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
+ res=0
+ set +x
2019-09-03 11:21:47.385 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200 
===================== Invoke transaction successful on peer0.org1 on channel 'mychannel' ===================== 

[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 1
Channel name : mychannel Org:1
===================== Querying on peer0.org1 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org1 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

80
===================== Query successful on peer0.org1 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 2
Channel name : mychannel Org:2
===================== Querying on peer0.org2 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org2 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

80
===================== Query successful on peer0.org2 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh channel join 0 3
Channel name : mychannel Org:3
+ peer channel join -b mychannel.block
+ res=0
+ set +x
2019-09-03 11:22:29.061 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:22:29.275 UTC [channelCmd] executeJoin -> INFO 002 Successfully submitted proposal to join channel
===================== peer0.org3 joined channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh channel anchor 0 3
Channel name : mychannel Org:3
+ peer channel update -o orderer1.test.com:7050 -c mychannel -f ./channel-artifacts/Org3MSPanchors.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem
2019-09-03 11:22:34.944 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2019-09-03 11:22:34.986 UTC [channelCmd] update -> INFO 002 Successfully submitted channel update
+ res=0
+ set +x
===================== Anchor peers updated for org 'Org3MSP' on channel 'mychannel' ===================== 

[root@localhost fabric-deploy]# ./cli.sh chaincode install 0 3
Channel name : mychannel Org:3
+ peer chaincode install -n mycc -v 1.0 -l golang -p github.com/chaincode/chaincode_example02/go/
+ res=0
+ set +x
2019-09-03 11:22:41.047 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 001 Using default escc
2019-09-03 11:22:41.047 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default vscc
2019-09-03 11:22:41.394 UTC [chaincodeCmd] install -> INFO 003 Installed remotely response:<status:200 payload:"OK" > 
===================== Chaincode is installed on peer0.org3 ===================== 

[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 3
Channel name : mychannel Org:3
===================== Querying on peer0.org3 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org3 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

80
===================== Query successful on peer0.org3 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["invoke","a","b","10"]}' chaincode invoke 0 3
Channel name : mychannel Org:3
+ peer chaincode invoke -o orderer1.test.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/test.com/orderers/orderer1.test.com/msp/tlscacerts/tlsca.test.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org3.test.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.test.com/peers/peer0.org3.test.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
+ res=0
+ set +x
2019-09-03 11:23:08.664 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200 
===================== Invoke transaction successful on peer0.org3 on channel 'mychannel' ===================== 

[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 3
Channel name : mychannel Org:3
===================== Querying on peer0.org3 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org3 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

70
===================== Query successful on peer0.org3 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 2
Channel name : mychannel Org:2
===================== Querying on peer0.org2 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org2 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

70
===================== Query successful on peer0.org2 on channel 'mychannel' ===================== 
[root@localhost fabric-deploy]# ./cli.sh -g '{"Args":["query","a"]}' chaincode query 0 1
Channel name : mychannel Org:1
===================== Querying on peer0.org1 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org1 ...3 secs
+ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
+ res=0
+ set +x

70
===================== Query successful on peer0.org1 on channel 'mychannel' =====================
```