// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/crowdsale/Crowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRoles {
    function isPrivateWhitelisted(address _beneficiary) external view returns (bool);
}

interface IVesting {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) external;
}

contract PrivateSale is
    Crowdsale,
    TimedCrowdsale,
    CappedCrowdsale,
    Ownable
{
    //CONSTANTES
    uint256 public constant lockTime = 1 hours; 
    uint256 public constant vestingTime = 6 hours;
    uint256 public constant vestingStart = 1650632400; 
    //uint256 public constant tokensForSell = 50000000000000000000000000;
    uint256 public constant minInvestment = 100000000000000000;
    uint256 public constant maxInvestment = 1000000000000000000;

    mapping(address => uint256) private alreadyInvested;
    //mapping(address => uint256) private boughtTokens;

    IVesting private _vestingContract;
    IRoles private _roles;

    // Set rate, token to be selled, collector wallet, opening and closing time for the ICO
    constructor(
        uint256 rate,
        address payable wallet,
        ERC20 token,
        uint256 openingTime,
        uint256 closingTime,
        uint256 cap,
        address roles_,
        address vestingContract_
    )
        public
        Crowdsale(rate, wallet, token)
        TimedCrowdsale(openingTime, closingTime)
        CappedCrowdsale(cap)
    {
        _roles = IRoles(roles_);
        _vestingContract = IVesting(vestingContract_);
    }

    // Extend parents behavior to let all addresses buy in public sale
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal view
    {
        require(_roles.isPrivateWhitelisted(_beneficiary), "Address not whitelisted");
        super._preValidatePurchase(_beneficiary, _weiAmount);
        uint256 _existingContribution = alreadyInvested[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        require(_newContribution >= minInvestment && _newContribution <= maxInvestment);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);
        alreadyInvested[beneficiary] += weiAmount;
    }
    
    // Extend closing time for the ICO
    function extendTime(uint256 newClosingTime) external onlyOwner {
        super._extendTime(newClosingTime);
    }

    function _processPurchase(address _beneficiary, uint256 amount) internal {
        _vestingContract.createVestingSchedule(_beneficiary, vestingStart, lockTime, vestingTime, 1, true, amount);
        //boughtTokens[_beneficiary] += amount;
    }

/*     function withdrawTokens(address _beneficiary) external {
        require(hasClosed(), "Crowdsale has not finalized");
        require( boughtTokens[_beneficiary] > 0, "Must have tokens bought");
        uint256 amount = boughtTokens[_beneficiary];
        boughtTokens[_beneficiary] = 0;
        _vestingContract.createVestingSchedule(_beneficiary, vestingStart, lockTime, vestingTime, 1, true, amount);
    }
 */
    function getVestingContract() external view returns(address){
        return address(_vestingContract);
    }
}

