// Layout of Contract:

// version
// imports
// errors
// interfaces, libraries, contracts

/**Inside the contracts: 
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
// external & public view & pure functions */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title A Sample Raffle Contract
 * @author Sharon Philip Lima
 * @notice This contract is for creating a sample Raffle
 * @dev Implements Chainlink VRFv2
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__notEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /** Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    //Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; //uppercase is gas efficient?
    uint32 private constant NUM_WORDS = 1; //we want only 1 winner

    uint256 private immutable i_entranceFee;
    //@dev duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players; //payable coz we are gonna pay the winner!
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */

    event RequestedRaffleWinner(uint256 indexed requestId);
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__notEnoughEthSent();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender); //emitting the event! we changed a state variable
    }

    /**
     * This is the function that the Chainlink Automation nodes call to
     * see if it is true to perform an upkeep.
     * The following should be true for this to return true
     * 1. The time interval has passed between raffle runs
     * 2. The Raffle is in the OPEN state
     * 3. The contract has ETH i.e players
     * 4. (Implicit) the subscription is funded with Link
     */

    function checkUpkeep(
        bytes memory /** checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x00");
    }

    //1. Get a random number
    //2. Use the random number to pick a player
    //3. Be automatically called while picking the winner!

    //Getting a random number is a two transaction function.
    //1. Request the RNG <- done by pickWinner
    //2. Get a random number <- something that ChainLink Node sends back to us

    //pickWinner() changed to performUpkeep()

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        //check to see if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;

        //make a request to the Chainlink node to give us a random number!
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            //vrfCoordinator calls VRFCoordinatorV2Interface
            //only the chainlink node can respond to that!
            //that in turn calls requestRandomWords and generates a random number
            //VRFCoordinatorV2Interface calls rawFulfillRandomWords from VRFConsumeV2Interface
            //that function in turn calls fulfillRandomWords
            i_gasLane, //gas lane (just specify if you don't wanna spend too much gas)
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit, //amount of gas you want the second tx to spend while getting the random number
            NUM_WORDS
        );
        //The following emit is redundant as it is already emitted by VRFCoordinatorV2mock
        //It is used for test purposes
        emit RequestedRaffleWinner(requestId);
    }

    //Chainlink node after getting a random number calls VRF coordinator
    //VRF coordinator calls VRFConsumerBaseV2 which calls rawFulfillRandomWords
    //And rawFulfillRandomWords calls fulfillRandomWords after the check is done
    //Check -> msg.sender == vrfCoordinator
    function fulfillRandomWords(
        uint256 /**requestId*/,
        uint256[] memory randomWords
    ) internal override {
        //let s_players[10]
        //rng = 12
        //rng % s_players[10] = 2
        //so, 2nd player in the array is the winner
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Functions*/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
