#!/usr/bin/bash 

sudo ./network.sh down -ca -s couchdb
sleep 2
sudo ./network.sh up -ca -s couchdb
sleep 1
sudo ./network.sh createChannel -c testchannel
sleep 1
# cp ../../../blockchain-chaincode/test-network/OssV1.tar.gz .
cp ../../../blockchain-chaincode/test-network/OssV1_1.tar.gz .
sleep 1
sudo chmod -R 777 .
sleep 1
# ./chaincode_lifecycle.sh
./CL_OSSV1_1.sh 