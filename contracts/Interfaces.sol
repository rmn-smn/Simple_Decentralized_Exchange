// contracts/Interfaces.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
Interface for the ERC20 Standard proposed in EIP-20:
https://eips.ethereum.org/EIPS/eip-20
Reimplementation here purely for educational purposes.
Several implementational details seem to have changed since Solidity 0.4.17.
Interfaces are declared as "interface" and not "contract" and all
function visibility has to be "external" instead of "public".
*/
interface ERC20Interface {
    function name() external view returns (string memory);
 	function symbol() external view returns (string memory);
 	function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _tokenOwner) external view returns (uint256);
    function allowance(
        address _tokenOwner, address _spender) external view returns (uint256);
    function transfer(
        address _recipient, uint256 _amount) external returns (bool);
    function approve(
        address _spender, uint256 _amount) external returns (bool);
    function transferFrom(
        address from, address to, uint tokens) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(
        address indexed _tokenOwner, address indexed _spender, uint256 _tokens);
    
}

interface ExchangeFactoryInterface{
    function createExchange(address _token) external returns (bool);
}