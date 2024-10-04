// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleLendingProtocol {
    struct Loan {
        address borrower;
        uint256 amountBorrowed;
        uint256 collateralAmount;
        uint256 dueDate;
        bool isRepaid;
    }

    mapping(address => uint256) public deposits; // Lender deposits
    mapping(address => Loan) public loans; // Active loans by borrowers

    uint256 public interestRate = 10; // 10% interest
    uint256 public loanDuration = 30 days;
    uint256 public collateralRatio = 150; // Borrower must provide 150% collateral

    event Deposit(address indexed lender, uint256 amount);
    event Withdraw(address indexed lender, uint256 amount);
    event LoanTaken(address indexed borrower, uint256 loanAmount, uint256 collateralAmount);
    event LoanRepaid(address indexed borrower, uint256 repaymentAmount);
    event CollateralLiquidated(address indexed borrower, uint256 collateralAmount);

    // Deposit funds as a lender
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw funds as a lender
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // Take a loan by providing collateral
    function takeLoan(uint256 loanAmount) external payable {
        require(msg.value >= (loanAmount * collateralRatio) / 100, "Insufficient collateral");
        require(loans[msg.sender].amountBorrowed == 0, "Existing loan must be repaid");

        loans[msg.sender] = Loan({
            borrower: msg.sender,
            amountBorrowed: loanAmount,
            collateralAmount: msg.value,
            dueDate: block.timestamp + loanDuration,
            isRepaid: false
        });

        payable(msg.sender).transfer(loanAmount);
        emit LoanTaken(msg.sender, loanAmount, msg.value);
    }

    // Repay the loan with interest
    function repayLoan() external payable {
        Loan storage loan = loans[msg.sender];
        require(loan.amountBorrowed > 0, "No active loan");
        require(block.timestamp <= loan.dueDate, "Loan is overdue");

        uint256 repaymentAmount = loan.amountBorrowed + (loan.amountBorrowed * interestRate) / 100;
        require(msg.value == repaymentAmount, "Incorrect repayment amount");

        loan.isRepaid = true;
        deposits[address(this)] += repaymentAmount; // Add interest to pool
        payable(msg.sender).transfer(loan.collateralAmount); // Return collateral
        emit LoanRepaid(msg.sender, repaymentAmount);
    }

    // Liquidate overdue loan and seize collateral
    function liquidateOverdueLoan(address borrower) external {
        Loan storage loan = loans[borrower];
        require(loan.amountBorrowed > 0, "No active loan");
        require(block.timestamp > loan.dueDate, "Loan is not overdue");
        require(!loan.isRepaid, "Loan already repaid");

        deposits[address(this)] += loan.collateralAmount; // Lenders take the collateral
        delete loans[borrower]; // Remove loan record
        emit CollateralLiquidated(borrower, loan.collateralAmount);
    }

    // Check lender balance
    function getLenderBalance() external view returns (uint256) {
        return deposits[msg.sender];
    }

    // Check borrower loan details
    function getLoanDetails(address borrower) external view returns (Loan memory) {
        return loans[borrower];
    }
}
