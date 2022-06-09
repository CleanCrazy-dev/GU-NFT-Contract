// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./GUCollections.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./GUTradeManager.sol";
import "./TradeLib.sol";

contract GUMinter {
    
    GUTradeManager manager;
    address adminSafe;

    event MintSuccessful(uint256 indexed id, uint256 amount, address receiver, address indexed initiator);
    event ManagerAddressChanged(address indexed managerAddress);

    constructor(address managerAddress, address safeAddress) {
        adminSafe = safeAddress;
        setManagerAddress(managerAddress);
    }

    modifier onlyAdminSafe {
        require(msg.sender == adminSafe, 'You are not whitelisted.');
        _;
    }

    function setManagerAddress(address managerAddress) public onlyAdminSafe
    {
        manager = GUTradeManager(managerAddress);
        emit ManagerAddressChanged(managerAddress);
    }

    function mintTo(TradeLib.MintTo calldata data) external
    {
        GUCollections collections = GUCollections(data.nftData.nftContract);
            
        TradeLib.checkMintToPreconditions(collections, manager, data);

        collections.mint(data.to, data.nftData.nftId, data.amount, data.nftSignature, data.nftData.cid);

        emit MintSuccessful(data.nftData.nftId, data.amount, data.to, data.nftData.creator);

    }
    
    function batchMintTo(TradeLib.MintTo[] calldata data) external
    {
        for(uint i; i < data.length; i++){
            GUCollections collections = GUCollections(data[i].nftData.nftContract);

            TradeLib.checkMintToPreconditions(collections, manager, data[i]);

            collections.mint(data[i].to,data[i].nftData.nftId,data[i].amount, data[i].nftSignature, data[i].nftData.cid);

            emit MintSuccessful(data[i].nftData.nftId, data[i].amount, data[i].to, data[i].nftData.creator);
        }

    } 
}
