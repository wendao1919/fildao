// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSignWallet  is Ownable {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event ModifyOwner(uint indexed managerIndex,address indexed owner);

    address[] public owners =new address[](5);
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(uint => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyManager() {
        uint managerIndex =  getOwnerIndex(msg.sender);
        require(managerIndex  < owners.length, "not manager");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        uint managerIndex =  getOwnerIndex(msg.sender);
        require(managerIndex  < owners.length, "not manager");
        require(!isConfirmed[_txIndex][managerIndex], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(_owners.length <= owners.length, "owners too many");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");

            uint managerIndex =  getOwnerIndex(owner);
            require(managerIndex  >= owners.length, "owner not unique");

            owners[i] = owner;  
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyManager {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
        confirmTransaction(txIndex);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        uint managerIndex =  getOwnerIndex(msg.sender);      
        isConfirmed[_txIndex][managerIndex] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
        if(transaction.numConfirmations >= numConfirmationsRequired){
            executeTransaction(_txIndex);
        }
    }

    function executeTransaction(uint _txIndex)
        public
        onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        
        uint managerIndex =  getOwnerIndex(msg.sender);  
        require(isConfirmed[_txIndex][managerIndex], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][managerIndex] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }


    function getOwnerIndex(address _address ) public view returns(uint ){
 
        for(uint i = 0; i < owners.length; i++) {
            if(_address ==  owners[i]){
                return i;
            } 
        }

        return owners.length;
    }


    function modifyOwner(uint _managerIndex,address _address)
        public
        onlyOwner
      
    {
        require(_managerIndex  >= 3, "cannot set");
        require(_managerIndex  < owners.length, "cannot set");
        uint managerIndex =  getOwnerIndex(_address);
        require(managerIndex  >= owners.length, "owner not unique");
        owners[_managerIndex] = _address;  
        emit ModifyOwner(_managerIndex, _address);
         
    }

}