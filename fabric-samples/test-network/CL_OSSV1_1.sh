#!/bin/zsh
#
# SPDX-License-Identifier: Apache-2.0

# default to using Org1

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

export PATH=${PWD}/../bin:${PWD}:$PATH 
export FABRIC_CFG_PATH=${PWD}/../config

ORDERER_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt # path to orderer TLS certification file
ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
PEER0_ORG1_CA=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
PEER0_ORG2_CA=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
PEER0_ORG3_CA=${DIR}/test-network/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
CORE_PEER_TLS_ENABLED=true
ORDERER_ADDRESS=localhost:7050

CORE_PEER_TLS_ROOTCERT_FILE_ORG1=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
CORE_PEER_TLS_ROOTCERT_FILE_ORG2=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem

export "PEER0_ORG1_CA=${PEER0_ORG1_CA}"
export "PEER0_ORG2_CA=${PEER0_ORG2_CA}"
export "PEER0_ORG3_CA=${PEER0_ORG3_CA}"
export "CORE_PEER_TLS_ENABLED=true"
export "ORDERER_CA=${ORDERER_CA}"
export "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"

CHANNEL_NAME="testchannel"
# CHAINCODE_NAME="OssV1"
CHAINCODE_NAME="OssV1_1"
# TARFILE_NAME="OssV1_1"
CHAINCODE_VERSION="0" 
CHAINCODE_PATH="../chaincode/oss-app/go/"
CHAINCODE_LANG="golang"
CHAINCODE_LABEL="OssV1_1"
# CHAINCODE_LABEL="property_1" 

# environment variables for ORG1
setEnvVarsForPeer0Org1() {
   CORE_PEER_LOCALMSPID=Org1MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
   CORE_PEER_ADDRESS=localhost:7051
   CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE_ORG1}

   export "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE_ORG1}" # exported
   export "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
   export "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
}

# environment variables for ORG2
setEnvVarsForPeer0Org2() {
   CORE_PEER_LOCALMSPID=Org2MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
   CORE_PEER_ADDRESS=localhost:9051
   CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE_ORG2}

   export "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE_ORG2}" # exported
   export "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
   export "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
}

#packaging is done on another folder

installChaincode() {
    echo "===================== Installing Chaincode on peer0.org1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz\
    --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1
    echo "===================== Chaincode is installed on peer0.org1 ===================== "
    echo 
    echo "===================== Installing Chaincode on peer0.org2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz\
    --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2
    echo "===================== Chaincode is installed on peer0.org2 ===================== "
}

queryInstalled() {
    echo "===================== Querying Installed Chaincode on peer0.org1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode queryinstalled --peerAddresses $CORE_PEER_ADDRESS\
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CHAINCODE_LABEL}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed chaincode successful on peer0.org1 ===================== "
}

approveForMyOrg1() {
    echo "===================== Approving chaincode definition from org 1 ===================== "
    setEnvVarsForPeer0Org1

    # added --certfile flag so that the command will point to the correct certfile directory
    # peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS\
    # --ordererTLSHostnameOverride orderer.example.com --tls --certfile $ORDERER_CERT --cafile $ORDERER_CA\ 
    # --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION}\
    # --init-required --package-id ${PACKAGE_ID} --sequence 1
    
    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA\
    --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION}\
    --init-required --package-id ${PACKAGE_ID} --sequence 1
    echo "===================== Chaincode approved from org 1 ===================== "
}

checkCommitReadinessForOrg1() {
    echo "===================== Checking commit readiness from org 1 ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME}\
    --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 --output json --init-required
    echo "===================== Successfully checking commit readiness from org 1 ===================== "
}

approveForMyOrg2() {
    echo "===================== Approving chaincode definition from org 2 ===================== "
    setEnvVarsForPeer0Org2

    # i added --certfile flag so that the command will point to the correct certfile directory
    # peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS\
    # --ordererTLSHostnameOverride orderer.example.com --tls --certfile $ORDERER_CERT --cafile $ORDERER_CA\
    # --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION}\
    # --init-required --package-id ${PACKAGE_ID} --sequence 1

    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA\
    --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION}\
    --init-required --package-id ${PACKAGE_ID} --sequence 1
    echo "===================== Chaincode approved from org 2 ===================== "
}

checkCommitReadinessForOrg2() {
    echo "===================== Checking commit readiness from org 2 ===================== "
    setEnvVarsForPeer0Org2
    peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME}\
    --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 --output json --init-required
    echo "===================== Successfully checking commit readiness from org 2 ===================== "
}

commitChaincodeDefinition() {
    echo "===================== Committing chaincode definition on channel ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    --version ${CHAINCODE_VERSION} --sequence 1 --init-required
    echo "===================== Chaincode definition successfully committed on channel ===================== "
}

queryCommitted() {
    echo "===================== Querying committed chaincode definition on channel ===================== "
    setEnvVarsForPeer0Org1
    peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME}
    echo "===================== Queried the chaincode definition committed on channel ===================== "
}

############################## INTERACTION WITH CHAINCODE ##############################

chaincodeInvokeInit() {
    echo "===================== Initializing chaincode===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    --isInit -c '{"Args":[]}'
    echo "===================== Succesfully initialized the chaincode===================== "
    echo 
}

# Un-comment if need to run dynamically [run the arguments via cmd]
# # Usage message 
# function usage {
#     echo "Usage: $0 [-i|--isInit] '<chaincode_invoke_arguments>'"
#     echo "Example for initialization: $0 -i '{\"Args\":[]}'"
#     echo "Example for invocation: $0 '{\"Args\":[\"QueryPropertyById\", \"1\"]}'"
#     exit 1
# }

# # Check if arguments are provided
# if [ $# -eq 0 ]; then
#     usage
# fi

# # Initialize variables
# IS_INIT=""
# ARGS=""

# # Parse the arguments
# while [[ "$#" -gt 0 ]]; do
#     case $1 in
#         -i|--isInit) IS_INIT="--isInit"; shift ;;
#         -c) ARGS="$2"; shift 2 ;;
#         *) ARGS="$1"; shift ;;
#     esac
# done

# # Check if ARGS is set
# if [ -z "$ARGS" ]; then
#     usage
# fi

chaincodeFunction() {
    # echo "===================== Starting chaincode function===================== "
    setEnvVarsForPeer0Org1
    peer chaincode invoke -o $ORDERER_ADDRESS\
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED\
    --cafile $ORDERER_CA -C ${CHANNEL_NAME} --name ${CHAINCODE_NAME}\
    --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1\
    --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2\
    $1 -c "$2"
    # echo "===================== Successfully added new document ===================== "
}

# Install and approve chaincode
installChaincode
queryInstalled
approveForMyOrg1
checkCommitReadinessForOrg1
approveForMyOrg2
checkCommitReadinessForOrg2
commitChaincodeDefinition
queryCommitted

# Initialize the chaincode
chaincodeInvokeInit 
echo "===================== Chaincode Initialization Complete ===================== "
echo
# Run the chaincode function
# chaincodeFunction "$ARGS"
sleep 5

# # Array of arguments to create a new doc
# declare -a ARGS_ARRAY_CREATE_DOC=(
#     '{"Args":["CreateDoc", "user123", "doc456","Example Document 1","pdf","2023-07-06T12:34:56Z", "QmTzQ1N4aVx7Mh3Uq7P8L2V9Rz1Q4uQ8Wz1F1R2P3S4T5"]}'
#     '{"Args":["CreateDoc", "user123", "doc891","Example Document 4","pdf","2023-07-06T14:34:56Z", "QmTzQ1N4aVx7Mh3Uq7P8L2W9Rz1Q4uQ8Wz1F1R2P3S4T5"]}'
#     '{"Args":["CreateDoc", "user124", "doc467","Example Document 2","pdf","2023-07-06T14:34:56Z", "QmTzQ1N4aVx7Mh3Uq7P8L2V9Rz1Q4uQ8Wz1F1R2P3G4F5"]}'
#     '{"Args":["CreateDoc", "user124", "doc764","Example Document 3","pdf","2023-07-06T14:35:56Z", "QmTzQ1N4aVx7Mh3Wq7P8L2V9Rz1Q4uQ8Wz1F1R2P3G4F5"]}'
# )

# # Loop through the array and invoke the chaincode function
# for ARGS_CREATE_DOC in "${ARGS_ARRAY_CREATE_DOC[@]}"; doCHAINCODE_NAME
#     echo "===================== Adding a new document ===================== "
#     chaincodeFunction "" "$ARGS_CREATE_DOC"
#     echo "===================== Successfully added a new document ===================== "
#     echo
#     sleep 5
# done

# ########################################################################

# # Array of arguments to query a doc by user id
# declare -a ARGS_ARRAY_QUERY_DOC_BY_USER_ID=(
#     '{"Args":["QueryDocByUserId", "user124"]}'
#     '{"Args":["QueryDocByUserId", "user123"]}'
#     # '{"Args":["QueryDocByUserId", "user122"]}' #should be an error
# )

# # Loop through the array and invoke the chaincode function
# for ARGS_USER_ID in "${ARGS_ARRAY_QUERY_DOC_BY_USER_ID[@]}"; do
#     echo "===================== Querying a specific document by user id ===================== "
#     chaincodeFunction "" "$ARGS_USER_ID"
#     echo "===================== Document successfully queried ===================== "
#     echo
#     sleep 5
# done

# ########################################################################

# # Array of arguments to query a doc by name
# declare -a ARGS_ARRAY_QUERY_DOC_BY_NAME=(
#     # '{"Args":["QueryDocByName", "Example Document"]}' #should be an error
#     '{"Args":["QueryDocByName", "Example Document 1"]}'
#     '{"Args":["QueryDocByName", "Example Document 2"]}'
#     '{"Args":["QueryDocByName", "Example Document 3"]}'
#     '{"Args":["QueryDocByName", "Example Document 4"]}'
# )

# # Loop through the array and invoke the chaincode function
# for ARGS_DOC_NAME in "${ARGS_ARRAY_QUERY_DOC_BY_NAME[@]}"; do
#     echo "===================== Querying a specific document by document name ===================== "
#     chaincodeFunction "" "$ARGS_DOC_NAME"
#     echo "===================== Document successfully queried ===================== "
#     echo
#     sleep 5
# done

# ########################################################################

# # Array of arguments to create query a doc by name
# declare -a ARGS_ARRAY_QUERY_DOC_BY_DOC_ID=(
#     '{"Args":["QueryDocByDocId", "user123", "doc456"]}'
#     '{"Args":["QueryDocByDocId", "user123", "doc891"]}'
#     '{"Args":["QueryDocByDocId", "user124", "doc467"]}'
#     '{"Args":["QueryDocByDocId", "user124", "doc764"]}'
#     # '{"Args":["QueryDocByDocId", "user125", "doc764"]}' #should be an error 
# )

# # Loop through the array and invoke the chaincode function
# for ARGS_DOC_ID in "${ARGS_ARRAY_QUERY_DOC_BY_DOC_ID[@]}"; do
#     echo "===================== Querying a specific document by document id ===================== "
#     chaincodeFunction "" "$ARGS_DOC_ID"
#     echo "===================== Document successfully queried ===================== "
#     echo
#     sleep 5
# done

########################################################################

# invoke chaincode
# peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls ${CORE_PEER_TLS_ENABLED} --cafile ${ORDERER_CA} --channelID testchannel --name OssV1 --peerAddresses localhost:7051 --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE_ORG1} --peerAddresses localhost:9051 --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE_ORG2} ${IS_INIT} -c "$ARGS"