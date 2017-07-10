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
        address to; //who recieved the votes
        uint256 toIndex; //the position in the mapping of reciever
        mapping (uint256 => address) fromIndex; //indexes of delegators
        uint256 fromLength; //total delegators
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
        address _oldTo = delegations[_from].to; //the delegation to be undone
        if(_oldTo != 0x0) { // _from was delegating?
            uint256 _oldToIndex = delegations[_from].toIndex; //msg.sender index in Delegator from list.
            delegations[_oldTo].fromLength--; //decrement _oldTo from index size
            if(_oldToIndex < delegations[_oldTo].fromLength)
                delegations[_oldTo].fromIndex[_oldToIndex] = delegations[_oldTo].fromIndex[delegations[_oldTo].fromLength]; //put latest index in place of msg.sender position
            delete delegations[_oldTo].fromIndex[delegations[_oldTo].fromLength]; //clear impossible position;
        }
        
        delegations[_from].to = _to; //register where our delegation is going
        if(_to != 0x0) { //_to is an account?
            uint256 newPos = delegations[_to].fromLength;
            delegations[_to].fromIndex[newPos] = _from; //add account into stack mapped to length
            delegations[_from].toIndex = newPos; //register the index of our address delegation (for mapping clean)
            delegations[_to].fromLength++; //increment _to from index size
        } else {
            delegations[_from].toIndex = 0; //reset index
        }
        
    }
    
    //returns the votes a account delegates
    function _votesDelegatedTo(address _who, MiniMeToken _token, uint _block)
     internal
     constant returns(uint256 total) {
        total = _token.balanceOfAt(_who,_block); // source of _who votes
        for(uint256 i = 0; delegations[_who].fromLength > i;i++)  
            total += _votesDelegatedTo(delegations[_who].fromIndex[i], _token, _block); //sum the from delegation votes
    }


}