// test/TestExchangeSimple.js
// SPDX-License-Identifier: MIT

const { BN} = require('@openzeppelin/test-helpers');
const { toBN } = web3.utils;

const ExchangeSimple = artifacts.require("ExchangeSimple");
const MyERC20 = artifacts.require("MyERC20");

const tokenValue = new BN(1000);
//const liquidity = new BN(10)
const ethValue = web3.utils.toWei('2','ether');

contract("ExchangeSimple Test", function(accounts) {

    beforeEach(async function() {
        // initialize token and exchange
        token = await MyERC20.new();
        exchange = await ExchangeSimple.new();

        // get initial account balances
        oldAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));
        oldAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));

        // call exchange.setup and get transaction
        receiptSetup = await exchange.setup(
            token.address, 
            tokenValue, 
            {from: accounts[0], value: ethValue} 
            );
        tx = await web3.eth.getTransaction(receiptSetup.tx)

        // compute cost and get new balances
        ethCost = toBN(tx.gasPrice).mul(toBN(receiptSetup.receipt.gasUsed)).add(toBN(ethValue));
        newAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));
        newAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));
    });

    it('test account balances after setup', async function () {
        assert.equal(
            newAccountTokenBalance.toString(),
            oldAccountTokenBalance.sub(tokenValue).toString(), 
            "Wrong account token balance"
            );
        assert.equal(
            newAccountEthBalance.toString(),
            oldAccountEthBalance.sub(ethCost).toString(), 
            "Wrong account eth balance"
            );  
    });

    it('test token reserves', async function () {
        assert.equal(
            (await exchange.getTokenReserve()).toString(),
            tokenValue.toString(),
            "Wrong amount of tokenReserve"
            );
    });


    it('test eth reserves', async function () {
        assert.equal(
            (await exchange.getEthReserve()).toString(),
            ethValue.toString(),
            "Wrong amount of ethReserve"
            );
    });

    
    it('test liquidity', async function () {

        // get initial account balances
        oldAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));
        oldAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));

        const ethReserve = toBN(await exchange.getEthReserve());
        const tokenReserve = toBN(await exchange.getTokenReserve());
        const totalLiquidity = toBN(await exchange.getLiquidity());

        const deltaEth = toBN(ethValue);
        const deltaToken = deltaEth.mul(tokenReserve).div(ethReserve);
        const deltaLiquidity = deltaEth.mul(totalLiquidity).div(ethReserve);

        receiptAddLiquidity = await exchange.addLiquidity({value: ethValue})
        tx = await web3.eth.getTransaction(receiptAddLiquidity.tx)

        const newTokenReserve = tokenReserve.add(deltaToken);
        const newEthReserve = ethReserve.add(deltaEth);
        const newLiquidity = totalLiquidity.add(deltaLiquidity)

        // compute cost and get new balances
        ethCost = toBN(tx.gasPrice).mul(toBN(receiptAddLiquidity.receipt.gasUsed)).add(toBN(ethValue));
        newAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));
        newAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));

        assert.equal(
            newAccountTokenBalance.toString(),
            oldAccountTokenBalance.sub(toBN(deltaToken)).toString(), 
            "Wrong account token balance"
            );

        assert.equal(
            newAccountEthBalance.toString(),
            oldAccountEthBalance.sub(ethCost).toString(), 
            "Wrong account eth balance"
            );  

        assert.equal(
            (await exchange.getTokenReserve()).toString(),
            newTokenReserve.toString() ,
            "Wrong amount of tokenReserve"
            );

        assert.equal(
            (await exchange.getEthReserve()).toString(),
            newEthReserve.toString() ,
            "Wrong amount of ethReserve"
            );

        assert.equal(
            (await exchange.getLiquidity()).toString(),
            newLiquidity.toString() ,
            "Wrong amount of totalLiquidity"
            );

        
        await exchange.removeLiquidity(newLiquidity);

        assert.equal(
            (await exchange.getLiquidity()).toString(), 
            0, 
            "Wrong amount of totalLiquidity. Should be zero"
            );

        // TODO: test account balances after liquidity removal
    });


    it('test eth to token input swap', async function () {

        // get initial account balances
        oldAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));
        oldAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));

        // get current reserves
        const tokenReserve_old = toBN(await exchange.getTokenReserve());

        receiptEthToTokenInSwap = await exchange.ethToTokenInSwap({value: ethValue})
        tx = await web3.eth.getTransaction(receiptEthToTokenInSwap.tx)

        // compute cost and get new balances
        ethCost = toBN(tx.gasPrice).mul(toBN(receiptEthToTokenInSwap.receipt.gasUsed)).add(toBN(ethValue));
        newAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));
        newAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));

        // get new reserves
        const ethReserve = toBN(await exchange.getEthReserve());
        const tokenReserve_new = toBN(await exchange.getTokenReserve());
        const tokensOut = toBN(await exchange.getInputPrice(ethValue, ethReserve, tokenReserve_old));

        assert.equal(
            newAccountTokenBalance.toString(),
            oldAccountTokenBalance.add(tokensOut).toString(), 
            "Wrong account token balance"
            );

        assert.equal(
            newAccountEthBalance.toString(),
            oldAccountEthBalance.sub(ethCost).toString(), 
            "Wrong account eth balance"
            );  

        assert.equal(
            ethReserve.toString(), 
            (2*ethValue).toString(), 
            "Wrong amount of ethReserve"
            );

        assert.equal(tokenReserve_new.toString(), 
            tokenReserve_old.sub(tokensOut).toString(), 
            "Wrong amount of tokenReserve"
            );
    });   

    it('test token to eth input swap', async function () {

        // get initial account balances
        oldAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));
        oldAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));

        const ethReserve_old = toBN(await exchange.getEthReserve());

        receiptTokenToEthInSwap = await exchange.tokenToEthInSwap(tokenValue);
        tx = await web3.eth.getTransaction(receiptTokenToEthInSwap.tx)

        // compute cost and get new balances
        ethCost = toBN(tx.gasPrice).mul(toBN(receiptTokenToEthInSwap.receipt.gasUsed));
        newAccountEthBalance = toBN(await web3.eth.getBalance(accounts[0]));
        newAccountTokenBalance = toBN(await token.balanceOf(accounts[0]));

        const tokenReserve = toBN(await exchange.getTokenReserve());
        const ethReserve_new = toBN(await exchange.getEthReserve());
        const ethOut = toBN(await exchange.getInputPrice(tokenValue, tokenReserve, ethReserve_old));

        assert.equal(
            newAccountTokenBalance.toString(),
            oldAccountTokenBalance.sub(tokenValue).toString(), 
            "Wrong account token balance"
            );

        assert.equal(
            newAccountEthBalance.toString(),
            oldAccountEthBalance.add(ethOut).sub(ethCost).toString(), 
            "Wrong account eth balance"
            ); 

        assert.equal(
            tokenReserve,
            (2*tokenValue).toString(),
            "Wrong amount of tokenReserve"
            );

        assert.equal(
            parseInt(ethReserve_new), 
            (parseInt(ethReserve_old-ethOut)).toString(), 
            "Wrong amount of ethReserve"
            );
    });

    // TODO: test ethToTokenOut and tokenToEthOut

});