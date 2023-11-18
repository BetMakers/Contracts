// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {HubRestricted} from 'lens/HubRestricted.sol';
import {Types} from 'lens/Types.sol';
import {IPublicationActionModule} from './interfaces/IPublicationActionModule.sol';
import {BetMakers} from './BetMakers.sol';

contract BetMakersOpenAction is HubRestricted, IPublicationActionModule {
    mapping(uint256 => mapping(uint256 => address[])) public poolParticipants; // uint pubId to uint256 result to betterAddress
    mapping(uint256 => uint256) public matchPool; // uint pubId to uint total pool
    mapping(uint256 => uint256) public matchBet; // uint pubId to uint bet ticket
    BetMakers internal _betMakers;
    address currency = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; 
    using SafeERC20 for IERC20;  // SafeERC20 to transfer tokens.

    constructor(address lensHubProxyContract, address betMakersContract) HubRestricted(lensHubProxyContract) {
        _betMakers = BetMakers(betMakersContract);
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId, // publication id
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
      // TODO: only callable for team token holder
        /* result
        0 = draw
        1 = first wins
        2 = second wins
        */
        (string memory matchId, uint256 bet,uint256 result, 
         address profileAddress // poly address
        ) = abi.decode(data, (string, uint256, uint256, address));
        // Crea un pozo depositalo
        //require(msg.sender has fantoken)
        matchPool[pubId] += bet;
        matchBet[pubId] = bet;
        poolParticipants[pubId][result].push(profileAddress);
        IERC20(currency).safeTransferFrom(profileAddress,address(_betMakers), bet);
        _betMakers.setBet(pubId, bet, result, profileAddress);
        // setea el function de la hora cuando termina el partido
        //rewardingTime[pubId] = // get time of match ending from chainlink o sacarlo de afuera
        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
      // TODO: only callable for team token holder (percentage)
      // TODO: not callable after game start
     
      matchPool[params.publicationActedId] += matchBet[params.publicationActedId];
      (uint256 result) = abi.decode(params.actionModuleData, (uint256));
      poolParticipants[params.publicationActedId][result].push(params.actorProfileOwner);
      IERC20(currency).safeTransferFrom(params.actorProfileOwner,address(_betMakers), matchBet[params.publicationActedId]);
      _betMakers.joinBet(params.publicationActedId, result,params.actorProfileOwner);

    }
}
