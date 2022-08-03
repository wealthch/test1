/**
 *Submitted for verification at BscScan.com on 2026-07-22
*/

/**
 *Website: https://bnbcapital.finance
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15 ; 

contract SuperBnB{
    uint256 private DIVIDEND_YIELD=129600;
    bool private isInitialized=false;
    address private mngmAddress;
    uint256 private investorsCount;

    struct Investor { 
      uint256 investedAmount;  
      uint256 sharesAmount;
      uint256 dividendsCurrent;
      uint256 dividendsReInvested;
      uint256 dividendsWithdrawn;
      uint256 lastDividendDate;
      uint256 entraneDate;
      bool isValue;
    }
    mapping (address => Investor) private investors;
    
    constructor() {
        mngmAddress=address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    }

    function reinvestDividends() public{
        require(isInitialized);

        Investor storage  _investor = investors[msg.sender];

        if (!_investor.isValue){
            return;
        }
        _investor.dividendsCurrent = SafeMath.add(_investor.dividendsCurrent ,calculateCurrentDividends(_investor.sharesAmount, _investor.lastDividendDate));
        _investor.dividendsReInvested = SafeMath.add(_investor.dividendsReInvested,_investor.dividendsCurrent);
        _investor.sharesAmount = SafeMath.add(_investor.sharesAmount,_investor.dividendsCurrent);    
        _investor.dividendsCurrent = 0;
        _investor.lastDividendDate = block.timestamp;
    }

    function withdrawDividends() public{
        require(isInitialized);
        Investor storage  _investor = investors[msg.sender];
        if (!_investor.isValue){
            return;
        }
        _investor.dividendsCurrent = SafeMath.add(_investor.dividendsCurrent ,calculateCurrentDividends(_investor.sharesAmount, _investor.lastDividendDate));
        uint256 _balance = getBalance();
        uint256 _out = _investor.dividendsCurrent;
        require(_balance>_out, "Insufficient Balance");
        if (_out > _balance){
            _out=_balance;
        }
        totalShares = SafeMath.sub(totalShares, _out);
        _investor.dividendsWithdrawn = SafeMath.add(_investor.dividendsWithdrawn, _out);
        _investor.dividendsCurrent = 0;
        _investor.lastDividendDate = block.timestamp;
        payable(msg.sender).transfer(_out);
    }

    function buyShares(address rfl) public payable{
        require(isInitialized);
        require(msg.value>0, "Can not invest zero amount");
        uint256 _newSharesAmount=calculateSharesToBuy(msg.value);
        _newSharesAmount=SafeMath.sub(_newSharesAmount,getMngmntFees(_newSharesAmount));
        uint256 _mngmtFees=getMngmntFees(msg.value);
        payable(mngmAddress).transfer(_mngmtFees);

        Investor storage  _investor = investors[msg.sender];
        if (!_investor.isValue) {
            investorsCount = SafeMath.add(investorsCount,1);
            investors[msg.sender] = Investor(msg.value,_newSharesAmount,0,0,0,block.timestamp,block.timestamp,true);
        }
        else{
            _investor.investedAmount = SafeMath.add(_investor.investedAmount, msg.value);
            _investor.dividendsCurrent =  SafeMath.add(_investor.dividendsCurrent,calculateCurrentDividends(_investor.sharesAmount, _investor.lastDividendDate));
            _investor.sharesAmount = SafeMath.add(_investor.sharesAmount,_newSharesAmount);
            _investor.lastDividendDate = block.timestamp;
            _investor.investedAmount = SafeMath.add(_investor.investedAmount, msg.value);
        }
        if (rfl == msg.sender){
              return;
        }
        Investor storage  _referral = investors[rfl];
        if (!_investor.isValue){
            return;
        }
        _referral.dividendsCurrent =  SafeMath.add(_referral.dividendsCurrent,SafeMath.div(SafeMath.mul(msg.value,10),100));      
    }

    function calculateCurrentDividends(uint256 nShares, uint256 lastDividendDate) public view returns(uint256){
        uint256 _yied=min(SafeMath.div(DIVIDEND_YIELD,5),SafeMath.sub(block.timestamp,lastDividendDate));
        return SafeMath.div(SafeMath.mul(_yied,nShares),DIVIDEND_YIELD);
    }

    function calculateSharesToBuy(uint256 inValue) public pure returns(uint256){
        return inValue;
    }

    function getSharesAmount_(address adr) public view returns(uint256){
        Investor memory  _investor = investors[adr];
        if (!_investor.isValue){
            return 0;
        }
        return _investor.sharesAmount;
    }
    function getSharesAmount() public view returns(uint256){
        return getSharesAmount_(msg.sender);
    }
    function getPortfolioDetails_(address adr) public view returns(Investor memory){
        Investor memory  _investor = investors[adr];
        if (!_investor.isValue){
            return Investor(0,0,0,0,0,0,0,false);
        }
        _investor.dividendsCurrent =  SafeMath.add(_investor.dividendsCurrent,calculateCurrentDividends(_investor.sharesAmount, _investor.lastDividendDate));
        return _investor;
    }  
    function getPortfolioDetails() public view returns(Investor memory){
        return getPortfolioDetails_(msg.sender);
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getTotalShares() public view returns(uint256){
        return totalShares;
    }
    function getDividendYield() public view returns(uint256){
        return DIVIDEND_YIELD;
    }
    function getInvestorsCount() public view returns(uint256){
        return investorsCount;
    }
    //10% management fees
    function getMngmntFees(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);
    }

    function initialise() public payable{
        require(isInitialized==false);
        isInitialized=true;
        totalShares=0;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}