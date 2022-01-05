// test/TestExchangeFactory.js
// SPDX-License-Identifier: MIT

const ExchangeFactory = artifacts.require("ExchangeFactory");
const MyERC20 = artifacts.require("MyERC20");

contract("ExchangeFactory Test", function(accounts) {

     beforeEach(async function() {
        // initialize token
        token = await MyERC20.new();
        factory = await ExchangeFactory.new();
        tokenAddress = token.address;

     });

    it('test exchange factory', async function () {
        assert.equal(
            (await factory.createExchange(tokenAddress)).receipt.status,
            true, 
            "Could not set up exchange"
            );
    });
});