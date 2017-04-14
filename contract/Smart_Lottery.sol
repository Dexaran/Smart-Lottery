pragma solidity ^0.4.9;

contract SmartLottery_v2 {
    
    // Event is fired when current round ends.
    event RoundEnd(uint indexed _roundNumber);
    
    // Event is fired when a new round starts.
    event RoundStart(uint indexed _roundNumber);
    
    // Event is fired when a participant is depositing funds.
    event Deposit(address indexed _participant, uint indexed _amount);
    
    // Event is fired in same time with RoundEnd event, is showing winner of the round,
    // winner reward and a random number that was generated.
    event Winner(address indexed _winner, uint indexed _reward, uint indexed _RNGnumber);
    
    // Event is fired when bonus reward is paid.
    event BonusReward(uint _amount);
    
    
    modifier onlydebug { if (debugging_enabled) _; }
    modifier onlyowner { if (msg.sender == owner) _; }
    
    struct Participant {
        address addr;
        uint deposit;
        uint winning_number;
    }
    
    // Owner of the contract.
    address public owner;
    
    // Index of current round.
    uint public currentRound=0;
    
    // Number of current round participants.
    uint public round_participants_count=0;
    
    // Is round currently enabled or it will start when the first deposit occurs.
    bool round_enabled=true;
    
    // Will bonus reward be paid at the end of current round or not.
    bool bonusRound=false;
    
    // Amount of funds in percents that are not paid as round end reward and are held
    // as lottery comission. This funds are divided to bonus rewards to be paid in future rounds
    // and devFee that will be paid to lottery creator.
    uint public haltedFunds = 10; // 10 %
    
    // Amount of money in percents that would be paid to lottery creator.
    uint public devFee = 5; // 5 %
    
    // A number of participants in current round.
    Participant[] public participants;
    
    // Variable to allow/disallow debugging functions.
    bool public debugging_enabled=true;
    
    // A number of start block of current round.
    uint public roundStart=0;
    
    // How many blocks will each round be.
    uint public roundInterval=2500;
    
    // A number of end block of current round.
    uint public roundEnd=roundStart+roundInterval;
    
    // Random number that is generated for current round.
    uint RNG_entry=631817202;
    
    // Maximal RNG entry to be generated.
    uint RNG_max=0;
    
    // Minimal deposit amount that participant need to deposit to take part in round.
    uint public min_value=10; //10WEI
    
    // Special reward that will be paid to a person who ends lottery round
    // round end requires a lot of calculations so it need a lot of gas
    // roundEndReward payment is a kind of refunding for paid gas (currently disabled)
    uint public roundEndReward=0;//200000000000000000 to give 0.2 Ether 
    
    // Address that will be paid as winner.
    address winner=0x0;
    
    // Will be paid to a winner of round.
    uint reward;
    
    // Bonus reward that will be paid to a winner of bonus round.
    uint bonus=0;
    
    //
    //Participant TMP_participant;
    
    // Returns index of current round if round is enabled.
    // Throws an error when round was ended but new one was not started.
    function getRoundNumber() constant returns (uint _roundNumber) {
        if(round_enabled) {
            return currentRound;
        }
        else {
            throw;
        }
    }
    
    // Returns start block of last roud.
    function getStartBlock() constant returns (uint _startBlock) {
        return roundStart;
    }
    
    // Returns end block of last round.
    function getEndBlock() constant returns (uint _endBlock) {
        return roundEnd;
    }
    
    // Returns round reward.
    // WARNING! Only 90% of this reward would be paid to round winner.
    // 5% is current bonus round reward
    // 5% is dev fee
    function getRoundReward() constant returns (uint _reward) {
        return reward;
    }
    
    // Returns bonus reward. It will be fully paid to bonus round winner.
    function getBonusReward() constant returns (uint _bonus) {
        return bonus;
    }
    
    // Returns status of current round.
    function getRoundEnabedStatus() constant returns (bool _enabled) {
        return round_enabled;
    } 
    
    // This function is executed on each default transaction with no function calls.
    function() payable {
        if(msg.value>min_value) {
            if(block.number>=roundEnd) {
                if(round_enabled) endRound();
                stardRound();
            }
        Participant memory TMP_participant;
        TMP_participant.addr=msg.sender;
        TMP_participant.deposit=msg.value;
        participants.push(TMP_participant);
        reward+=msg.value;
        round_participants_count++;
        Deposit(msg.sender, msg.value);
        }
        else {
            throw;
        }
    }
    
    // A special function to give lottery funds.
    function Donate() payable{
        
    }
    
    // Function that is triggered on each round end.
    function endRound(){
        if((block.number>=roundEnd)&&round_enabled)
        {
            round_enabled=false;
        if(participants.length>0)
        {
        	winner = Calculate();
            reward=reward-(reward/haltedFunds);
            if(bonusRound) {
                reward+=bonus;
                BonusReward(bonus);
                bonus=0;
            }
        	
            //prepare to new round if the winner is paid
            if(winner.send(reward) && owner.send(reward/(100/devFee)))
            {
                bonus+=this.balance;
                RoundEnd(currentRound);
                Winner(winner, reward, RNG_entry);
            }
            if(roundEndReward>0){
                bool resultOK = msg.sender.send(roundEndReward);
            }
        }
        }
        else{
            throw;
        }
    }
    
    // Function that is triggered on each new round start.
    function stardRound() private {
        if(roundStart<block.number){
            roundStart=block.number+1;
        }
        if(RNG(5)==1) {
            bonusRound=true;
        }
        else {
            bonusRound=false;
        }
        
        round_enabled=true;
        round_participants_count=0;
        delete participants;
        currentRound++;
        roundEnd=roundStart+roundInterval;
        reward=0;
        RNG_entry=0;
        RNG_max=0;
        winner=0;
        RoundStart(currentRound);
    }
    
    // Calculate round winner.
    function Calculate() private constant returns(address _winner){
        
        uint win_number_condition=0;
        RNG_max=reward;
        for(uint x = 0; x < participants.length; x++)
        	{
        	    participants[x].winning_number=win_number_condition+participants[x].deposit;
        	    win_number_condition+=participants[x].deposit;
        	}
        	
        RNG_entry=RNG(RNG_max);
        uint8 i=0;
        while(winner==0)
        {
            if(RNG_entry<=participants[i].winning_number)
            {
                winner=participants[i].addr;
                return participants[i].addr;
            }
            i++;
        }
        delete i;
    }
    
    // Function that is returning random number based on hash timestamp/difficulty
    function RNG(uint256 max) constant private returns (uint RNGoutput)
    {
        bytes32 tmp_hash0 = sha256(block.timestamp);
        bytes32 tmp_hash1 = sha256(block.difficulty);
        bytes32 tmp_hash2 = sha256(block.number);
        bytes32 tmp_hash3 = tmp_hash1&tmp_hash0;
        bytes32 tmp_hash4=sha256(msg.sender);
        uint256 tmp0=uint256(tmp_hash0);
        uint256 tmp1=uint256(tmp_hash1);
        uint256 tmp2=uint256(tmp_hash2);
        uint256 tmp3=uint256(tmp_hash3);
        uint256 tmp4=uint256(tmp_hash4);
        
        RNGoutput=tmp0+tmp1-tmp2+tmp3-tmp4;
        if(max==0)
        {
            return RNGoutput=0;
        }
        while(RNGoutput>max)
        {
           RNGoutput=RNGoutput%(max+1);
        }
        return RNGoutput;
    }
    
    
    
    // DEBUGGING FUNCTIONS //
    
    function Debugging_ForceCalculate() onlyowner onlydebug
    {
        	Calculate();
    }
    
    function Debugging_Set_RoundEnd(uint roundEndTmp) onlyowner onlydebug
    {
        roundEnd=roundEndTmp;
    }
    
    function Debugging_Set_RoundStart(uint roundStartTmp) onlyowner onlydebug
    {
        roundStart=roundStartTmp;
    }
    
    function Debugging_Set_RoundInterval(uint roundIntervalTmp) onlyowner onlydebug
    {
        roundInterval=roundIntervalTmp;
    }
    
    function Debugging_Set_MinValue(uint minValue) onlyowner onlydebug
    {
        min_value=minValue;
    }
    
    function Debugging_Set_RoundEndReward(uint _end_reward) onlyowner onlydebug
    {
        roundEndReward=_end_reward;
    }
    
    function Debugging_SendMeAll() onlyowner onlydebug
    {
       msg.sender.send(this.balance-10000);
    }
    
    function TurnOffDebugging() onlyowner onlydebug
    {
        debugging_enabled=false;
    }
    
    function kill() onlyowner onlydebug{
    if (msg.sender == owner) suicide(owner); 
  }
}
