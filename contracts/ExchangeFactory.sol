// contracts/TokenPairFactory.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Exchange.sol";


contract ExchangeFactory is ExchangeFactoryInterface{

    Exchange[] public exchangeArray;
    mapping(address => address) public tokenToExchange;
    mapping(address => address) public exchangeToToken;

    function createExchange(address _token) public returns (bool){
        require(_token != address(0));
        Exchange _newExchange = new Exchange();
        _newExchange.setup(_token);
        tokenToExchange[_token] = address(_newExchange);
        exchangeToToken[address(_newExchange)] = _token;

        exchangeArray.push(_newExchange);
        return true;
    }
}
