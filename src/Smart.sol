// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Smart
 * @dev ERC20 token with admin controls, pausable transfers, and dynamic supply
 * Token name: Smart
 * Token symbol: SMART
 * Decimals: 0 (non-divisible whole tokens)
 * 
 * Features:
 * - Admin whitelist management
 * - Pausable transfers for emergency situations
 * - Minting capability for admins
 * - Burning capability for admins and token holders
 * - Dynamic supply with incremental minting
 */
contract Smart is ERC20, ERC20Burnable, Ownable {
    // Mapping of admin addresses
    mapping(address => bool) private _admins;
    
    // Pause state for transfers
    bool private _paused;
    
    // Events
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    
    // Errors
    error NotAdmin();
    error AlreadyAdmin();
    error NotAnAdmin();
    error TransfersPaused();
    error CannotRemoveLastAdmin();
    
    /**
     * @dev Modifier to make a function callable only by admins
     */
    modifier onlyAdmin() {
        if (!_admins[msg.sender]) revert NotAdmin();
        _;
    }
    
    /**
     * @dev Modifier to make a function callable only when not paused
     */
    modifier whenNotPaused() {
        if (_paused) revert TransfersPaused();
        _;
    }
    
    /**
     * @dev Constructor that initializes the token with name "Smart" and symbol "SMART"
     * Mints initial supply to the deployer and adds deployer as the first admin
     * @param initialSupply The initial supply of tokens to mint to the deployer
     */
    constructor(uint256 initialSupply) ERC20("Smart", "SMART") Ownable(msg.sender) {
        // Add deployer as first admin
        _admins[msg.sender] = true;
        emit AdminAdded(msg.sender);
        
        // Mint initial supply to deployer
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
        }
        
        // Start unpaused
        _paused = false;
    }
    
    /**
     * @dev Returns 0 decimals (whole tokens only)
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }
    
    /**
     * @dev Adds a new admin. Only callable by existing admins
     * @param account The address to add as admin
     */
    function addAdmin(address account) external onlyAdmin {
        if (account == address(0)) revert();
        if (_admins[account]) revert AlreadyAdmin();
        
        _admins[account] = true;
        emit AdminAdded(account);
    }
    
    /**
     * @dev Removes an admin. Only callable by existing admins
     * @param account The address to remove as admin
     */
    function removeAdmin(address account) external onlyAdmin {
        if (!_admins[account]) revert NotAnAdmin();
        
        _admins[account] = false;
        emit AdminRemoved(account);
    }
    
    /**
     * @dev Checks if an address is an admin
     * @param account The address to check
     * @return bool True if the address is an admin
     */
    function isAdmin(address account) external view returns (bool) {
        return _admins[account];
    }
    
    /**
     * @dev Mints new tokens to a specified address. Only callable by admins
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyAdmin {
        _mint(to, amount);
    }
    
    /**
     * @dev Pauses all token transfers. Only callable by admins
     */
    function pause() external onlyAdmin {
        _paused = true;
        emit Paused(msg.sender);
    }
    
    /**
     * @dev Unpauses all token transfers. Only callable by admins
     */
    function unpause() external onlyAdmin {
        _paused = false;
        emit Unpaused(msg.sender);
    }
    
    /**
     * @dev Returns whether the contract is paused
     * @return bool True if paused
     */
    function paused() external view returns (bool) {
        return _paused;
    }
    
    /**
     * @dev Override transfer to add pause functionality
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override transferFrom to add pause functionality
     */
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}

