pragma solidity ^0.4.9;

contract SmartLottery_v2 {
    
    mapping (address => uint) public balanceOf;
    
    event RoundEnd(uint indexed _roundNumber);
    event RoundStart(uint indexed _roundNumber);
    event Deposit(address indexed _participant, uint indexed _amount);
    event Winner(address indexed _winner, uint indexed _reward, uint indexed _RNGnumber);
    event BonusReward(uint _amount);
    
    address public owner;
    string public Fee='10 %';
    uint public currentRound=0;
    uint public round_pretendents_count=0;
    bool round_enabled=true;
    bool bonusRound=false;
    
    struct Pretendent {
        address addr;
        uint deposit;
        uint winning_number;
    }
    
    modifier onlydebug { if (debugging_enabled) _; }
    modifier onlyowner { if (msg.sender == owner) _; }
    
    Pretendent[] public pretendents;
    
    bool public debugging_enabled=true;
    uint public roundStart=0;
    uint public roundInterval=2500;
    uint public roundEnd=roundStart+roundInterval;
    uint RNG_entry=631817202;
    uint RNG_max=0;
    uint public min_value=10; //0.95 ETC //10WEI
    uint public roundEndReward=0;//200000000000000000 to give 0.2 Ether 
    address winner=0;
    uint reward; //public 
    uint bonus=0;
    Pretendent TMP_pretendent;
    
    
    function getRoundNumber() constant returns (uint _roundNumber) {
        return currentRound;
    }
    function getStartBlock() constant returns (uint _startBlock) {
        return roundStart;
    }
    function getEndBlock() constant returns (uint _endBlock) {
        return roundEnd;
    }
    function getRoundReward() constant returns (uint _reward) {
        return reward;
    }
    function getBonusReward() constant returns (uint _bonus) {
        return bonus;
    }
    function getRoundEnabedStatus() constant returns (bool _enabled) {
        return round_enabled;
    } 
    
    function() payable {
        if(msg.value>min_value) {
            if(block.number>=roundEnd) {
                if(round_enabled) endRound();
                stardRound();
            }
        TMP_pretendent.addr=msg.sender;
        TMP_pretendent.deposit=msg.value;
        pretendents.push(TMP_pretendent);
        reward+=msg.value;
        round_pretendents_count++;
        Deposit(msg.sender, msg.value);
        }
        else {
            throw;
        }
    }
    
    function Donate() payable{
        
    }
    
    function endRound(){
        if((block.number>=roundEnd)&&round_enabled)
        {
            round_enabled=false;
        if(pretendents.length>0)
        {
        	winner = Calculate();
            reward=reward-reward/10;
            if(bonusRound) {
                reward+=bonus;
                BonusReward(bonus);
                bonus=0;
            }
        	
            //prepare to new round if the winner is paid
            if(winner.send(reward) && owner.send(reward/20))
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
        round_pretendents_count=0;
        delete pretendents;
        currentRound++;
        roundEnd=roundStart+roundInterval;
        reward=0;
        RNG_entry=0;
        RNG_max=0;
        winner=0;
        RoundStart(currentRound);
    }
    
    function Calculate() private constant returns(address _winner){
        
        uint win_number_condition=0;
        RNG_max=reward;
        for(uint x = 0; x < pretendents.length; x++)
        	{
        	    pretendents[x].winning_number=win_number_condition+pretendents[x].deposit;
        	    win_number_condition+=pretendents[x].deposit;
        	}
        	
        RNG_entry=RNG(RNG_max);
        uint8 i=0;
        while(winner==0)
        {
            if(RNG_entry<=pretendents[i].winning_number)
            {
                winner=pretendents[i].addr;
                return pretendents[i].addr;
            }
            i++;
        }
        delete i;
    }
    
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
