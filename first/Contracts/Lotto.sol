pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT
contract Lotto{

    uint public aggregatePaid;

    bool public done = false;

    uint256 public ticketPrice = 0.1 ether;

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

    event TicketCanceled(Ticket ticket);

    struct Ticket{
        uint id;
        uint8[7] chosenNumbers;
        address owner;
    }

    modifier raffleNotStarted(){
        assert(!done);
        _;
    }

    modifier raffleDone(){
        assert(done);
        _;
    }

    modifier onlyOrganiser(){
        require(organiser == msg.sender);
        _;
    }

    constructor(){
        organiser = msg.sender;
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

        Ticket memory ticket = Ticket(currId++, chosenNumbers, msg.sender);
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
        resultNumbers.push(5);
        resultNumbers.push(9);
        resultNumbers.push(12);
        resultNumbers.push(13);
        resultNumbers.push(23);
        resultNumbers.push(25);
        resultNumbers.push(35);

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
                numberOfWinningTicketsByCorrectNumber[counter] += 1;
            }
        }
        //30% go to 7 hits, 20% go to 6 hits, 15% go to 5 hits, 10% go to 4 hits, 20% go to 3 hits
        winningAmountByCorrectNumber[3] = (aggregatePaid / 100 * 20) / numberOfWinningTicketsByCorrectNumber[3];
        winningAmountByCorrectNumber[4] = (aggregatePaid / 100 * 10) / numberOfWinningTicketsByCorrectNumber[4];
        winningAmountByCorrectNumber[5] = (aggregatePaid / 100 * 15) / numberOfWinningTicketsByCorrectNumber[5];
        winningAmountByCorrectNumber[6] = (aggregatePaid / 100 * 20) / numberOfWinningTicketsByCorrectNumber[6];
        winningAmountByCorrectNumber[7] = (aggregatePaid / 100 * 30) / numberOfWinningTicketsByCorrectNumber[7];

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
            }
            pendingWithdrawals[tickets[i].owner] += winningAmountByCorrectNumber[counter];
        }

        done = true;
        emit NumbersDrawn(resultNumbers);
    }



    function withdrawWinnings() public payable raffleDone{
        uint amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }




}
