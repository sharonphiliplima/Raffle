//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract DeployRaffleTest is Test {
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId; //either get this from UI or make yourself
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;
    HelperConfig helperConfig = new HelperConfig();

    function setUp() public {
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            ,
            deployerKey
        ) = helperConfig.activeNetworkConfig();
    }

    Raffle deployedRaffle;

    //     new Raffle(
    //         entranceFee,
    //         interval,
    //         vrfCoordinator,
    //         gasLane,
    //         subscriptionId,
    //         callbackGasLimit
    //     );

    function testDeployRaffleReturnValuesAreNotNull() public {
        DeployRaffle deployer = new DeployRaffle();
        (deployedRaffle, helperConfig) = deployer.run();

        assert(address(deployedRaffle) != address(0));
        assert(address(helperConfig) != address(0));
    }
}
