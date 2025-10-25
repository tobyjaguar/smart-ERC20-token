// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {SmartCoin} from "../src/Smart.sol";

contract SmartTest is Test {
    SmartCoin public token;
    address public owner;
    address public admin1;
    address public admin2;
    address public user1;
    address public user2;
    
    uint256 constant INITIAL_SUPPLY = 1000;
    
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function setUp() public {
        owner = address(this);
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new SmartCoin(INITIAL_SUPPLY);
    }
    
    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Deployment() public view {
        assertEq(token.name(), "Smart Coin");
        assertEq(token.symbol(), "SMART");
        assertEq(token.decimals(), 0);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.paused(), false);
    }
    
    function test_DeployerIsAdmin() public view {
        assertTrue(token.isAdmin(owner));
    }
    
    function test_DeploymentWithZeroSupply() public {
        SmartCoin newToken = new SmartCoin(0);
        assertEq(newToken.totalSupply(), 0);
        assertEq(newToken.balanceOf(address(this)), 0);
        assertTrue(newToken.isAdmin(address(this)));
    }
    
    /*//////////////////////////////////////////////////////////////
                        ADMIN MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_AddAdmin() public {
        vm.expectEmit(true, false, false, false);
        emit AdminAdded(admin1);
        
        token.addAdmin(admin1);
        assertTrue(token.isAdmin(admin1));
    }
    
    function test_RevertWhen_NonAdminAddsAdmin() public {
        vm.prank(user1);
        vm.expectRevert(SmartCoin.NotAdmin.selector);
        token.addAdmin(admin1);
    }
    
    function test_RevertWhen_AddingExistingAdmin() public {
        token.addAdmin(admin1);
        
        vm.expectRevert(SmartCoin.AlreadyAdmin.selector);
        token.addAdmin(admin1);
    }
    
    function test_RevertWhen_AddingZeroAddress() public {
        vm.expectRevert();
        token.addAdmin(address(0));
    }
    
    function test_RemoveAdmin() public {
        token.addAdmin(admin1);
        assertTrue(token.isAdmin(admin1));
        
        vm.expectEmit(true, false, false, false);
        emit AdminRemoved(admin1);
        
        token.removeAdmin(admin1);
        assertFalse(token.isAdmin(admin1));
    }
    
    function test_RevertWhen_NonAdminRemovesAdmin() public {
        token.addAdmin(admin1);
        
        vm.prank(user1);
        vm.expectRevert(SmartCoin.NotAdmin.selector);
        token.removeAdmin(admin1);
    }
    
    function test_RevertWhen_RemovingNonAdmin() public {
        vm.expectRevert(SmartCoin.NotAnAdmin.selector);
        token.removeAdmin(user1);
    }
    
    function test_MultipleAdmins() public {
        token.addAdmin(admin1);
        token.addAdmin(admin2);
        
        assertTrue(token.isAdmin(owner));
        assertTrue(token.isAdmin(admin1));
        assertTrue(token.isAdmin(admin2));
        assertFalse(token.isAdmin(user1));
    }
    
    function test_AdminCanAddOtherAdmins() public {
        token.addAdmin(admin1);
        
        vm.prank(admin1);
        token.addAdmin(admin2);
        
        assertTrue(token.isAdmin(admin2));
    }
    
    /*//////////////////////////////////////////////////////////////
                        MINTING TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_AdminCanMint() public {
        uint256 mintAmount = 500;
        uint256 initialSupply = token.totalSupply();
        
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), initialSupply + mintAmount);
    }
    
    function test_RevertWhen_NonAdminMints() public {
        vm.prank(user1);
        vm.expectRevert(SmartCoin.NotAdmin.selector);
        token.mint(user1, 100);
    }
    
    function test_MintToMultipleAddresses() public {
        token.mint(user1, 100);
        token.mint(user2, 200);
        
        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(user2), 200);
    }
    
    function test_IncrementalMinting() public {
        uint256 initialSupply = token.totalSupply();
        
        token.mint(user1, 100);
        assertEq(token.totalSupply(), initialSupply + 100);
        
        token.mint(user1, 50);
        assertEq(token.totalSupply(), initialSupply + 150);
        assertEq(token.balanceOf(user1), 150);
    }
    
    function testFuzz_Mint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount < type(uint256).max - token.totalSupply());
        
        uint256 initialSupply = token.totalSupply();
        token.mint(to, amount);
        
        assertEq(token.balanceOf(to), amount);
        assertEq(token.totalSupply(), initialSupply + amount);
    }
    
    /*//////////////////////////////////////////////////////////////
                        BURNING TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_TokenHolderCanBurn() public {
        uint256 burnAmount = 100;
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialSupply = token.totalSupply();
        
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }
    
    function test_BurnReducesSupply() public {
        token.mint(user1, 500);
        uint256 totalSupplyBefore = token.totalSupply();
        
        vm.prank(user1);
        token.burn(200);
        
        assertEq(token.totalSupply(), totalSupplyBefore - 200);
        assertEq(token.balanceOf(user1), 300);
    }
    
    function test_RevertWhen_BurningMoreThanBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        token.burn(100);
    }
    
    function testFuzz_Burn(uint256 mintAmount, uint256 burnAmount) public {
        vm.assume(mintAmount > 0 && mintAmount < type(uint256).max / 2);
        vm.assume(burnAmount > 0 && burnAmount <= mintAmount);
        
        token.mint(user1, mintAmount);
        uint256 supplyAfterMint = token.totalSupply();
        
        vm.prank(user1);
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
        assertEq(token.totalSupply(), supplyAfterMint - burnAmount);
    }
    
    /*//////////////////////////////////////////////////////////////
                        PAUSE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_AdminCanPause() public {
        vm.expectEmit(true, false, false, false);
        emit Paused(owner);
        
        token.pause();
        assertTrue(token.paused());
    }
    
    function test_AdminCanUnpause() public {
        token.pause();
        assertTrue(token.paused());
        
        vm.expectEmit(true, false, false, false);
        emit Unpaused(owner);
        
        token.unpause();
        assertFalse(token.paused());
    }
    
    function test_RevertWhen_NonAdminPauses() public {
        vm.prank(user1);
        vm.expectRevert(SmartCoin.NotAdmin.selector);
        token.pause();
    }
    
    function test_RevertWhen_NonAdminUnpauses() public {
        token.pause();
        
        vm.prank(user1);
        vm.expectRevert(SmartCoin.NotAdmin.selector);
        token.unpause();
    }
    
    function test_RevertWhen_TransferWhilePaused() public {
        token.mint(user1, 100);
        token.pause();
        
        vm.prank(user1);
        vm.expectRevert(SmartCoin.TransfersPaused.selector);
        token.transfer(user2, 50);
    }
    
    function test_RevertWhen_TransferFromWhilePaused() public {
        token.mint(user1, 100);
        
        vm.prank(user1);
        token.approve(user2, 50);
        
        token.pause();
        
        vm.prank(user2);
        vm.expectRevert(SmartCoin.TransfersPaused.selector);
        token.transferFrom(user1, user2, 50);
    }
    
    function test_TransferWorksAfterUnpause() public {
        token.mint(user1, 100);
        token.pause();
        token.unpause();
        
        vm.prank(user1);
        token.transfer(user2, 50);
        
        assertEq(token.balanceOf(user1), 50);
        assertEq(token.balanceOf(user2), 50);
    }
    
    function test_MintingWorksWhilePaused() public {
        token.pause();
        token.mint(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }
    
    function test_BurningWorksWhilePaused() public {
        token.mint(user1, 100);
        token.pause();
        
        vm.prank(user1);
        token.burn(50);
        assertEq(token.balanceOf(user1), 50);
    }
    
    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Transfer() public {
        token.mint(user1, 100);
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, 50);
        
        token.transfer(user2, 50);
        
        assertEq(token.balanceOf(user1), 50);
        assertEq(token.balanceOf(user2), 50);
    }
    
    function test_TransferFrom() public {
        token.mint(user1, 100);
        
        vm.prank(user1);
        token.approve(user2, 50);
        
        vm.prank(user2);
        token.transferFrom(user1, user2, 50);
        
        assertEq(token.balanceOf(user1), 50);
        assertEq(token.balanceOf(user2), 50);
    }
    
    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint256).max / 2);
        
        token.mint(user1, amount);
        
        vm.prank(user1);
        token.transfer(user2, amount);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), amount);
    }
    
    /*//////////////////////////////////////////////////////////////
                        DECIMALS TEST
    //////////////////////////////////////////////////////////////*/
    
    function test_ZeroDecimals() public view {
        assertEq(token.decimals(), 0);
    }
    
    function test_WholeTokensOnly() public {
        // With 0 decimals, 1 token = 1 (not 1e18)
        token.mint(user1, 1);
        assertEq(token.balanceOf(user1), 1);
        
        token.mint(user2, 100);
        assertEq(token.balanceOf(user2), 100);
    }
    
    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_CompleteWorkflow() public {
        // 1. Add admins
        token.addAdmin(admin1);
        token.addAdmin(admin2);
        
        // 2. Admin1 mints tokens to user1
        vm.prank(admin1);
        token.mint(user1, 100);
        assertEq(token.balanceOf(user1), 100);
        
        // 3. User1 transfers to user2
        vm.prank(user1);
        token.transfer(user2, 30);
        assertEq(token.balanceOf(user2), 30);
        
        // 4. Admin2 pauses the contract
        vm.prank(admin2);
        token.pause();
        
        // 5. Transfers should fail
        vm.prank(user1);
        vm.expectRevert(SmartCoin.TransfersPaused.selector);
        token.transfer(user2, 10);
        
        // 6. Admin1 unpauses
        vm.prank(admin1);
        token.unpause();
        
        // 7. Transfers work again
        vm.prank(user1);
        token.transfer(user2, 20);
        assertEq(token.balanceOf(user1), 50);
        assertEq(token.balanceOf(user2), 50);
        
        // 8. User2 burns some tokens
        vm.prank(user2);
        token.burn(25);
        assertEq(token.balanceOf(user2), 25);
    }
    
    function test_DailyRewardScenario() public {
        // Simulate the My Daily Trivia use case
        address hotWallet = makeAddr("hotWallet");
        address player1 = makeAddr("player1");
        address player2 = makeAddr("player2");
        address player3 = makeAddr("player3");
        
        // Setup: Mint tokens to hot wallet
        token.mint(hotWallet, 10000);
        
        // Day 1: Three players answer correctly
        vm.startPrank(hotWallet);
        token.transfer(player1, 1);
        token.transfer(player2, 1);
        token.transfer(player3, 1);
        vm.stopPrank();
        
        assertEq(token.balanceOf(player1), 1);
        assertEq(token.balanceOf(player2), 1);
        assertEq(token.balanceOf(player3), 1);
        assertEq(token.balanceOf(hotWallet), 9997);
        
        // Day 2: Only player1 and player3 answer correctly
        vm.startPrank(hotWallet);
        token.transfer(player1, 1);
        token.transfer(player3, 1);
        vm.stopPrank();
        
        assertEq(token.balanceOf(player1), 2);
        assertEq(token.balanceOf(player2), 1);
        assertEq(token.balanceOf(player3), 2);
        
        // If hot wallet runs low, admin can mint more
        if (token.balanceOf(hotWallet) < 100) {
            token.mint(hotWallet, 5000);
        }
        
        assertGe(token.balanceOf(hotWallet), 5000);
    }
}

