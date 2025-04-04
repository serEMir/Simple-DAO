// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {DAO} from "src/DAO.sol";
import {DeployDAO} from "script/DeployDAO.s.sol";

contract DAOTest is Test, DAO {
    DAO public dao;

    address public CONTRIBUTOR1 = makeAddr("contributor1");
    address public CONTRIBUTOR2 = makeAddr("contributor2");
    address public CONTRIBUTOR3 = makeAddr("contributor3");

    uint256 public constant STARTING_CONTRIBUTOR_BALANCE = 10 ether;

    function setUp() public {
        DeployDAO deployDAO = new DeployDAO();
        dao = deployDAO.run();

        vm.deal(CONTRIBUTOR1, STARTING_CONTRIBUTOR_BALANCE);
        vm.deal(CONTRIBUTOR2, STARTING_CONTRIBUTOR_BALANCE);
        vm.deal(CONTRIBUTOR3, STARTING_CONTRIBUTOR_BALANCE);

        vm.prank(msg.sender);
        dao.initializeDAO(1 days, 1 days, 50);
    }

    function testFullDAOOperations() public {
        vm.prank(CONTRIBUTOR1);
        dao.contribution{value: 1 ether}();
        assertEq(dao.contributions(CONTRIBUTOR1), 1 ether);
        assertEq(dao.shares(CONTRIBUTOR1), 1 ether);
        assertEq(dao.totalShares(), 1 ether);

        vm.prank(CONTRIBUTOR2);
        dao.contribution{value: 1 ether}();
        assertEq(dao.contributions(CONTRIBUTOR2), 1 ether);
        assertEq(dao.shares(CONTRIBUTOR2), 1 ether);
        assertEq(dao.totalShares(), 2 ether);

        vm.prank(CONTRIBUTOR3);
        dao.contribution{value: 1 ether}();
        assertEq(dao.contributions(CONTRIBUTOR3), 1 ether);
        assertEq(dao.shares(CONTRIBUTOR3), 1 ether);
        assertEq(dao.totalShares(), 3 ether);

        vm.prank(CONTRIBUTOR3);
        dao.redeemShare(1 ether);
        assertEq(dao.shares(CONTRIBUTOR3), 0);

        vm.prank(CONTRIBUTOR2);
        dao.transferShare(1 ether, CONTRIBUTOR1);
        assertEq(dao.shares(CONTRIBUTOR2), 0);
        assertEq(dao.shares(CONTRIBUTOR1), 2 ether);

        vm.warp(block.timestamp + 2 days);
        string memory description = "Proposal 1";
        uint256 amount = 1 ether;
        address payable recipient = payable(CONTRIBUTOR2);
        vm.prank(msg.sender);
        dao.createProposal(description, amount, recipient);


        vm.prank(CONTRIBUTOR1);
        dao.voteProposal(0);
        assertEq(dao.getProposal(0).votes, 2 ether);
        assertEq(dao.votes(0, CONTRIBUTOR1), true);

        vm.warp(block.timestamp + 2 days);
        vm.prank(msg.sender);
        dao.executeProposal(0);
        assertEq(address(dao).balance, 1 ether);
        assertTrue(dao.getProposal(0).executed);
        assertEq(CONTRIBUTOR2.balance, STARTING_CONTRIBUTOR_BALANCE);
    }
}