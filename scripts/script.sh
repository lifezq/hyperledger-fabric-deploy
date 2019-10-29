#!/bin/bash
#
# Script
#
# @Author Ryan
# @Link   github.com/lifezq
# @Datetime 2019-09-04
#

METHOD="$1"
CHANNEL_NAME="$2"
PEERCODE="$3"
ORGCODE="$4"
LANGUAGE="$5"
CHAIN_NAME="$6"
CHAIN_VERSION="$7"
CHAIN_ARGS="$8"
CC_SRC_PATH="$9"
ENDORSER="${10}"
DELAY="${11}"
TIMEOUT="${12}"
VERBOSE="${13}"

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
: ${PEERCODE:="0"}
: ${ORGCODE:="1"}

LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

# echo "Channel name : "$CHANNEL_NAME" Org:"$ORGCODE

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals $PEERCODE $ORGCODE

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer1.${DOMAIN_NAME}:7050 -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer1.${DOMAIN_NAME}:7050 -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

case "$METHOD" in
  createChannel)
    createChannel
    exit 0
    ;;
  joinChannel)
    joinChannelWithRetry $PEERCODE $ORGCODE
	echo "===================== peer${PEERCODE}.org${ORGCODE} joined channel '$CHANNEL_NAME' ===================== "
    exit 0
    ;;
  listChannel)
    peer channel list
    exit 0
    ;;
  getinfoChannel)
    peer channel getinfo -c $CHANNEL_NAME
    exit 0
    ;;
  fetchChannel)
    OUT_JSON="fetch_out.json"
    fetchChannelConfig $CHANNEL_NAME $OUT_JSON
    set -x
    cat $OUT_JSON
    set +x
    rm -f $OUT_JSON
    exit 0
    ;;
  updateAnchorPeers)
    updateAnchorPeers $PEERCODE $ORGCODE
    exit 0
    ;;
  installChaincode)
    installChaincode $PEERCODE $ORGCODE
    exit 0
    ;;
  instantiateChaincode)
    instantiateChaincode $PEERCODE $ORGCODE 
    exit 0
    ;;
  chaincodeInvoke)
    chaincodeInvoke $PEERCODE $ORGCODE
    exit 0
    ;;
  chaincodeQuery)
    chaincodeQuery $PEERCODE $ORGCODE
    exit 0
    ;;
  upgradeChaincode)
    upgradeChaincode $PEERCODE $ORGCODE
    exit 0
    ;;
  listChaincode)
    setGlobals $PEERCODE $ORGCODE
    peer chaincode list --installed
    peer chaincode list -C $CHANNEL_NAME --instantiated >&log.txt
    res=$?
    if test $res -eq 0 ;then
      cat log.txt
    else
      echo "No instantiated chaincodes on channel <$CHANNEL_NAME>"
    fi
    exit 0
    ;;
  *)
    echo "command not found"
    exit 1
    ;;
esac
