//SPDX-License-Identifier:MIT

pragma solidity ^0.8.16;


contract MultiSigWallet{

    event Deposit(address indexed sender, uint amount, uint balance);
    event Submit( address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data);
    event Approve(address indexed onwer, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);


    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    //Address of Owner to approved transactions 
    mapping(uint => mapping(address => bool))public approved;


    Transaction[] public  transactions;


    //Modifier functions
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }    


    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx dose not exist");
        _;
    }    

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuited(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }
    //required address and number of owners
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <=_owners.length, "invalid required number of owner");

        for(uint i; i<_owners.length; i++) {
            address owner = _owners[i];

            require(owner !=address(0), " invalid owner");
            require(!isOwner[owner], "owner is not unique");



            isOwner[owner]= true;
            owners.push(owner);
        }

        required = _required;    

    }

    //contract to hold the balance
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    //Data to submit for approval
    function subMit(address _to, uint _value, bytes memory _data ) external  onlyOwner{uint txIndex = transactions.length;

        transactions.push(Transaction({
        to: _to,
        value: _value,
        data: _data,
        executed: false,
        numConfirmations: 0
       })
       
       );

        emit Submit(msg.sender, txIndex, _to, _value, _data);
    }

    //address owners approval process
    function executeTransaction(uint _txId)
        public
        onlyOwner
        txExists(_txId )
        notExecuited(_txId )
    {
        Transaction storage transaction = transactions[_txId];

        require(transaction.numConfirmations >= required,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit Approve(msg.sender, _txId );
    }

    //revoke transaction in not approve majority owners
    function revokeConfirmation(uint _txId )
        public
        onlyOwner
        txExists(_txId )
        notExecuited(_txId )
    {
        Transaction storage transaction = transactions[_txId];

        require(approved[_txId][msg.sender], "tx not confirmed");

        transaction.numConfirmations --;
        approved[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }

    //See address owners
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    //number of pending transactions
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    //see what transactions are pending 
    function getTransaction(uint _txId)
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
        Transaction storage transaction = transactions[_txId];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
  
}