pragma solidity ^0.8.2;

contract Lotto {

    Ticket[] tickets;

    mapping(uint => Ticket) ticketsById;

    mapping(uint8 => uint) winningAmountByNumbersCorrect;

    uint currId = 1;

    //address public lottoOrgFunds;

    address organiser;

    bool public done = false;

    uint256 public ticketPrice = 0.1 ether;

    uint8[7] public resultNumbers;

    event TicketBought(Ticket ticket);

    event TicketPaidOut(Ticket ticket, uint amount);

    event NumbersDrawn(uint[7] resultNumbers);

    event TicketCanceled(Ticket ticket);

    struct Ticket {
        uint id;
        uint8[] chosenNumbers;
        address payable owner;
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

    function buyTicket(uint8[7] memory chosenNumbers) public payable raffleNotStarted returns (uint){
        //check if balance is over 0.1 ether
        //check if numbers are different, check if all of them are between 1 and 39
        //create new Ticket, put in tickets and in ticketsById
        //do event

    }

    function startRaffle() onlyOrganiser raffleNotStarted public {
        //pull random numbers and put them in resultNumbers
        //check totalfunds and calculate 95% to be given back to winners
        //set done to true
        //do event
    }

    function cancelTicket(uint id) public raffleNotStarted {
        //check if id exists, check if ticket.address matches msg.sender
        //do event
    }


    function payOutTicket(uint id) public raffleDone {
        //check if msg.sender equals id, then msg.transfer amount of funds from winningAmountByNumbersCorrect
        //do event
    }

    function randomGen(uint seed) private returns (uint randomNumber) {
        //generate random number from 1 to 39
    }
}
