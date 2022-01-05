// contracts/ExchangeSimple.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MyERC20.sol";

// A naive implementation of a token exchange 
// using a constant product market-maker formula
// references:  https://github.com/runtimeverification/verified-smart-contracts/blob/uniswap/uniswap/x-y-k.pdf
//              https://hackmd.io/@HaydenAdams/HJ9jLsfTz

contract ExchangeSimple is MyERC20{

    uint256 public ethReserve;
    uint256 public tokenReserve;
    uint256 public invariant;
    uint256 public totalLiquidity; 

    ERC20Interface public token;
    ExchangeFactoryInterface public factory;
    mapping(address => uint256) balances;
    mapping(address => uint256) liquidity;

    event TokenPurchase(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
    event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);

    // this method should be called from the ExchangeFactory to set up 
    // a new exchange pair and provide some initial reserve
    // (why not let the constructor take care of this?)
    function setup(address _token, uint256 _tokenAmount) external payable returns(bool){

        // sanity checks
        require(_token != address(0) && msg.sender != address(0));
        require(msg.value >= 0 && _tokenAmount >= 0);

        // initialize token and factory
        token = ERC20Interface(_token);
        factory = ExchangeFactoryInterface(msg.sender);

        // add reserve
        tokenReserve += _tokenAmount;
        ethReserve += msg.value;

        // give liquidity to caller (this could be a token)
        liquidity[msg.sender] = 1*10**6;
        totalLiquidity = 1*10**6;

        // send tokens from caller to exchange contract
        require(token.transferFrom(msg.sender, address(this), _tokenAmount));

        return true;
    }

    function addLiquidity () external payable returns (bool){

        // compute additions to reserves
        require(msg.value >= 0);
        uint256 deltaEth = msg.value;
        uint256 deltaToken = deltaEth * tokenReserve / ethReserve;
        uint256 deltaLiquidity = deltaEth * totalLiquidity / ethReserve;

        // add to reserves
        liquidity[msg.sender] += deltaLiquidity;
        ethReserve += deltaEth;
        tokenReserve += deltaToken;
        totalLiquidity += deltaLiquidity; 

        // recompute reserve product
        invariant = ethReserve * tokenReserve;

        // send tokens from caller to exchange contract
        require(token.transferFrom(msg.sender, address(this), deltaToken));
        return true;

    }

    function removeLiquidity (uint256 _liquidityBurned) external returns (bool){
        
        // compute removal from reserves
        uint256 deltaLiquidity = _liquidityBurned;
        uint256 deltaEth = _liquidityBurned * ethReserve / totalLiquidity;
        uint256 deltaToken = _liquidityBurned * tokenReserve / totalLiquidity;
        
        require(liquidity[msg.sender] >= deltaLiquidity && totalLiquidity >= deltaLiquidity);
        require(ethReserve >= deltaEth);
        require(tokenReserve >= deltaToken);

        // remove from reserves
        liquidity[msg.sender] -= deltaLiquidity;
        ethReserve -= deltaEth;
        tokenReserve -= deltaToken;
        totalLiquidity -= deltaLiquidity; 

        // recompute reserve product
        invariant = ethReserve * tokenReserve;

        // send tokens and eth to caller
        require(token.transfer(msg.sender, deltaToken));
        payable(msg.sender).transfer(deltaEth);

        return true;

    }

    // convert between price of ETH and Token
    function getInputPrice(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) public pure returns (uint256){
        
        require(_reserveIn > 0 && _amountIn > 0);
        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
            
    }

    function getOutputPrice(uint256 _amountOut, uint256 _reserveIn, uint256 _reserveOut) public pure returns (uint256){
        
        require(_reserveIn > 0 && _amountOut > 0);
        uint256 numerator = (_reserveIn * _amountOut) * 1000;
        uint256 denominator = (_reserveOut - _amountOut) * 997;
        return 1 + (numerator / denominator);   
    }

    /*----------------------------------------------------------*/
    /* Exchange methods based on exact input price (sell order) */
    /*----------------------------------------------------------*/


    function ethToTokenInSwap() public payable returns(uint256){
        require(msg.value >= 0);
        return ethToTokenIn(msg.value, msg.sender, msg.sender);
        // since ethToTokenIn is called from a payable function 
        // the eth transfer from the user's wallet is done automatically
    }

    // user sells eth and transfers tokens to recipient
    function ethToTokenInTransfer(uint256 _ethIn, address _recipient) public payable returns(uint256){
        require(_ethIn >= 0);
        require(_recipient != msg.sender && _recipient != address(0));
        return ethToTokenIn(_ethIn, msg.sender, _recipient);
    }

    // exchange specified amount of eth to tokens
    function ethToTokenIn(uint256 _ethIn, address _buyer, address _recipient) private returns(uint256){
        ethReserve += _ethIn;
        uint256 tokensOut = getInputPrice(_ethIn, ethReserve, tokenReserve);
        tokenReserve -= tokensOut;
        // recipient receives tokens
        require(token.transfer(_recipient, tokensOut));
        emit TokenPurchase(_buyer, _ethIn, tokensOut);
        return tokensOut;
    }

    // user swaps token for eth (sell tokens)
    function tokenToEthInSwap(uint256 _tokensIn) public payable returns(uint256){
        require(_tokensIn >= 0);
        return tokenToEthIn(_tokensIn, msg.sender, msg.sender);
    }

    // user sells token and transfers eth to recipient
    function tokenToEthInTransfer(uint256 _tokensIn, address _recipient) public payable returns(uint256){
        require(_tokensIn >= 0);
        require(_recipient != msg.sender && _recipient != address(0));
        return tokenToEthIn(_tokensIn, msg.sender, _recipient);
    }

    function tokenToEthIn(uint256 _tokensIn, address _buyer, address _recipient) private returns(uint256){
        tokenReserve += _tokensIn;
        uint256 ethOut = getInputPrice(_tokensIn, tokenReserve, ethReserve);
        ethReserve -= ethOut;
        // buyer pays in token
        require(token.transferFrom(_buyer, address(this), _tokensIn));

        // recipient receives eth
        payable(_recipient).transfer(ethOut);
        emit EthPurchase(_buyer, _tokensIn, ethOut);
        return ethOut;
    }

    /*----------------------------------------------------*/
    /* Exchange methods based on output price (buy order) */
    /*----------------------------------------------------*/

    // user swaps eth for tokens (boy tokens)
    function ethToTokenOutSwap(uint256 _tokensIn) public payable returns(uint256){
        require(_tokensIn >= 0);
        return ethToTokenOut(_tokensIn,msg.sender,msg.sender);
    }

    // users buys specified amount of tokens for eth and sends tokens to recipient
    function ethToTokenOutTransfer(uint256 _tokensIn, address _recipient) public payable returns(uint256){
        require(_tokensIn >= 0);
        require(_recipient != msg.sender && _recipient != address(0));
        return ethToTokenOut(_tokensIn,msg.sender,_recipient);
    }

    function ethToTokenOut(uint256 _tokensIn, address _buyer, address _recipient) private returns(uint256){
        tokenReserve -= _tokensIn;
        uint256 ethOut = getOutputPrice(_tokensIn, ethReserve, tokenReserve);
        ethReserve += ethOut;
        // recipient receives tokens
        require(token.transfer(_recipient, _tokensIn));
        emit TokenPurchase(_buyer, ethOut, _tokensIn);
        return ethOut;
    }

    // user swaps tokens for eth (buy eth)
    function tokenToEthOutSwap(uint256 _ethIn) public payable returns(uint256){
        require(_ethIn >= 0);
        return tokenToEthOut(_ethIn, msg.sender, msg.sender);
    }

    // users buys specified amount of eth for tokens and sends eth to recipient
    function tokenToEthOutTransfer(uint256 _ethIn, address _recipient) public payable returns(uint256){
        require(_ethIn >= 0);
        require(_recipient != msg.sender && _recipient != address(0));
        return tokenToEthOut(_ethIn, msg.sender, _recipient);
    }

    function tokenToEthOut(uint256 _ethIn, address _buyer, address _recipient) private returns(uint256){
        ethReserve -= _ethIn;
        uint256 tokensOut = getOutputPrice(_ethIn, tokenReserve, ethReserve);
        tokenReserve += tokensOut;
        // buyer pays tokens
        require(token.transferFrom(_buyer, address(this), tokensOut));
        // recipient receives eth
        payable(_recipient).transfer(_ethIn);
        emit EthPurchase(_buyer, tokensOut, _ethIn);

        return tokensOut;
    }

    function getTokenReserve() public view returns (uint256){
        return tokenReserve;
    }

    function getEthReserve() public view returns (uint256){
        return ethReserve;
    }

    function getLiquidity() public view returns (uint256){
        return totalLiquidity;
    }
}