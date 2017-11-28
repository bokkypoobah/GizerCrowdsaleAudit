#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`

CROWDSALESOL=`grep ^CROWDSALESOL= settings.txt | sed "s/^.*=//"`
CROWDSALEJS=`grep ^CROWDSALEJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

DATE_PRESALE_START=`echo "$CURRENTTIME+75" | bc`
DATE_PRESALE_START_S=`date -r $DATE_PRESALE_START -u`
DATE_PRESALE_END=`echo "$CURRENTTIME+90" | bc`
DATE_PRESALE_END_S=`date -r $DATE_PRESALE_END -u`

printf "MODE               = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALESOL       = '$CROWDSALESOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALEJS        = '$CROWDSALEJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT        = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS       = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "DATE_PRESALE_START = '$DATE_PRESALE_START' '$DATE_PRESALE_START_S'\n" | tee -a $TEST1OUTPUT
printf "DATE_PRESALE_END   = '$DATE_PRESALE_END' '$DATE_PRESALE_END_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/$CROWDSALESOL .`

# --- Modify parameters ---
`perl -pi -e "s/DATE_PRESALE_START \= 1512050400;.*$/DATE_PRESALE_START \= $DATE_PRESALE_START; \/\/ $DATE_PRESALE_START_S/" $CROWDSALESOL`
`perl -pi -e "s/DATE_PRESALE_END   \= 1513260000;.*$/DATE_PRESALE_END   \= $DATE_PRESALE_END; \/\/ $DATE_PRESALE_END_S/" $CROWDSALESOL`

DIFFS1=`diff $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL`
echo "--- Differences $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.4.18 --version | tee -a $TEST1OUTPUT

echo "var tokenOutput=`solc_0.4.18 --optimize --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$CROWDSALEJS");
loadScript("functions.js");

var libAbi = JSON.parse(tokenOutput.contracts["$CROWDSALESOL:SafeMath"].abi);
var libBin = "0x" + tokenOutput.contracts["$CROWDSALESOL:SafeMath"].bin;
var tokenAbi = JSON.parse(tokenOutput.contracts["$CROWDSALESOL:GizerTokenPresale"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$CROWDSALESOL:GizerTokenPresale"].bin;

// console.log("DATA: libAbi=" + JSON.stringify(libAbi));
// console.log("DATA: libBin=" + JSON.stringify(libBin));
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));


unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployLibraryMessage = "Deploy SafeMath Library";
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployLibraryMessage);
var libContract = web3.eth.contract(libAbi);
var libTx = null;
var libAddress = null;
var lib = libContract.new({from: contractOwnerAccount, data: libBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        libTx = contract.transactionHash;
      } else {
        libAddress = contract.address;
        addAccount(libAddress, "Lib SafeMath");
        console.log("DATA: libAddress=" + libAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
printTxData("libAddress=" + libAddress, libTx);
failIfTxStatusError(libTx, deployLibraryMessage);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Crowdsale/Token Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + tokenMessage);
// console.log("RESULT: old='" + tokenBin + "'");
var newTokenBin = tokenBin.replace(/__GizerTokenPresale\.sol\:SafeMath________/g, libAddress.substring(2, 42));
// console.log("RESULT: new='" + newTokenBin + "'");
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;
var token = tokenContract.new({from: contractOwnerAccount, data: newTokenBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
printTxData("tokenAddress=" + tokenAddress, tokenTx);
failIfTxStatusError(tokenTx, tokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var setupMessage = "Setup";
// -----------------------------------------------------------------------------
console.log("RESULT: " + setupMessage);
var setup1Tx = token.setWallet(wallet, {from: contractOwnerAccount, gas: 400000, gasPrice: defaultGasPrice});
var setup2Tx = token.setRedemptionWallet(redemptionWallet, {from: contractOwnerAccount, gas: 400000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
printTxData("setup1Tx", setup1Tx);
printTxData("setup2Tx", setup2Tx);
failIfTxStatusError(setup1Tx, setupMessage + " - setWallet(...)");
failIfTxStatusError(setup2Tx, setupMessage + " - setRedemptionWallet(...)");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendPrivateSaleContrib1Message = "Send Private Sale Contribution";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendPrivateSaleContrib1Message);
var sendPrivateSaleContrib1_1Tx = token.privateSaleContribution(account3, web3.toWei("100", "ether"), {from: contractOwnerAccount, gas: 400000, gasPrice: defaultGasPrice});
var sendPrivateSaleContrib1_2Tx = token.privateSaleContribution(account4, web3.toWei("200", "ether"), {from: contractOwnerAccount, gas: 400000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
printTxData("sendPrivateSaleContrib1_1Tx", sendPrivateSaleContrib1_1Tx);
printTxData("sendPrivateSaleContrib1_2Tx", sendPrivateSaleContrib1_2Tx);
failIfTxStatusError(sendPrivateSaleContrib1_1Tx, sendPrivateSaleContrib1Message + " - ac3 100 ETH");
failIfTxStatusError(sendPrivateSaleContrib1_2Tx, sendPrivateSaleContrib1Message + " - ac4 200 ETH");
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("DATE_PRESALE_START", token.DATE_PRESALE_START(), 0);


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution In Presale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1_1Tx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
var sendContribution1_2Tx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
var sendContribution1_3Tx = eth.sendTransaction({from: account5, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
var sendContribution1_4Tx = eth.sendTransaction({from: account6, to: tokenAddress, gas: 400000, value: web3.toWei("100.01", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
printTxData("sendContribution1_1Tx", sendContribution1_1Tx);
printTxData("sendContribution1_2Tx", sendContribution1_2Tx);
printTxData("sendContribution1_3Tx", sendContribution1_3Tx);
printTxData("sendContribution1_4Tx", sendContribution1_4Tx);
failIfTxStatusError(sendContribution1_1Tx, sendContribution1Message + " - ac3 100 ETH");
failIfTxStatusError(sendContribution1_2Tx, sendContribution1Message + " - ac4 100 ETH");
failIfTxStatusError(sendContribution1_3Tx, sendContribution1Message + " - ac5 100 ETH");
passIfTxStatusError(sendContribution1_4Tx, sendContribution1Message + " - ac5 100.01 ETH - Expecting failure as over the contrib limit");
printTokenContractDetails();
console.log("RESULT: ");

exit;

// -----------------------------------------------------------------------------
// Wait for dateIcoStart start
// -----------------------------------------------------------------------------
waitUntil("dateIcoStart", token.dateIcoStart(), 0);


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution In Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2_1Tx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("1000", "ether")});
var sendContribution2_2Tx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("1000", "ether")});
var sendContribution2_3Tx = eth.sendTransaction({from: account5, to: tokenAddress, gas: 400000, value: web3.toWei("1000", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution2_1Tx", sendContribution2_1Tx);
printTxData("sendContribution2_2Tx", sendContribution2_2Tx);
printTxData("sendContribution2_3Tx", sendContribution2_3Tx);
printBalances();
failIfTxStatusError(sendContribution2_1Tx, sendContribution2Message + " - ac3 1000 ETH");
failIfTxStatusError(sendContribution2_2Tx, sendContribution2Message + " - ac4 1000 ETH");
passIfTxStatusError(sendContribution2_3Tx, sendContribution2Message + " - ac5 1000 ETH - expecting failure");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for dateIcoEnd start
// -----------------------------------------------------------------------------
waitUntil("dateIcoEnd", token.dateIcoEnd(), 0);


// -----------------------------------------------------------------------------
var closeCrowdsaleMessage = "Close Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + closeCrowdsaleMessage);
var closeCrowdsale_1Tx = token.declareIcoFinished({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
var closeCrowdsale_2Tx = token.makeTradeable({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("closeCrowdsale_1Tx", closeCrowdsale_1Tx);
printTxData("closeCrowdsale_2Tx", closeCrowdsale_2Tx);
printBalances();
failIfTxStatusError(closeCrowdsale_1Tx, closeCrowdsaleMessage + " - close crowdsale");
failIfTxStatusError(closeCrowdsale_2Tx, closeCrowdsaleMessage + " - tradeable");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move Tokens After Transfers Allowed";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account5, "1000000", {from: account3, gas: 100000});
var moveToken2Tx = token.approve(account6,  "30000000", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account4, account7, "30000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printBalances();
failIfTxStatusError(moveToken1Tx, moveTokenMessage + " - transfer 1 token ac3 -> ac5. CHECK for movement");
failIfTxStatusError(moveToken2Tx, moveTokenMessage + " - approve 30 tokens ac4 -> ac6");
failIfTxStatusError(moveToken3Tx, moveTokenMessage + " - transferFrom 30 tokens ac4 -> ac7 by ac6. CHECK for movement");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
