pragma solidity ^0.8.2;



contract Lotto{

    Ticket[] tickets;
    address organiser;
    uint currId = 1;
    bool ended = false;
    int[7] resultNumbers;

    struct Ticket{
        uint id;
        int[7] chosenNumbers;
        address buyer;
    }

    mapping(uint => Ticket) ticketsById;

    constructor(address  _organiser){
        organiser = _organiser;
    }

    function buyTicket(int first, int second, int third, int fourth, int fifth, int sixth, int seventh) public payable returns (uint){
        if (ended){
            return 0;
        }
        int[7] memory testingNumbers;
        testingNumbers[0] = first;
        testingNumbers[1] = second;
        testingNumbers[2] = third;
        testingNumbers[3] = fourth;
        testingNumbers[4] = fifth;
        testingNumbers[5] = sixth;
        testingNumbers[6] = seventh;
        /*
        for (uint i = 0; i < 7; i++){
            if (testingNumbers[i] > 39 || testingNumbers[i] < 1){
                return 0;
            }
            for (uint j = 0; j < 7; j++){

                if (i != j){
                    if (testingNumbers[i] == testingNumbers[j]){
                        return 0;
                    }
                }
            }
        }
        */
        uint _id = currId++;

        Ticket memory ticket = Ticket(_id, testingNumbers, msg.sender);
        tickets[_id] = ticket;
        return ticket.id;
    }

    function startRaffle() public{
        if (msg.sender == organiser){
            ended = true;
            resultNumbers[0] = 3;
            resultNumbers[1] = 12;
            resultNumbers[2] = 13;
            resultNumbers[3] = 21;
            resultNumbers[4] = 30;
            resultNumbers[5] = 36;
            resultNumbers[6] = 38;
        }
    }

    function checkTicket(uint id) public view returns (int){
        int ctr = 0;
        Ticket memory ticket = tickets[id];
        if (ended){
            for (uint i = 0; i < 7; i++){
                for (uint j = 0; j < 7; j++){
                    if (ticket.chosenNumbers[i] == resultNumbers[j]){
                        ctr++;
                    }
                }
            }
            return ctr;

        }else{
            return -1;

        }
    }


}
