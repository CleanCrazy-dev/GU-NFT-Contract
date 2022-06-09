// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./GUCollections.sol";
import "./GUCancellations.sol";
import "./GUTradeManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TradeLib.sol";

contract GUTradeMatcher {

    GUTradeManager manager;

    address adminSafe;

    event AuctionSuccessful(uint indexed id, address indexed bidder, address indexed collector, bytes bidSig, uint listingId, uint amount, uint price);
    event PurchaseSuccessful(uint indexed id, address indexed buyer, address indexed collector, uint buyerId, uint listingId, uint amount, uint price);
    event OfferAccepted(uint indexed id, address indexed offeror, address indexed collector, bytes offerSig, uint listingId, uint amount, uint price);
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

    function acceptOffer(TradeLib.FinalizeOffer calldata data) external
    {
        TradeLib.checkFinalizeOfferPreconditions(manager.cancellations(), manager, data);
            
        TradeLib.verifyFinalizeOfferSignatures(data);

        TradeLib.transferERC20(data.nftData, data.sale.tokenAddress, data.offerer, data.seller, manager.beneficiary(), data.offer.amount, data.auth.fee);

        TradeLib.transferOrMintERC1155(data.nftData, TradeLib.TransferERC1155Data(data.seller, data.offer.to, data.sale.amount, data.nftSignature));
   
        emit OfferAccepted(data.sale.nftId, data.offerer, data.offer.to, data.offerSignature, data.offer.listingId, data.sale.amount, data.offer.amount);
    }

    function finalizeBatchOffers(TradeLib.FinalizeOffer[] calldata data) external
    {
        for(uint i; i < data.length; i++){
            
            TradeLib.checkFinalizeOfferPreconditions(manager.cancellations(), manager, data[i]);

            TradeLib.verifyFinalizeOfferSignatures(data[i]);

            TradeLib.transferERC20(data[i].nftData, data[i].sale.tokenAddress, data[i].offerer, data[i].seller, manager.beneficiary(), data[i].offer.amount,  data[i].auth.fee);

            TradeLib.transferOrMintERC1155(data[i].nftData, TradeLib.TransferERC1155Data(data[i].seller, data[i].offer.to, data[i].sale.amount, data[i].nftSignature));

            emit OfferAccepted(data[i].sale.nftId, data[i].offerer, data[i].offer.to, data[i].offerSignature, data[i].offer.listingId, data[i].sale.amount, data[i].offer.amount);

        }
    }

    function purchase(TradeLib.FinalizePurchase calldata data) external
    {
        TradeLib.checkPurchasePreconditions(manager.cancellations(), manager, data);

        TradeLib.verifyPurchaseSignatures(data);

        TradeLib.transferERC20(data.nftData, data.sale.tokenAddress, msg.sender, data.seller, manager.beneficiary(), data.sale.price,  data.auth.fee);

        TradeLib.transferOrMintERC1155(data.nftData, TradeLib.TransferERC1155Data(data.seller, data.to, data.sale.amount, data.nftSignature));

        emit PurchaseSuccessful(data.sale.nftId, msg.sender, data.to,  0, data.sale.listingId, data.sale.amount, data.sale.price);
    }

    function batchPurchase(TradeLib.FinalizePurchase[] calldata data) external
    {
        for (uint i; i<data.length; i++)
        {
            TradeLib.checkPurchasePreconditions(manager.cancellations(), manager, data[i]);

            TradeLib.verifyPurchaseSignatures(data[i]);

            TradeLib.transferERC20(data[i].nftData, data[i].sale.tokenAddress, msg.sender, data[i].seller, manager.beneficiary(), data[i].sale.price,  data[i].auth.fee);
            
            TradeLib.transferOrMintERC1155(data[i].nftData, TradeLib.TransferERC1155Data(data[i].seller, data[i].to, data[i].sale.amount, data[i].nftSignature));

            emit PurchaseSuccessful(data[i].sale.nftId, msg.sender, data[i].to,  0, data[i].sale.listingId, data[i].sale.amount, data[i].sale.price);
        }
    }
    
    function finalizeAuction(TradeLib.FinalizeAuction calldata data) external
    {
        TradeLib.checkFinalizeAuctionPreconditions(manager.cancellations(), manager, data);

        TradeLib.verifyFinalizeAuctionSignatures(data);

        TradeLib.transferERC20(data.nftData, data.auction.tokenAddress, data.bidder, data.seller, manager.beneficiary(), data.bid.amount,  data.auth.fee);
            
        TradeLib.transferOrMintERC1155(data.nftData, TradeLib.TransferERC1155Data(data.seller, data.bid.to, data.auction.amount, data.nftSignature));

        emit AuctionSuccessful(data.auction.nftId, data.bidder, data.bid.to, data.bidSignature, data.auction.listingId, data.auction.amount, data.bid.amount);
    }

    function finalizeBatchAuctions(TradeLib.FinalizeAuction[] calldata data) external
    {
        for (uint i; i<data.length; i++)
        {

            TradeLib.checkFinalizeAuctionPreconditions(manager.cancellations(), manager, data[i]);

            TradeLib.verifyFinalizeAuctionSignatures(data[i]);

            TradeLib.transferERC20(data[i].nftData, data[i].auction.tokenAddress, data[i].bidder, data[i].seller, manager.beneficiary(), data[i].bid.amount,  data[i].auth.fee);
            
            TradeLib.transferOrMintERC1155(data[i].nftData, TradeLib.TransferERC1155Data(data[i].seller, data[i].bid.to, data[i].auction.amount, data[i].nftSignature));

            emit AuctionSuccessful(data[i].auction.nftId, data[i].bidder, data[i].bid.to, data[i].bidSignature, data[i].auction.listingId, data[i].auction.amount ,data[i].bid.amount);

        }
    }
}
