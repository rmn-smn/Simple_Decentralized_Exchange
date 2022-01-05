// test/TestMyERC20.js
// SPDX-License-Identifier: MIT

const MyERC20 = artifacts.require("MyERC20");

contract("MyERC20 Test", function(accounts) {

    const name = "MyToken";
    const symbol = "MTN";
    const totalSupply = 10000000000000000000
    const testAmount = 10
    const decimals = 18

    beforeEach(async function() {
        this.token = await MyERC20.new();//name,symbol,initialHolder,initialSupply);
    });

    it('test name', async function () {
        assert.equal(await this.token.name(), name, "Wrong Name");

    });

    it('test symbol', async function () {
        assert.equal(await this.token.symbol(), symbol, "Wrong Symbol");
    });

    it('test decimals', async function () {
        assert.equal(await this.token.decimals(), decimals, "Wrong decimals");
    });

    it('test total supply', async function () {
        assert.equal(await this.token.totalSupply(), totalSupply, "Wrong total supply");
    });

    it('test initial balance owner', async function () {
        const balance = await this.token.balanceOf(accounts[0]);
        assert.equal(balance,totalSupply,"Wrong total supply");
    });

    it('test transfer from owner', async function () {
        await this.token.transferFrom(accounts[0],accounts[1],testAmount);
        balanceAcc0 = await this.token.balanceOf(accounts[0]);
        balanceAcc1 = await this.token.balanceOf(accounts[1]);
        assert.equal(balanceAcc0,totalSupply-testAmount,"Wrong balance of account[0]");
        assert.equal(balanceAcc1,testAmount,"Wrong balance of account[1]");
    }); 
    
    it('test transfer to recipient', async function () {
        await this.token.transfer(accounts[1],testAmount);
        balanceAcc0 = await this.token.balanceOf(accounts[0]);
        balanceAcc1 = await this.token.balanceOf(accounts[1]);
        assert.equal(balanceAcc0,totalSupply-testAmount,"Wrong balance of account[0]");
        assert.equal(balanceAcc1,testAmount,"Wrong balance of account[1]");
    });     

    it('test approve and allowance', async function () {
        await this.token.approve(accounts[1],testAmount);
        allowance = await this.token.allowance(accounts[0],accounts[1])
        assert.equal(allowance,testAmount,"Wrong allowance");
    });   
});