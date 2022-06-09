// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./GUCollections.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TradeLib.sol";

contract GUCancellations {
    mapping(uint => bool) public cancelledListings;
    mapping(bytes => bool) public cancelledOffers;

    event ListingCancelled(uint indexed id);
    event OfferCancelled(bytes indexed signature);

    function cancelAuction(address seller, TradeLib.AuctionData calldata auction, bytes calldata auctionSignature, address authorized, TradeLib.AuthData calldata auth, bytes calldata authSignature) external
    {
        require(seller == msg.sender, "You are not the seller");
        require(TradeLib.verifyAuctionSignature(seller, auction, auctionSignature), "Invalid seller's signature");
        require(TradeLib.verifyAuthSignature(authorized, auth, authSignature), "Invalid auth signature");
        cancelledListings[auction.listingId] = true;
        emit ListingCancelled(auction.listingId);
    }

    function cancelSale(address seller, TradeLib.SaleData calldata sale, bytes calldata saleSignature, address authorized, TradeLib.AuthData calldata auth, bytes calldata authSignature) external
    {
        require(seller == msg.sender, "You are not the seller");
        require(TradeLib.verifySaleSignature(seller,sale,saleSignature), "Invalid seller's signature");
        require(TradeLib.verifyAuthSignature(authorized, auth, authSignature), "Invalid auth signature");
        cancelledListings[sale.listingId] = true;
        emit ListingCancelled(sale.listingId);
    }

    function cancelOffer(address offerer, TradeLib.OfferData calldata offer, bytes calldata offerSignature,address authorized, TradeLib.AuthData calldata auth, bytes calldata authSignature) external
    {
        require(offerer == msg.sender, "You are not the offerer");
        require(!cancelledOffers[offerSignature], "Offer already cancelled");
        require(TradeLib.verifyOfferSignature(offerer,offer,offerSignature), "Invalid offerer's signature");
        require(TradeLib.verifyAuthSignature(authorized, auth, authSignature), "Invalid auth signature");
        cancelledOffers[offerSignature] = true;
        emit OfferCancelled(offerSignature);
    }
}