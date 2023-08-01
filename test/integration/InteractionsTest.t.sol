//unit
//integration -> testing deploy script and various other parts!
//forked -> pseudo staging integration test
//staging -> run on a mainnet/testnet

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract Interactions is Test {
    //check if it returns a correct subId for the vrfCoordinator
    //check if it funds the subId
    //check if the a consumer is added properly

    Raffle raffle;
    HelperConfig helperConfig;

    //state variables to use in the test!
    address vrfCoordinator;
    uint64 subscriptionId;
    address link;
    uint256 deployerKey;

    address public SUBSCRIBER = makeAddr("subscriber");
    uint256 public constant STARTING_SUBSCRIBER_BALANCE = 10 ether;

    event SubscriptionFunded(uint64 indexed subId);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            ,
            ,
            vrfCoordinator,
            ,
            subscriptionId,
            ,
            link,
            deployerKey
        ) = helperConfig.activeNetworkConfig();
        vm.deal(SUBSCRIBER, STARTING_SUBSCRIBER_BALANCE);
    }

    function testCreateSubscriptionReturnsSubId() public {
        //Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 testSubId = createSubscription.createSubscription(
            vrfCoordinator,
            deployerKey
        );
        //Act
        vm.recordLogs();
        VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 subId = entries[0].topics[1];
        console.log("subId:", uint64(uint160(uint256(subId))));
        console.log("testSubId: ", testSubId);

        //Assert
        assert(testSubId == (uint64(uint160(uint256(subId))) - 1));
        //The mock gives the next subscriptionID! see the working below:
        //function createSubscription() external override returns (uint64 _subId) {
        //s_currentSubId++;
    }

    //     function testFundSubscriptionLocalChainWithGoodParameters() public {
    //         //Arrange
    //         uint96 _baseFee = 0.25 ether;
    //         uint96 _gasPriceLink = 1e9;
    //         FundSubscription fundSubscription = new FundSubscription();
    //         VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
    //             _baseFee,
    //             _gasPriceLink
    //         );

    //         //Assert/Act
    //         vm.prank(SUBSCRIBER);
    //         vm.expectEmit(true, false, false, false);
    //         emit SubscriptionFunded(subscriptionId);
    //         fundSubscription.fundSubscription(
    //             vrfCoordinator,
    //             subscriptionId,
    //             link,
    //             deployerKey
    //         );
    //     }
}
