pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";

// SPDX-License-Identifier: MIT


contract Lotto is VRFConsumerBase{
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function linkBalance() public view returns (uint256){
        return LINK.balanceOf(address(this));
    }

    uint8 public numberCounter = 0;

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

    uint8[] numberDrum;

    function getResultNumbers() public raffleDone view returns (uint8[7] memory) {
        return resultNumbers;
    }

    event TicketBought(Ticket ticket);

    event NumbersDrawn(uint8[7] resultNumbers);

    event Withdrawal(address winner, uint amount);

    event TicketCanceled(Ticket ticket);

    event NumberDrawn(uint8 numberDrawn);

    struct Ticket{
        uint id;
        uint8[7] chosenNumbers;
        address owner;
        uint8 numbersCorrect;
    }

    modifier raffleNotStarted(){
        require(!done && numberCounter == 0, "raffle has finished");
        _;
    }

    modifier numbersDrawn(){
        require(numberCounter == 7, "not 7 numbers pulled");
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

    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ) public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        organiser = msg.sender;
        for (uint8 i = 1; i < 40; i++){
            numberDrum.push(i);
        }
    }


    //ticket must be bought before the raffle started, you enter 7 numbers between 1 and 39 as an array (format [x,x,x,x,x,x,x])
    function buyTicket(uint8[7] memory chosenNumbers) public payable raffleNotStarted validNumbers(chosenNumbers) returns (uint){

        require (msg.value >= ticketPrice);

        //if you sent more money than the ticket price you can withdraw after the round is over
        //ideas - either enable withdrawals before the raffle has ended or create another mapping and another method for returning overpaid funds
        pendingWithdrawals[msg.sender] += (msg.value - ticketPrice);

        Ticket memory ticket = Ticket(currId++, chosenNumbers, msg.sender, 0);
        tickets.push(ticket);
        aggregatePaid += ticketPrice;

        emit TicketBought(ticket);

        return ticket.id;
    }

    function startRaffle() onlyOrganiser numbersDrawn public{


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

    function getRandomNumber(uint256 userProvidedSeed) public onlyOrganiser returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");

        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        if (numberCounter < 7){
            uint8 numberPick = uint8((randomResult % (numberDrum.length-1)) + 1);
            uint8 resultNumber = numberDrum[numberPick];
            numberDrum[numberPick] = numberDrum[numberDrum.length-1];
            numberDrum.pop();

            resultNumbers[numberCounter++] = resultNumber;
        }


    }


    function withdrawLink() external payable onlyOrganiser{
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }


}
