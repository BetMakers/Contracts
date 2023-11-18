// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract BetMakers {
    address betMakerAddress;
    address public owner;
    using SafeERC20 for IERC20;  // SafeERC20 to transfer tokens.
    mapping(uint256 => mapping(uint256 => address[])) public poolParticipants; // uint pubId to uint256 result to betterAddress
    mapping(uint256 => uint256) public matchPool; // uint pubId to uint total pool
    mapping(uint256 => uint256) public matchBet; // uint pubId to uint bet ticket
    address currency = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; 
  
    constructor(){
        owner = msg.sender;
    } 

    modifier onlyBetMakers() {
        require(
            msg.sender == betMakerAddress,
            "OnlyBetMaker"
        );
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }
    function setBet(uint256 pubId, uint256 bet, uint256 result, address profileAddress) public onlyBetMakers{
        matchPool[pubId] += bet;
        matchBet[pubId] = bet;
        poolParticipants[pubId][result].push(profileAddress);
    }

    function joinBet(uint256 pubId, uint256 result, address profileAddress) public onlyBetMakers{
        matchPool[pubId] += matchBet[pubId];
        poolParticipants[pubId][result].push(profileAddress);
    }

    function StartBet(uint256 pubId) external onlyOwner  {
        //devolver apuesta a los que no alcanzaron a hacer match
        uint256 bettersteam1 = poolParticipants[pubId][1].length;
        uint256 bettersteam2 = poolParticipants[pubId][2].length;
        uint256 largerTeam = (bettersteam1 > bettersteam2) ? 1 : 2;
        uint256 smallerTeam = (bettersteam1 > bettersteam2) ? 2 : 1;
        uint256 finalParticipants = poolParticipants[pubId][smallerTeam].length;
        
        if (bettersteam1 != bettersteam2) {   
            for (uint256 i = poolParticipants[pubId][largerTeam].length; i > finalParticipants; --i) {
                IERC20(currency).safeTransfer(poolParticipants[pubId][largerTeam][i], matchBet[pubId]);
                poolParticipants[pubId][largerTeam].pop();
                matchPool[pubId] -= matchBet[pubId];
         }
        } 
    }

    function executeBet(uint256 pubId, uint256 result) external onlyOwner{
        uint256 winners = poolParticipants[pubId][result].length;
        uint256 prize = matchPool[pubId]/winners;
        for (uint256 i; i < winners; ++i) {
            IERC20(currency).safeTransfer(poolParticipants[pubId][result][i], prize);
            matchPool[pubId] -= prize;
        }
    }

    function setBetMaker(address _betMakerAddress) external onlyOwner{
        betMakerAddress = _betMakerAddress;
    }
}