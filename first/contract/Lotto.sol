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

    uint8[7] resultNumbers;

    function getResultNumbers() public raffleDone view returns (uint8[7] memory) {
        return resultNumbers;
    }

    event TicketBought(Ticket ticket);

    event NumbersDrawn(uint8[7] resultNumbers);

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

    modifier validNumbers(uint8[7] memory chosenNumbers){
        require(validateNumbers(chosenNumbers), "failed validation");
        _;
    }

    constructor(){
        organiser = msg.sender;
    }


    //ticket must be bought before the raffle started, you enter 7 numbers between 1 and 39 as an array (format [x,x,x,x,x,x,x])
    function buyTicket(uint8[7] memory chosenNumbers) public payable raffleNotStarted validNumbers(chosenNumbers) returns (uint){

        require (msg.value >= ticketPrice);

        /*
        first went with for loop (7**2 operations) , then outer function with ~30 operations, then called that function inside modifier
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

        require(validateNumbers(chosenNumbers), "did not pass number validation");
        */


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
        //set 7 random numbers until they are valid
        /*
        do{
            resultNumbers[0] = 1;
            resultNumbers[1] = 2;
            resultNumbers[2] = 3;
            resultNumbers[3] = 4;
            resultNumbers[4] = 5;
            resultNumbers[5] = 6;
            resultNumbers[6] = 7;
        }while(validateNumbers(resultNumbers));
        */
        resultNumbers[0] = 1;
        resultNumbers[1] = 2;
        resultNumbers[2] = 3;
        resultNumbers[3] = 4;
        resultNumbers[4] = 5;
        resultNumbers[5] = 6;
        resultNumbers[6] = 7;
        //require(validateNumbers(resultNumbers), "did not pass number validation");

        for (uint i = 0; i < tickets.length; i++){
            uint8 counter = 0;
            for (uint8 j = 0; j < 7; j++){
                for (uint8 k = 0; k < 7; k++){
                    if (i != j){
                        if (tickets[i].chosenNumbers[j] == resultNumbers[k]){
                            counter += 1;
                            break;
                        }
                    }
                }
                tickets[i].numbersCorrect = counter;
                numberOfWinningTicketsByCorrectNumber[counter] += 1;
            }
        }

        winningAmountByCorrectNumber[3] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[3] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[3]);
        winningAmountByCorrectNumber[4] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[4] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[4]);
        winningAmountByCorrectNumber[5] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[5] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[5]);
        winningAmountByCorrectNumber[6] = (aggregatePaid / 100 * 20) / (numberOfWinningTicketsByCorrectNumber[6] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[6]);
        winningAmountByCorrectNumber[7] = (aggregatePaid / 100 * 45) / (numberOfWinningTicketsByCorrectNumber[7] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[7]);

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

    function validateNumbers(uint8[7] memory numbers) private pure returns (bool){
        if (numbers.length != 7) return false;

        if (numbers[0] > 39 || numbers[0] < 1) return false;
        if (numbers[1] > 39 || numbers[1] < 1) return false;
        if (numbers[2] > 39 || numbers[2] < 1) return false;
        if (numbers[3] > 39 || numbers[3] < 1) return false;
        if (numbers[4] > 39 || numbers[4] < 1) return false;
        if (numbers[5] > 39 || numbers[5] < 1) return false;
        if (numbers[6] > 39 || numbers[6] < 1) return false;

        if (numbers[0] == numbers[1] || numbers[0] == numbers[2] || numbers[0] == numbers[3] || numbers[0] == numbers[4] || numbers[0] == numbers[5] || numbers[0] == numbers[6] ||
        numbers[1] == numbers[2] || numbers[1] == numbers[3] || numbers[1] == numbers[4] || numbers[1] == numbers[5] || numbers[1] == numbers[6] ||
        numbers[2] == numbers[3] || numbers[2] == numbers[4] || numbers[2] == numbers[5] || numbers[2] == numbers[6] ||
        numbers[3] == numbers[4] || numbers[3] == numbers[5] || numbers[3] == numbers[6] ||
        numbers[4] == numbers[5] || numbers[4] == numbers[6] || numbers[5] == numbers[6] ){
            return false;
        }

        return true;
    }


}
