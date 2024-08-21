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
    address[] public owners;

    // check if address is already owner
    mapping(address => bool) public isOwner;

    // number of approvaols required
    uint256 public numberOfApprovs;

    struct Transactions {
        address to;
        uint256 amount;
        bool executed;
    }

    Transactions[] public transactionsList;
    mapping(uint256 => mapping(address => bool)) transactionsApproval;

    constructor(address[] memory _owner, uint256 _numberOfApprovs) {
        require(_owner.length > 0, "list of owner must not be empty");
        require(
            _numberOfApprovs > 0 && _numberOfApprovs <= _owner.length,
            "number of approvals must not be greater than number of owners"
        );
    }
}
