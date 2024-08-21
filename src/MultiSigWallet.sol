/*
ASSIGNMENT DESCRIPTION:

Let's create an multi-sig wallet. Here are the specifications.

The wallet owners can

- submit a transaction
- approve and revoke approval of pending transactions
- anyone can execute a transaction after enough owners has approved it.
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract MultiSigWallet {
    // list of owners
    address[] private owners;

    // check if address is already owner
    mapping(address => bool) public isOwner;

    // number of approvaols required
    uint256 public numberOfApproveRequired;

    struct Transaction {
        address to;
        uint256 amount;
        bool executed;
        uint256 numberOfApprovals;
        bytes data;
    }

    Transaction[] public transactionsList;

    // mapping from txIndex => owner => true|false
    mapping(uint256 => mapping(address => bool)) private transactionsApproval;

    // event *
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed txIndex,
        uint256 amount,
        bytes data
    );

    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    event ApproveTransaction(address indexed sender, uint256 txIdex);

    event RevokeTransaction(address indexed sender, uint256 txIdex);

    event executingTransaction(address indexed sender, uint256 txIndex);
    // modifier *

    // only owner allow to call function
    modifier onlyOnwer() {
        require(isOwner[msg.sender], "you are not owner");
        _;
    }

    // transaction exists
    modifier txExist(uint256 txIndex) {
        require(txIndex < transactionsList.length, "transaction don't exist");
        _;
    }

    // transaction status
    modifier txNotExecuted(uint256 txIndex) {
        require(
            !transactionsList[txIndex].executed,
            "transaction already executed"
        );
        _;
    }

    // transaction approval
    modifier txNotApproved(uint256 txIndex) {
        require(
            !transactionsApproval[txIndex][msg.sender],
            "transaction already approved"
        );
        _;
    }

    constructor(address[] memory _owners, uint256 _numberOfApproveRequired) {
        require(_owners.length > 0, "list of owner must not be empty");
        require(
            _numberOfApproveRequired > 0 &&
                _numberOfApproveRequired <= _owners.length,
            "number of approval required must not be greater than number of owners"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(_owners[i] != address(0), "invalid address");
            require(!isOwner[owner], "address already exists as an owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numberOfApproveRequired = _numberOfApproveRequired;
    }

    // receive function
    receive() external payable {}

    // transaction submission
    function submitTransaction(
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public onlyOnwer {
        require(_to != address(0), "invalid address");
        require(_amount > 0, "amount ethers to sent must be greater than 0");

        // get the index of transaction
        uint256 _txIndex = transactionsList.length;
        transactionsList.push(
            Transaction({
                to: _to,
                amount: _amount,
                executed: false,
                numberOfApprovals: 0,
                data: _data
            })
        );
        emit Transfer(msg.sender, _to, _txIndex, _amount, _data);
    }

    // confirm transaction
    function approveTransaction(
        uint256 _txIndex
    )
        public
        onlyOnwer
        txExist(_txIndex)
        txNotApproved(_txIndex)
        txNotExecuted(_txIndex)
    {
        // increase the number of approval for this transaction
        transactionsList[_txIndex].numberOfApprovals++;
        // approve this transaction
        transactionsApproval[_txIndex][msg.sender] = true;

        // emit event
        emit ApproveTransaction(msg.sender, _txIndex);
    }

    // revoke transaction
    function revokeTransaction(
        uint256 _txIndex
    ) public onlyOnwer txExist(_txIndex) txNotExecuted(_txIndex) {
        // require this transaction to be already approved
        require(
            transactionsApproval[_txIndex][msg.sender],
            "transaction is not approved"
        );

        // decrease the number of approval for this transaction
        transactionsList[_txIndex].numberOfApprovals--;

        // revoke transaction
        transactionsApproval[_txIndex][msg.sender] = false;

        // emit event for revoke
        emit RevokeTransaction(msg.sender, _txIndex);
    }

    // execute a transaction
    function executeTransaction(
        uint256 _txIndex
    ) public onlyOnwer txExist(_txIndex) txNotExecuted(_txIndex) {
        // to be in the state of execution, this transaction must be already approved
        require(
            transactionsApproval[_txIndex][msg.sender],
            "transaction is not approved yet"
        );

        // the number of approval for this transaction must be greater than the number of approval required by the network
        require(
            transactionsList[_txIndex].numberOfApprovals >=
                numberOfApproveRequired,
            "number of approval for this transaction is not satisfied by the network"
        );

        // if the number of approval required by the network is alreay satisfied, execute the transaction
        Transaction memory _tx = transactionsList[_txIndex];
        _tx.executed = true;

        // exeucte the transaction
        (bool status, ) = _tx.to.call{value: _tx.amount}(_tx.data);
        require(status, "tx failed");

        emit executingTransaction(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function countTransaction() public view returns (uint256) {
        return transactionsList.length;
    }

    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        returns (
            address to,
            uint256 amount,
            bytes memory data,
            bool executed,
            uint256 numberOfApprovals
        )
    {
        Transaction memory _tx = transactionsList[_txIndex];
        return (
            _tx.to,
            _tx.amount,
            _tx.data,
            _tx.executed,
            _tx.numberOfApprovals
        );
    }
}
