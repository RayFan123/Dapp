// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SubwayBet {
    uint public start_value;
    uint public positive_value;
    uint public negative_value;
    address payable public starter;
    address payable[] public positive_bettor;
    address payable[] public negative_bettor;
    mapping (address => uint) private validaty;
    mapping (address => uint) private confirm_list;
    uint public confirmation;
    uint public Bettor_number;
    bool [] private consensus; 
    uint public confirm_num;
    uint public index=1;

    enum State { Betting ,Locked, ConfirmReceived , Release, Inactive }
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

    function Bet(uint ind) external inState(State.Betting) condition(msg.value == start_value) 
        condition(validaty[msg.sender] == 0)payable {
        require(ind == 1 || ind == 0);
        if (ind == 1){
            positive_bettor.push(payable(msg.sender));
            consensus.push(false);
            positive_value += msg.value;
            validaty[msg.sender] = index;
            index += 1;
        }
        else if (ind == 0) {
            negative_bettor.push(payable(msg.sender));
            negative_value += msg.value;
            consensus.push(false);
            validaty[msg.sender] = index;
            index += 1;
        }
    }

    function Reveal_Arrival(uint ind) public onlyStarter inState(State.Betting) correct_input(ind) 
        condition(positive_bettor.length * negative_bettor.length != 0){
        if (positive_bettor.length * negative_bettor.length == 0){
            state = State.Inactive;
            abort_pay();
        }
        else{
            confirmation = ind;
            Bettor_number = positive_bettor.length + negative_bettor.length;
            state = State.Locked;
        }

    }

    function Bettor_confirm(uint ind) public inState(State.Locked) condition(validaty[msg.sender] >= 1) 
        correct_input(ind) {
        require(confirm_list[msg.sender] == 0);
        if (ind == confirmation){
            consensus[validaty[msg.sender] - 1] = true;
        }
        confirm_num += 1;
        confirm_list[msg.sender] = 1;
        if (confirm_num == Bettor_number){
            state = State.ConfirmReceived;
        }
    }

    function Starter_Confirm() public inState(State.ConfirmReceived) onlyStarter  {
        uint i;
        bool flag = true;
        for (i = 0; i< Bettor_number; i ++){
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
        for (i = 0; i< positive_bettor.length; i ++){
            confirm_list[positive_bettor[i]] = 0;
        }
        for (i = 0; i< negative_bettor.length; i ++){
            confirm_list[negative_bettor[i]] = 0;
        }
        for (i = 0; i< Bettor_number; i ++){
            consensus [i] = false;
        }
        confirm_num = 0;
        state = State.Locked;
    }

    function abort_pay() inState(State.Inactive) private {
        uint i;
        if (positive_bettor.length > 0){
            for (i = 0; i< positive_bettor.length; i ++){
                positive_bettor[i].transfer(start_value);
            }
        }
        if (negative_bettor.length > 0){
            for (i = 0; i< negative_bettor.length; i ++){
                negative_bettor[i].transfer(start_value);
            }
        }
        starter.transfer(start_value);
    }


    function payback(uint ind) inState(State.Release) private {
        if (ind == 1){
            uint i;
            starter.transfer(start_value/3);
            for (i = 0; i< positive_bettor.length; i ++){
                positive_bettor[i].transfer((start_value / 3 + negative_value/2 + positive_value) / positive_bettor.length);
            }
            for (i = 0; i< negative_bettor.length; i ++){
                negative_bettor[i].transfer((start_value / 3 + negative_value/2) / negative_bettor.length);
            }
        }
        else if (ind == 0){
            uint i;
            starter.transfer(start_value + positive_value/3);
            for (i = 0; i< positive_bettor.length; i ++){
                positive_bettor[i].transfer(positive_value / 3 / positive_bettor.length);
            }
            for (i = 0; i< negative_bettor.length; i ++){
                negative_bettor[i].transfer((negative_value + positive_value / 3  )/ negative_bettor.length);
            }
        }
        state = State.Inactive;
    }

}
