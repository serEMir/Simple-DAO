// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {DAO} from "src/DAO.sol";
import {DeployDAO} from "script/DeployDAO.s.sol";

contract DAOTest is Test, DAO {
    DAO dao;

    function setUp() public {
        DeployDAO deployDAO = new DeployDAO();
        dao = deployDAO.run();
        
        vm.prank(msg.sender);
        dao.initializeDAO(1 days, 1 days, 50);
    }

    function testInitialize() public view {
        assertEq(dao.owner(), msg.sender);
        assertEq(dao.contributionTimeEnd(), block.timestamp + 1 days);
        assertEq(dao.voteTime(), 1 days);
        assertEq(dao.quorum(), 50);
    }

    /*//////////////////////////////////////////////////////////////
                              CONTRIBUTION
    //////////////////////////////////////////////////////////////*/

    function testContribution() public {

        vm.expectEmit(true, false, false, true, address(dao));
        emit Contribution(address(0x1), 1 ether);
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();
        assertEq(dao.contributions(address(0x1)), 1 ether);
        assertEq(dao.shares(address(0x1)), 1 ether);
        assertEq(dao.totalShares(), 1 ether);

    }

    function testContributionFailsAfterEnd() public {
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.DAO__ContributionPeriodHasEnded.selector);
        dao.contribution{value: 1 ether}();
    }

    /*//////////////////////////////////////////////////////////////
                             REDEEM SHARES
    //////////////////////////////////////////////////////////////*/

    function testSharesRedeemAndEmitted() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.deal(address(dao), 1 ether);

        vm.prank(address(0x1));
        vm.expectEmit(true, false, false, true, address(dao));
        emit SharesRedeemed(address(0x1), 1 ether);
        dao.redeemShare(1 ether);
        assertEq(dao.shares(address(0x1)), 0);
        assertEq(dao.totalShares(), 0);

    }

    function testRedeemShareFailsIfFundsNotEnough() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();
        vm.deal(address(dao), 1 ether);

        vm.expectRevert(DAO.DAO__InsufficientShares.selector);
        vm.prank(address(0x1));
        dao.redeemShare(2 ether);
    }

    function testRedeemShareFailsAfterContributionEnds() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.DAO__ContributionPeriodHasEnded.selector);
        
        dao.redeemShare(1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER SHARES
    //////////////////////////////////////////////////////////////*/

    function testShareTransferredAndEmitted() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.expectEmit(true, true, false, true, address(dao));
        emit TransferShares(address(0x1), address(0x2), 1 ether);
        vm.prank(address(0x1));
        dao.transferShare(1 ether, address(0x2));
        assertEq(dao.shares(address(0x1)), 0);
        assertEq(dao.shares(address(0x2)), 1 ether);
    }

    function testShareTransferredFailsIfInsufficientShares() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.expectRevert(DAO.DAO__InsufficientShares.selector);
        vm.prank(address(0x1));
        dao.transferShare(2 ether, address(0x2));
    }

      /*//////////////////////////////////////////////////////////////
                            CREATE PROPOSALS
    //////////////////////////////////////////////////////////////*/

    function testOnlyOwnerCanCreateProposal() public {
        vm.deal(address(dao), 1 ether);
        vm.warp(block.timestamp + 2 days);
        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x2)));
        assertEq(dao.owner(), msg.sender);
    }

    function testProposalAddedAndEmittedWithCorrectDetails() public {
        vm.deal(address(dao), 2 ether);
        vm.warp(block.timestamp + 2 days);

        string memory description = "Proposal 1";
        uint256 amount = 1 ether;
        address payable recipient = payable(address(0x2));

        vm.expectEmit(true, true, false, false, address(dao));
        emit ProposalCreated(0, msg.sender);
        vm.prank(msg.sender);
        dao.createProposal(description, amount, recipient);

        DAO.Proposal memory proposal = dao.getProposal(0);

        assertEq(proposal.description, description);
        assertEq(proposal.amount, amount);
        assertEq(proposal.recipient, recipient);
        assertEq(proposal.votes, 0);
        assertFalse(proposal.executed);
        assertEq(proposal.createdAt, block.timestamp);

    }

    function testProposalFailsIfContributionPeriodNotEnded() public {
        vm.deal(address(dao), 1 ether);

        vm.expectRevert(DAO.DAO__ContributionPeriodNotEnded.selector);
        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x2)));
    }

    function testProposalFailsIfFundsInsufficient() public {
        vm.deal(address(dao), 1 ether);
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.DAO__InsufficientDAOFunds.selector);
        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 2 ether, payable(address(0x2)));
    }

    modifier createProposalAfterRequirementsMet {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();
        vm.deal(address(dao), 1 ether);
        vm.warp(block.timestamp +2 days);

        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x2)));
        _;
    }

     /*//////////////////////////////////////////////////////////////
                             VOTE PROPOSALS
    //////////////////////////////////////////////////////////////*/

    function testVoteProposalAndVoteEmitted() public createProposalAfterRequirementsMet {
        vm.expectEmit(true, true, false, false, address(dao));
        emit Voted(0, address(0x1));
        vm.prank(address(0x1));
        dao.voteProposal(0);
        assertEq(dao.getProposal(0).votes, 1 ether);
        assertEq(dao.votes(0, address(0x1)), true);
    }

    function testVoteProposalFailsIfVoteTimeEnded() public createProposalAfterRequirementsMet {
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.DAO__VotingTimeEnded.selector);
        vm.prank(address(0x1));
        dao.voteProposal(0);
    }

    function testVoteProposalFailIfAlreadyVoted() public createProposalAfterRequirementsMet {
        vm.prank(address(0x1));
        dao.voteProposal(0);

        vm.expectRevert(DAO.DAO__AlreadyVoted.selector);
        vm.prank(address(0x1));
        dao.voteProposal(0);
    }

    function testVoteProposalFailIfNotAContributor() public createProposalAfterRequirementsMet {
        vm.expectRevert(DAO.DAO__NotAContributor.selector);
        vm.prank(address(0x2));
        dao.voteProposal(0);
    }

    /*//////////////////////////////////////////////////////////////
                           EXECUTE PROPOSALS
    //////////////////////////////////////////////////////////////*/

    function testProposalExecutedAndEmitted() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.deal(address(0x2), 1 ether);
        vm.prank(address(0x2));
        dao.contribution{value: 1 ether}();

        vm.deal(address(dao), 2 ether);
        vm.warp(block.timestamp + 2 days);

        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x3)));

        vm.prank(address(0x1));
        dao.voteProposal(0);

        vm.warp(block.timestamp + 2 days);

        vm.expectEmit(true, false, false, false, address(dao));
        emit ProposalExecuted(address(0x3), 0);
        vm.prank(msg.sender);
        dao.executeProposal(0);
        assertEq(dao.getProposal(0).executed, true);
        assertEq(address(dao).balance, 1 ether);
        assertEq(address(0x3).balance, 1 ether);

    }

    function testProposalExecutedFailsIfNotOwner() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.deal(address(dao), 1 ether);
        vm.warp(block.timestamp + 2 days);

        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x3)));

        vm.prank(address(0x1));
        dao.voteProposal(0);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.DAO__OnlyOwnerCanCallThisFunction.selector);
        vm.prank(address(0x2));
        dao.executeProposal(0);
    }

    function testProposalExecutedFailsIfVotingOngoing() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.deal(address(dao), 1 ether);
        vm.warp(block.timestamp + 2 days);

        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x3)));

        vm.expectRevert(DAO.DAO__VotingOngoing.selector);
        vm.prank(msg.sender);
        dao.executeProposal(0);
    }

    function testProposalExecutedFailsIfAlreadyExecuted() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.deal(address(dao), 1 ether);
        vm.warp(block.timestamp + 2 days);

        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x3)));

        vm.prank(address(0x1));
        dao.voteProposal(0);

        vm.warp(block.timestamp + 2 days);

        vm.prank(msg.sender);
        dao.executeProposal(0);

        vm.expectRevert(DAO.DAO__ProposalAlreadyExecuted.selector);
        vm.prank(msg.sender);
        dao.executeProposal(0);
    }

    function testProposalExecutedFailsIfQuorumNotMet() public {
        vm.prank(address(0x1));
        dao.contribution{value: 1 ether}();

        vm.deal(address(0x2), 1 ether);
        vm.prank(address(0x2));
        dao.contribution{value: 1 ether}();

        vm.deal(address(0x3), 1 ether);
        vm.prank(address(0x3));
        dao.contribution{value: 1 ether}();

        vm.deal(address(dao), 3 ether);
        vm.warp(block.timestamp + 2 days);

        vm.prank(msg.sender);
        dao.createProposal("Proposal 1", 1 ether, payable(address(0x4)));

        vm.prank(address(0x1));
        dao.voteProposal(0);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.DAO__QuorumNotMet.selector);
        vm.prank(msg.sender);
        dao.executeProposal(0);
    }
}