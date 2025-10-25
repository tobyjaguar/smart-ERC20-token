// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {SmartCoin} from "../src/Smart.sol";

/**
 * @title Deploy
 * @dev Deployment script for SmartCoin token contract
 * 
 * Usage:
 * 
 * Deploy to Base Sepolia (testnet):
 * forge script script/Deploy.s.sol:Deploy --rpc-url base_sepolia --broadcast --verify
 * 
 * Deploy to Base Mainnet:
 * forge script script/Deploy.s.sol:Deploy --rpc-url base --broadcast --verify
 * 
 * Dry run (simulation):
 * forge script script/Deploy.s.sol:Deploy --rpc-url base_sepolia
 */
contract Deploy is Script {
    // Initial supply: 1000 SMART tokens
    uint256 constant INITIAL_SUPPLY = 1000;
    
    function run() external returns (SmartCoin) {
        // Get the deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the SmartCoin token contract
        SmartCoin token = new SmartCoin(INITIAL_SUPPLY);
        
        console.log("SmartCoin token deployed at:", address(token));
        console.log("Deployer address:", vm.addr(deployerPrivateKey));
        console.log("Initial supply:", token.totalSupply());
        console.log("Deployer is admin:", token.isAdmin(vm.addr(deployerPrivateKey)));
        
        vm.stopBroadcast();
        
        return token;
    }
}

