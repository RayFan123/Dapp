// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SubwayBid {
    uint public start_value;
    uint public ontime_value;
    uint public late_value;
    address payable public starter;
    address payable[] public ontime_bidders;
    address payable[] public late_bidders;
    mapping (address => uint) private validaty;
    mapping (address => uint) private confirm_list;
    uint public confirmation;
    uint public bidder_number;
    bool [] private consensus; 
    uint public confirm_num;
    uint public index=1;

    enum State { Bidding ,Locked, ConfirmReceived , Release, Inactive }
    State public state;

    /// The function cannot be called at the current state.
    error InvalidState();

    /// Only the starter can call this function.
    error OnlyStarter();

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    modifier correct_input(uint ind) {
        require(ind == 0 || ind == 1);
        _;
    }

    modifier inState(State state_) {
        if (state != state_)
            revert InvalidState();
        _;
    }

    modifier onlyStarter() {
        if (msg.sender != starter)
            revert OnlyStarter();
        _;
    }

    constructor() payable condition(msg.value >= 10) {

        starter = payable(msg.sender);
        start_value = msg.value;

    }

    function Bid(uint ind) external inState(State.Bidding) condition(msg.value == start_value) 
        condition(validaty[msg.sender] == 0)payable {
        require(ind == 1 || ind == 0);
        if (ind == 1){
            ontime_bidders.push(payable(msg.sender));
            consensus.push(false);
            ontime_value += msg.value;
            validaty[msg.sender] = index;
            index += 1;
        }
        else if (ind == 0) {
            late_bidders.push(payable(msg.sender));
            late_value += msg.value;
            consensus.push(false);
            validaty[msg.sender] = index;
            index += 1;
        }
    }

    function Reveal_Arrival(uint ind) public onlyStarter inState(State.Bidding) correct_input(ind) 
        condition(ontime_bidders.length * late_bidders.length != 0){
        confirmation = ind;
        bidder_number = ontime_bidders.length + late_bidders.length;

        state = State.Locked;
    }

    function Bidder_Confirm(uint ind) public inState(State.Locked) condition(validaty[msg.sender] >= 1) 
        correct_input(ind) {
        require(confirm_list[msg.sender] == 0);
        if (ind == confirmation){
            consensus[validaty[msg.sender] - 1] = true;
        }
        confirm_num += 1;
        confirm_list[msg.sender] = 1;
        if (confirm_num == bidder_number){
            state = State.ConfirmReceived;
        }
    }

    function Starter_Confirm() public inState(State.ConfirmReceived) onlyStarter  {
        uint i;
        bool flag = true;
        for (i = 0; i< bidder_number; i ++){
            flag = flag && consensus[i];
        }
        if (flag == true){
            state = State.Release;
            payback(confirmation);
        }
        else{
            Clear();
        }

    }

    function Clear() private inState(State.ConfirmReceived) {
        uint i;
        for (i = 0; i< ontime_bidders.length; i ++){
            confirm_list[ontime_bidders[i]] = 0;
        }
        for (i = 0; i< late_bidders.length; i ++){
            confirm_list[late_bidders[i]] = 0;
        }
        for (i = 0; i< bidder_number; i ++){
            consensus [i] = false;
        }
        confirm_num = 0;
        state = State.Locked;
    }

    function payback(uint ind) inState(State.Release) private {
        if (ind == 1){
            uint i;
            starter.transfer(start_value/3);
            for (i = 0; i< ontime_bidders.length; i ++){
                ontime_bidders[i].transfer((start_value / 3 + late_value + ontime_value) / ontime_bidders.length);
            }
            for (i = 0; i< late_bidders.length; i ++){
                late_bidders[i].transfer(start_value / 3  / late_bidders.length);
            }
        }
        else if (ind == 0){
            uint i;
            starter.transfer(start_value + ontime_value/3);
            for (i = 0; i< ontime_bidders.length; i ++){
                ontime_bidders[i].transfer(ontime_value / 3 / ontime_bidders.length);
            }
            for (i = 0; i< late_bidders.length; i ++){
                late_bidders[i].transfer((late_value + ontime_value / 3  )/ late_bidders.length);
            }
        }
        state = State.Inactive;
    }

}
