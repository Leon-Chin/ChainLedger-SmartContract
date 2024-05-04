// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LedgerRecord {
    struct DebtRecord {
        uint id;
        address debtor;
        address creditor;
        uint amount;
        uint256 repaymentDueDate; // Timestamp for when the debt is due
        uint256 repaymentDate; // Timestamp for when the debt was actually repaid
        string[] initialEvidenceImages;
        string[] settledEvidenceImages;
        bool debtorInitiateConfirmed;
        bool creditorInitiateConfirmed;
        bool debtorSettledConfirmed;
        bool creditorSettledConfirmed;
        bool isActive;
    }

    struct DebtInfo {
        uint id;
        address oppositeParty; // The other party involved in the debt
        uint amount;
        uint256 repaymentDueDate;
        uint256 repaymentDate;
        string[] initialEvidenceImages;
        string[] settledEvidenceImages;
        bool debtorInitiateConfirmed;
        bool creditorInitiateConfirmed;
        bool debtorSettledConfirmed;
        bool creditorSettledConfirmed;
        bool isDebtor; // True if the user is the debtor, false if the creditor
    }

    DebtRecord[] public debts;
    uint public nextId = 0;

    mapping(address => uint[]) public debtorDebts;
    mapping(address => uint[]) public creditorDebts;
    mapping(address => address[]) public contactUser;

    // events
    event DebtCreated(
        uint id,
        address indexed debtor,
        address indexed creditor
    );
    event DebtSettled(
        uint id,
        address indexed debtor,
        address indexed creditor
    );
    event DebtDeleted(uint id);
    event DebtConfirmed(uint id);

    function recordDebt(
        address _debtor,
        address _creditor,
        uint _amount,
        uint256 _repaymentDueDate,
        string[] memory _initialEvidenceImages
    ) public {
        require(
            _repaymentDueDate > block.timestamp,
            "Repayment due date must be in the future"
        );
        bool debtorInitiateConfirmed = false;
        bool creditorInitiateConfirmed = false;
        if (msg.sender == _debtor) {
            debtorInitiateConfirmed = true;
        } else {
            creditorInitiateConfirmed = true;
        }
        debts.push(
            DebtRecord(
                nextId,
                _debtor,
                _creditor,
                _amount,
                _repaymentDueDate,
                0,
                _initialEvidenceImages,
                new string[](0),
                debtorInitiateConfirmed,
                creditorInitiateConfirmed,
                false,
                false,
                true
            )
        );
        debtorDebts[_debtor].push(nextId);
        creditorDebts[_creditor].push(nextId);

        // used for retrieve all contacts of a user
        // if the contact is not existed, add it to the contact list
        address[] memory allContactsOfDebtor = contactUser[_debtor];
        address[] memory allContactsOfCreditor = contactUser[_creditor];
        bool isExistedForDebtor = false;
        for (uint256 i = 0; i < allContactsOfDebtor.length; i++) {
            if (allContactsOfDebtor[i] == _creditor) {
                isExistedForDebtor = true;
                break;
            }
        }
        if (!isExistedForDebtor) {
            contactUser[_debtor].push(_creditor);
        }
        bool isExistedForCreditor = false;
        for (uint256 i = 0; i < allContactsOfCreditor.length; i++) {
            if (allContactsOfCreditor[i] == _debtor) {
                isExistedForCreditor = true;
                break;
            }
        }
        if (!isExistedForCreditor) {
            contactUser[_creditor].push(_debtor);
        }

        emit DebtCreated(nextId, _debtor, _creditor);
        nextId++;
    }

    function confirmDebt(uint _id) public {
        DebtRecord storage debt = debts[_id];
        require(
            msg.sender == debt.debtor || msg.sender == debt.creditor,
            "Only debtor or creditor can confirm the debt"
        );
        if (msg.sender == debt.debtor) {
            debt.debtorInitiateConfirmed = true;
        } else if (msg.sender == debt.creditor) {
            debt.creditorInitiateConfirmed = true;
        }
        if (debt.debtorInitiateConfirmed && debt.creditorInitiateConfirmed) {
            emit DebtConfirmed(_id);
        }
    }

    function settleDebt(
        uint _id,
        uint256 _repaymentDate,
        string[] memory _settledEvidenceImages
    ) public {
        DebtRecord storage debt = debts[_id];
        require(
            msg.sender == debt.debtor,
            "Only the debtor can settle the debt"
        );
        require(
            debt.debtorInitiateConfirmed && debt.creditorInitiateConfirmed,
            "Both parties must confirm the debt before settling"
        );
        require(
            (debt.debtorSettledConfirmed && debt.creditorSettledConfirmed) ==
                false,
            "Debt is already settled"
        );
        debt.debtorSettledConfirmed = true;
        debt.repaymentDate = _repaymentDate;
        debt.settledEvidenceImages = _settledEvidenceImages;
        if (debt.debtorSettledConfirmed && debt.creditorSettledConfirmed) {
            emit DebtSettled(_id, debt.debtor, debt.creditor);
        }
    }
    function confirmSettledDebt(uint _id) public {
        DebtRecord storage debt = debts[_id];
        require(
            msg.sender == debt.creditor,
            "Not authorithed to confirm the debt"
        );
        require(
            debt.debtorInitiateConfirmed && debt.creditorInitiateConfirmed,
            "Both parties must confirm the debt before settling"
        );
        require(
            (debt.debtorSettledConfirmed && debt.creditorSettledConfirmed) ==
                false,
            "Debt is already settled"
        );
        debt.creditorSettledConfirmed = true;
        if (debt.debtorSettledConfirmed && debt.creditorSettledConfirmed) {
            emit DebtSettled(_id, debt.debtor, debt.creditor);
        }
    }
    function getAllDebts(
        address _user
    ) public view returns (DebtInfo[] memory) {
        uint[] memory debtorDebtIds = debtorDebts[_user];
        uint[] memory creditorDebtIds = creditorDebts[_user];

        uint activeCount = 0; // Counter for active debts

        // First count active debts to allocate array size properly
        for (uint i = 0; i < debtorDebtIds.length; i++) {
            if (debts[debtorDebtIds[i]].isActive) {
                activeCount++;
            }
        }
        for (uint j = 0; j < creditorDebtIds.length; j++) {
            if (debts[creditorDebtIds[j]].isActive) {
                activeCount++;
            }
        }

        // Create an array with the size of active(undeleted) debts
        DebtInfo[] memory results = new DebtInfo[](activeCount);
        uint resultIndex = 0;

        // Populate the array with active debts
        for (uint i = 0; i < debtorDebtIds.length; i++) {
            uint debtId = debtorDebtIds[i];
            DebtRecord storage record = debts[debtId];
            if (record.isActive) {
                results[resultIndex++] = DebtInfo(
                    record.id,
                    record.creditor,
                    record.amount,
                    record.repaymentDueDate,
                    record.repaymentDate,
                    record.initialEvidenceImages,
                    record.settledEvidenceImages,
                    record.debtorInitiateConfirmed,
                    record.creditorInitiateConfirmed,
                    record.debtorSettledConfirmed,
                    record.creditorSettledConfirmed,
                    true
                );
            }
        }

        for (uint j = 0; j < creditorDebtIds.length; j++) {
            uint debtId = creditorDebtIds[j];
            DebtRecord storage record = debts[debtId];
            if (record.isActive) {
                results[resultIndex++] = DebtInfo(
                    record.id,
                    record.debtor,
                    record.amount,
                    record.repaymentDueDate,
                    record.repaymentDate,
                    record.initialEvidenceImages,
                    record.settledEvidenceImages,
                    record.debtorInitiateConfirmed,
                    record.creditorInitiateConfirmed,
                    record.debtorSettledConfirmed,
                    record.creditorSettledConfirmed,
                    false
                );
            }
        }

        return results;
    }

    // Method to calculate the total amount of money still owed by the user
    function getTotalDebtOwed(address _user) public view returns (uint) {
        uint totalOwed = 0; // Initialize totalOwed
        uint[] memory debtIds = debtorDebts[_user];
        for (uint i = 0; i < debtIds.length; i++) {
            DebtRecord storage record = debts[debtIds[i]];
            if (record.repaymentDate == 0 && record.isActive == true) {
                // Check if the debt is not settled
                totalOwed += record.amount;
            }
        }
        return totalOwed; // Return the total amount owed
    }

    // Method to calculate the total amount of money still owed to the user
    function getTotalCreditOwed(address _user) public view returns (uint) {
        uint totalOwed = 0; // Initialize totalOwed
        uint[] memory debtIds = creditorDebts[_user];
        for (uint i = 0; i < debtIds.length; i++) {
            DebtRecord storage record = debts[debtIds[i]];
            if (record.repaymentDate == 0 && record.isActive == true) {
                // Check if the debt is not settled
                totalOwed += record.amount;
            }
        }
        return totalOwed; // Return the total amount owed to the user
    }

    // Method to update a debt record
    function updateDebt(
        uint _id,
        uint _newAmount,
        uint256 _newRepaymentDueDate
    ) public {
        require(_id < debts.length, "Debt record does not exist.");
        DebtRecord storage record = debts[_id];
        require(
            msg.sender == record.debtor || msg.sender == record.creditor,
            "Only debtor or creditor can update the debt."
        );
        require(
            _newRepaymentDueDate > block.timestamp,
            "New repayment due date must be in the future."
        );
        require(record.repaymentDate == 0, "Cannot update a settled debt.");

        record.amount = _newAmount;
        record.repaymentDueDate = _newRepaymentDueDate;
    }

    function deleteDebt(uint _id) public {
        require(
            _id < debts.length && debts[_id].isActive,
            "Debt record does not exist or already inactive."
        );
        DebtRecord storage record = debts[_id];
        require(
            (msg.sender == record.debtor || msg.sender == record.creditor) &&
                record.repaymentDate == 0,
            "Only active, unsettled debts can be deleted by debtor or creditor."
        );
        require(
            !(record.creditorInitiateConfirmed &&
                record.debtorInitiateConfirmed),
            "Cannot delete a confirmed debt."
        );
        record.isActive = false;
        emit DebtDeleted(_id);
    }

    function getRecentTransactionPartners(
        address _user
    ) public view returns (address[] memory) {
        address[] memory allContacts = contactUser[_user];
        return allContacts;
    }
}
