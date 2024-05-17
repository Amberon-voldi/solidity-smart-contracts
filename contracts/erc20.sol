// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//You can change the contract name to your liking
contract ERC20Token {
    string public name = "<name>"; // Provide name for your token
    string public symbol = "<symbol>"; // Provide symbol for your token
    uint8 public decimals = 18; // Default 18 decimals
    uint256 public totalSupply = 25000000 * (10**uint256(decimals)); // Total supply of tokens

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccounts;
    mapping(address => bool) public approvedContracts;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event NameAndSymbolChanged(string newName, string newSymbol);
    event ContractApproved(address indexed contractAddress);
    event ContractApprovalRevoked(address indexed contractAddress);
    event TokenReceived(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    modifier whenNotFrozen(address account) {
        require(!frozenAccounts[account], "Account is frozen");
        _;
    }

    modifier onlyApprovedContracts() {
        require(approvedContracts[msg.sender], "Contract not approved");
        _;
    }

    bool public paused = false;

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a + b >= a, "SafeMath: addition overflow");
        return a + b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "SafeMath: subtraction overflow");
        return a - b;
    }

    function transfer(address to, uint256 value)
        public
        whenNotPaused
        whenNotFrozen(msg.sender)
        whenNotFrozen(to)
        returns (bool success)
    {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool success)
    {
        allowance[msg.sender][spender] = safeAdd(
            allowance[msg.sender][spender],
            addedValue
        );
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool success)
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "Allowance cannot be negative"
        );
        allowance[msg.sender][spender] = safeSub(
            currentAllowance,
            subtractedValue
        );
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function allowanceOf(address spender)
        public
        view
        returns (uint256)
    {
        return allowance[owner][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        whenNotPaused
        whenNotFrozen(from)
        whenNotFrozen(to)
        returns (bool success)
    {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        allowance[from][msg.sender] = safeSub(
            allowance[from][msg.sender],
            value
        );
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value)
        public
        onlyOwner
        returns (bool success)
    {
        require(to != address(0), "Invalid address");

        totalSupply = safeAdd(totalSupply, value);
        balanceOf[to] = safeAdd(balanceOf[to], value);
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value)
        public
        whenNotFrozen(msg.sender)
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        totalSupply = safeSub(totalSupply, value);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function freezeAccount(address account) public onlyOwner {
        frozenAccounts[account] = true;
        emit Freeze(account);
    }

    function unfreezeAccount(address account) public onlyOwner {
        frozenAccounts[account] = false;
        emit Unfreeze(account);
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function changeNameAndSymbol(string memory newName, string memory newSymbol)
        public
        onlyOwner
    {
        name = newName;
        symbol = newSymbol;
        emit NameAndSymbolChanged(newName, newSymbol);
    }

    function approveContract(address contractAddress) public onlyOwner {
        approvedContracts[contractAddress] = true;
        emit ContractApproved(contractAddress);
    }

    function revokeContractApproval(address contractAddress) public onlyOwner {
        approvedContracts[contractAddress] = false;
        emit ContractApprovalRevoked(contractAddress);
    }

    function executeOnTokenReceived(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) public onlyApprovedContracts {
        // Implement custom logic for approved contracts.
        emit TokenReceived(from, to, value, data);
    }
}
