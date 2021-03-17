pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";


contract Lotto is VRFConsumerBase{

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;


    uint public aggregatePaid;

    bool public done = false;

    uint256 public ticketPrice = 10 ether;

    address organiser;

    Ticket[] tickets;

    mapping (address => uint) pendingWithdrawals;

    mapping(uint8 => uint) numberOfWinningTicketsByCorrectNumber;

    mapping(uint8 => uint) winningAmountByCorrectNumber;

    uint currId = 1;

    uint8[] resultNumbers;

    function getResultNumbers() public raffleDone view returns (uint8[] memory) {
        return resultNumbers;
    }

    event TicketBought(Ticket ticket);

    event NumbersDrawn(uint8[] resultNumbers);

    event Withdrawal(address winner, uint amount);

    event TicketCanceled(Ticket ticket);

    struct Ticket{
        uint id;
        uint8[7] chosenNumbers;
        address owner;
        uint8 numbersCorrect;
    }

    modifier raffleNotStarted(){
        require(!done, "raffle has finished");
        _;
    }

    modifier raffleDone(){
        require(done, "raffle has not finished yet");
        _;
    }

    modifier onlyOrganiser(){
        require(organiser == msg.sender, "you're not the organiser");
        _;
    }

    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ) public
    {
        organiser = msg.sender;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    //ticket must be bought before the raffle started, you enter 7 numbers between 1 and 39 as an array (format [x,x,x,x,x,x,x])
    function buyTicket(uint8[7] memory chosenNumbers) public payable raffleNotStarted returns (uint){

        require (msg.value >= ticketPrice);

        for (uint i = 0; i < 7; i++){
            require (chosenNumbers[i] > 0 || chosenNumbers[i] < 40);
            for (uint j = 0; j < 7; j++){
                if (i != j){
                    if (chosenNumbers[i] == chosenNumbers[j]){
                        revert("Two same numbers");
                    }
                }
            }
        }
        //if you sent more money than the ticket price you can withdraw after the round is over
        //ideas - either enable withdrawals before the raffle has ended or create another mapping and another method for returning overpaid funds
        pendingWithdrawals[msg.sender] += (msg.value - ticketPrice);

        Ticket memory ticket = Ticket(currId++, chosenNumbers, msg.sender, 0);
        tickets.push(ticket);
        aggregatePaid += ticketPrice;

        emit TicketBought(ticket);

        return ticket.id;
    }

    function startRaffle() onlyOrganiser raffleNotStarted public{
        //pull random numbers and put them in resultNumbers
        //check totalfunds and calculate 95% to be given back to winners
        //set done to true
        //do event
        /*
        resultNumbers.push(5);
        resultNumbers.push(9);
        resultNumbers.push(12);
        resultNumbers.push(13);
        resultNumbers.push(23);
        resultNumbers.push(25);
        resultNumbers.push(35);
        */
        resultNumbers.push(uint8(convert(getRandomNumber(1))));
        resultNumbers.push(uint8(convert(getRandomNumber(2))));
        resultNumbers.push(uint8(convert(getRandomNumber(3))));
        resultNumbers.push(uint8(convert(getRandomNumber(4))));
        resultNumbers.push(uint8(convert(getRandomNumber(5))));
        resultNumbers.push(uint8(convert(getRandomNumber(6))));
        resultNumbers.push(uint8(convert(getRandomNumber(7))));
        //TODO need proper conversion, transforming it between 1 and 39 and checking if they are not the same;

        for (uint i = 0; i < tickets.length; i++){
            uint8 counter = 0;
            for (uint8 j = 0; j < 7; j++){
                for (uint8 k = 0; k < 7; k++){
                    if (i != j){
                        if (tickets[i].chosenNumbers[j] == resultNumbers[k]){
                            counter += 1;
                        }
                    }
                }
                tickets[i].numbersCorrect = counter;
                numberOfWinningTicketsByCorrectNumber[counter] += 1;
            }
        }
        //30% go to 7 hits, 20% go to 6 hits, 15% go to 5 hits, 10% go to 4 hits, 20% go to 3 hits
        winningAmountByCorrectNumber[3] = (aggregatePaid / 100 * 20) / (numberOfWinningTicketsByCorrectNumber[3] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[3]);
        winningAmountByCorrectNumber[4] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[4] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[4]);
        winningAmountByCorrectNumber[5] = (aggregatePaid / 100 * 15) / (numberOfWinningTicketsByCorrectNumber[5] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[5]);
        winningAmountByCorrectNumber[6] = (aggregatePaid / 100 * 20) / (numberOfWinningTicketsByCorrectNumber[6] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[6]);
        winningAmountByCorrectNumber[7] = (aggregatePaid / 100 * 30) / (numberOfWinningTicketsByCorrectNumber[7] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[7]);

        for (uint i = 0; i < tickets.length; i++){
            pendingWithdrawals[tickets[i].owner] += winningAmountByCorrectNumber[tickets[i].numbersCorrect];
        }

        done = true;
        emit NumbersDrawn(resultNumbers);


    }



    function withdrawWinnings() public payable raffleDone{
        uint amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }

    /**
   * Requests randomness from a user-provided seed
   */
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function convert(bytes32 b) private pure returns(uint) {
        return uint(b);
    }

}
