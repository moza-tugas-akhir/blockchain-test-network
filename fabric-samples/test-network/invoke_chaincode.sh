#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0

# default to using Org1

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ORDERER_CA=${DIR}/test-network/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
PEER0_ORG1_CA=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
PEER0_ORG2_CA=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
PEER0_ORG3_CA=${DIR}/test-network/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem

CORE_PEER_TLS_ENABLED=true

# environment variables for ORG1
CORE_PEER_LOCALMSPID_ORG1=Org1MSP
CORE_PEER_MSPCONFIGPATH_ORG1=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS_ORG1=localhost:7051
CORE_PEER_TLS_ROOTCERT_FILE_ORG1=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

# environment variables for ORG2
CORE_PEER_LOCALMSPID_ORG2=Org2MSP
CORE_PEER_MSPCONFIGPATH_ORG2=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS_ORG2=localhost:9051
CORE_PEER_TLS_ROOTCERT_FILE_ORG2=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem

# Usage message
function usage {
    echo "Usage: $0 [-i|--isInit] '<chaincode_invoke_arguments>'"
    echo "Example for initialization: $0 -i '{\"Args\":[]}'"
    echo "Example for invocation: $0 '{\"Args\":[\"QueryPropertyById\", \"1\"]}'"
    exit 1
}

# Check if arguments are provided
if [ $# -eq 0 ]; then
    usage
fi

# Initialize variables
IS_INIT=""

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--isInit) IS_INIT="--isInit"; shift ;;
        -c) ARGS="$2"; shift 2 ;;
        *) ARGS="$1"; shift ;;
    esac
done

# Check if ARGS is set
if [ -z "$ARGS" ]; then
    usage
fi

# invoke chaincode
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls ${CORE_PEER_TLS_ENABLED} --cafile ${ORDERER_CA} --channelID testchannel --name OssV1 --peerAddresses localhost:7051 --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE_ORG1} --peerAddresses localhost:9051 --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE_ORG2} ${IS_INIT} -c "$ARGS"
