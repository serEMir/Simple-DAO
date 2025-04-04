// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract DAO {
    /* Errors */
    error DAO__OnlyOwnerCanCallThisFunction();
    error DAO__ContributionTimeAndVoteTimeAndQuorumMustBeGreaterThanZero();
    error DAO__ContributionPeriodHasEnded();
    error DAO__ContributionMustBeGreaterThanZero();
    error DAO__AmountMustBeGreaterThanZero();
    error DAO__InsufficientShares();
    error DAO__InsufficientDAOFunds();
    error DAO__TransferFailed();
    error DAO__ContributionPeriodNotEnded();
    error DAO__InvalidProposalID();
    error DAO__VotingOngoing();
    error DAO__ProposalAlreadyExecuted();
    error DAO__QuorumNotMet();
    error DAO__ThereAreNoProposals();
    error DAO__ThereAreNoCurrentInvestors();
    error DAO__InvalidProsalID();
    error DAO__VotingTimeEnded();
    error DAO__AlreadyVoted();
    error DAO__NotAContributor();

    /* Type Declarations */
    struct Proposal {
        string description;
        uint256 amount;
        address recipient;
        uint256 votes;
        bool executed;
        uint256 createdAt;
    }

    /* State variables */
    uint256 public contributionTimeEnd;
    uint256 public voteTime;
    uint256 public quorum;
    uint256 public totalShares;
    address public owner;
    address[] public investors;
    Proposal[] public proposals;
    mapping(address => uint256) public shares;
    mapping(uint256 => mapping(address => bool)) public votes;
    mapping(address => uint256) public contributions;

    /* Events */
    event Contribution(address indexed investor, uint256 amount);
    event SharesRedeemed(address indexed to, uint256 amount);
    event TransferShares(address indexed from, address indexed to, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator);
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalExecuted(address indexed recipient, uint256 indexed proposalId);


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert DAO__OnlyOwnerCanCallThisFunction();
        }
        _;
    }

    function initializeDAO(
        uint256 _contributionTimeEnd,
        uint256 _voteTime,
        uint256 _quorum
    ) public onlyOwner{
        if (_contributionTimeEnd <= 0 && _voteTime <= 0 && _quorum <= 0) {
            revert DAO__ContributionTimeAndVoteTimeAndQuorumMustBeGreaterThanZero();
        }
        contributionTimeEnd = block.timestamp + _contributionTimeEnd;
        voteTime = _voteTime;
        quorum = _quorum;
    }


    function contribution() public payable {
        if (block.timestamp > contributionTimeEnd) {
            revert DAO__ContributionPeriodHasEnded();
        }
        if (msg.value <= 0) {
            revert DAO__ContributionMustBeGreaterThanZero();
        }

        // Convert ETH to shares (1 ETH = 1 share)
        uint256 newShares = msg.value;

        // Update investor records
        if (shares[msg.sender] == 0) {
            investors.push(msg.sender);
        }

        shares[msg.sender] += newShares;
        totalShares += newShares;
        contributions[msg.sender] += msg.value;

        emit Contribution(msg.sender, msg.value);
    }

    function redeemShare(uint256 amount) public{
        if (amount <= 0) {
            revert DAO__AmountMustBeGreaterThanZero();
        }
        if (block.timestamp > contributionTimeEnd) {
            revert DAO__ContributionPeriodHasEnded();
        }
        if (shares[msg.sender] < amount) {
            revert DAO__InsufficientShares();
        }
        if (address(this).balance < amount) {
            revert DAO__InsufficientDAOFunds();
        }

        shares[msg.sender] = shares[msg.sender] - amount;
        totalShares = totalShares - amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert DAO__TransferFailed();
        }

        emit SharesRedeemed(msg.sender, amount);
    }

    function transferShare(uint256 amount, address to) public {
        if (shares[msg.sender] < amount) {
            revert DAO__InsufficientShares();
        }

        shares[msg.sender] -= amount;
        if (shares[to] == 0) {
            investors.push(to);
        }
        shares[to] += amount;

        emit TransferShares(msg.sender, to, amount);
    }

    function createProposal(string calldata description,uint256 amount,address payable recipient) public onlyOwner {
        if (block.timestamp < contributionTimeEnd) {
            revert DAO__ContributionPeriodNotEnded();
        }
        if (amount > address(this).balance) {
            revert DAO__InsufficientDAOFunds();
        }

        Proposal memory newProposal = Proposal({
            description: description,
            amount: amount,
            recipient: recipient,
            votes: 0,
            executed: false,
            createdAt: block.timestamp
        });

        proposals.push(newProposal);
        emit ProposalCreated(proposals.length - 1, msg.sender);
    }

    function voteProposal(uint256 proposalId) public {
        if (proposalId >= proposals.length) {
            revert DAO__InvalidProsalID();
        }
        if (block.timestamp > proposals[proposalId].createdAt + voteTime) {
            revert DAO__VotingTimeEnded();
        }
        if (votes[proposalId][msg.sender]) {
            revert DAO__AlreadyVoted();
        }
        if (shares[msg.sender] <= 0) {
            revert DAO__NotAContributor();
        }

        votes[proposalId][msg.sender] = true;
        proposals[proposalId].votes += shares[msg.sender];

        emit Voted(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) public onlyOwner{
        if (proposalId >= proposals.length) {
            revert DAO__InvalidProposalID();
        }
        Proposal storage proposal = proposals[proposalId];
        if (block.timestamp <= proposal.createdAt + voteTime) {
            revert DAO__VotingOngoing();
        }
        if (proposal.executed) {
            revert DAO__ProposalAlreadyExecuted();
        }
        if (proposal.votes * 100 < quorum * totalShares) {
            revert DAO__QuorumNotMet();
        }

        proposal.executed = true;
        (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
        if (!success) {
            revert DAO__TransferFailed();
        }

        emit ProposalExecuted(proposal.recipient, proposalId);
    }

    function proposalList() public view returns (string[] memory, uint256[] memory, address[] memory) {
        uint256 length = proposals.length;
        if (length <= 0) {
            revert DAO__ThereAreNoProposals();
        }
        string[] memory descriptions = new string[](proposals.length);
        uint256[] memory amounts = new uint256[](proposals.length);
        address[] memory recipients = new address[](proposals.length);

        for(uint256 i = 0; i < proposals.length; i++) {
            descriptions[i] = proposals[i].description;
            amounts[i] = proposals[i].amount;
            recipients[i] = proposals[i].recipient;
        }

        return (descriptions, amounts, recipients);
    }

    function allInvestorList() public view returns (address[] memory) {
        if (investors.length <= 0) {
            revert DAO__ThereAreNoCurrentInvestors();
        }
        return investors;
    }

    function getProposal(uint256 index) public view returns (Proposal memory) {
    return proposals[index];
    }

}