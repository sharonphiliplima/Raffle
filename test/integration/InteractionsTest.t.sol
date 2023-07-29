//unit
//integration -> testing deploy script and various other parts!
//forked -> pseudo staging integration test
//staging -> run on a mainnet/testnet

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
