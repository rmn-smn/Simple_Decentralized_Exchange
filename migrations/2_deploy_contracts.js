var MyERC20 = artifacts.require("MyERC20");
var ExchangeSimple = artifacts.require("ExchangeSimple");
var ExchangeFactory = artifacts.require("ExchangeFactory");

module.exports = function(deployer){
    deployer.deploy(MyERC20);
    deployer.deploy(ExchangeSimple);
    deployer.deploy(ExchangeFactory);
};