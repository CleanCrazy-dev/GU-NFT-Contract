// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./GUCollections.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TradeLib.sol";

contract GUTradeManager {
    address public adminSafe;
    address payable public beneficiary;
    address public cancellations;

    uint public deferralStart;
    uint public deferralEnd;

    uint public maxRoyaltyFee;
    uint public maxPlatformFee;

    mapping(address => bool) public authorizedSigners;

    event CancellationsAddressChanged(address indexed cancellationsContractAddress);
    event FinalizationDefferalChanged(uint indexed start, uint indexed end);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event FeesChanged(uint indexed royalty, uint indexed platform);
    event BeneficiaryChanged(address indexed beneficiary);

    constructor(address safeAddress) {
        adminSafe = safeAddress;
    }

    modifier onlyAdminSafe {
        require(msg.sender == adminSafe, 'You are not whitelisted.');
        _;
    }

    function setCancellationsContractAddress(address cancellationsContractAddress) external onlyAdminSafe
    {
        require(cancellations!=cancellationsContractAddress, "Same address already set");
        cancellations = cancellationsContractAddress;
    }

    function setFinalizationDefferal(uint finalizationDefferalStart, uint finalizationDefferalEnd) external onlyAdminSafe
    {
        deferralStart = finalizationDefferalStart;
        deferralEnd = finalizationDefferalEnd;
        emit FinalizationDefferalChanged(deferralStart, deferralEnd);
    }

    function setMaxFees(uint royalty, uint platform) external onlyAdminSafe
    {
        maxRoyaltyFee = royalty;
        maxPlatformFee = platform;
        emit FeesChanged(royalty, platform);
    }

    function setBeneficiary(address _beneficiary) external onlyAdminSafe
    {
        beneficiary = payable(_beneficiary);
        emit BeneficiaryChanged(_beneficiary);
    }

    function setAuthorizedSigners(address signer, bool authorized) external onlyAdminSafe
    {
        require(authorizedSigners[signer] != authorized, 'Already (un)authorized');

        authorizedSigners[signer] = authorized;

        if (authorized)
        {
            emit SignerAdded(signer);
        }
        else
        {
            emit SignerRemoved(signer);
        }
    }

}