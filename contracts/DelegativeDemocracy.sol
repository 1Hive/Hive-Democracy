import "./minime/MiniMeToken.sol";
pragma solidity ^0.4.11;

/**
 * @title DelegativeDemocracy
 * @author Ricardo Guilherme Schmidt
 * Is an abstract contract to issue delegateable votes from a source _votesSource; 
 */
contract DelegativeDemocracy {
    
    mapping (address => Delegation) public delegations;
    event Delegate(address who, address to);
    
    struct Delegation {
        address to; //who recieved the delegaton
        uint256 toIndex; //index in from array of `to`
        address[] from; //who is delegation
    }
    
    //returns the destination of an account's votes
    function delegationOf(address _who)
     constant returns(address) {
        if(delegations[_who].to != 0x0) //_who is delegating?
            return delegationOf(delegations[_who].to); //load the delegation of _who delegation
        else
            return _who; //reached the endpoint of delegation
    }  
    
    //returns the voting power of an account
    function influenceOf(address _who, MiniMeToken _token, uint _block)
     constant returns(uint256) {
        if(delegations[_who].to == 0x0) //is endpoint of delegation?
            return _votesDelegatedTo(_who, _token, _block); //calcule the votes delegated to _who
        else return 0; //no votes: were delegated
    }   
    
    //changes the delegation of an account, if _to 0x00: self delegation (become voter)
    function delegate(address _to) {
        address _from = msg.sender;
        require(delegationOf(_to) != _from); //block impossible circular delegation
        Delegate(_from,_to);

        //Removes from delegation 'receiver' the address listed there.
        Delegation storage from = delegations[_from];
        address _oldTo = from.to; //the delegation to be undone
        if(_oldTo != 0x0) { // _from was delegating?
            uint256 _oldToIndex = delegations[_from].toIndex; //msg.sender index in Delegator from list.
            Delegation storage oldTo = delegations[_oldTo];
            oldTo.from[_oldToIndex] = oldTo.from[oldTo.from.length - 1];
            oldTo.from.length--;
        }
        
        //Add the new delegation
        from.to = _to; //register where our delegation is going
        if(_to != 0x0) { //_to is an account?
            Delegation storage to = delegations[_to];
            from.toIndex = to.from.length; //register the index of our address delegation (for mapping clean)
            to.from.push(_from);
        } else {
            from.toIndex = 0; //reset index
        }
        
    }
    
    //returns the votes a account delegates
    function _votesDelegatedTo(address _who, MiniMeToken _token, uint _block)
     internal
     constant returns(uint256 total) {
        total = _token.balanceOfAt(_who, _block); // source of _who votes
        address[] memory _from = delegations[_who].from;
        uint _len = _from.length;
        for(uint256 i = 0; _len > i; i++)  
            total += _votesDelegatedTo(_from[i], _token, _block); //sum the from delegation votes
    }


}