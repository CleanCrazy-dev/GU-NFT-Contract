// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./GUCollections.sol";
import "./GUCancellations.sol";
import "./GUTradeManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library TradeLib {

    function checkFinalizeAuctionPreconditions(address cancellationsAddress, GUTradeManager manager, TradeLib.FinalizeAuction calldata data) external view {
        require(manager.authorizedSigners(data.authorized), "Signer not authorized");
        require(!(GUCancellations(cancellationsAddress).cancelledListings(data.auction.listingId)), "Listing cancelled");
        uint time = block.timestamp;
        require(time > data.auction.expiry, "Auction hasn't ended yet");
        require(time > data.auction.expiry + manager.deferralStart(), "Settling period hasn't ended yet");
        require(time < data.auction.expiry + manager.deferralEnd() + 30 minutes, "Auction expired");
        require(!(GUCancellations(cancellationsAddress).cancelledOffers(data.bidSignature)),"Offer cancelled");

        require(data.bid.listingId == data.auction.listingId, "Listing id mismatch");
        require(data.nftData.nftId == data.auction.nftId, "NFT id mismatch");
        require(data.nftData.royalty <= manager.maxRoyaltyFee(), "Royalty too high");
        require(data.auth.fee <= manager.maxPlatformFee(), "Platform fee too high");
        require(data.bid.amount > data.auction.reservePrice, "Reserve not met");
    }

    function checkPurchasePreconditions(address cancellationsAddress, GUTradeManager manager, TradeLib.FinalizePurchase calldata data) external view
    {
        require(manager.authorizedSigners(data.authorized), "Signer not authorized");
        require(!(GUCancellations(cancellationsAddress).cancelledListings(data.sale.listingId)),"Listing cancelled");
        require(block.timestamp < data.sale.expiry + 3 minutes, "Listing expired");
        require(data.nftData.royalty <= manager.maxRoyaltyFee(), "Royalty too high");
        require(data.auth.fee <= manager.maxPlatformFee(), "Platform fee too high");
        require(data.nftData.nftId == data.sale.nftId, "NFT id mismatch");
    }

    function checkFinalizeOfferPreconditions(address cancellationsAddress, GUTradeManager manager, TradeLib.FinalizeOffer calldata data) external view
    {
        require(manager.authorizedSigners(data.authorized), "Signer not authorized");
        require(data.seller == msg.sender, "Unauthorized");
        require(!(GUCancellations(cancellationsAddress).cancelledListings(data.sale.listingId)), "Listing cancelled");
        require(!(GUCancellations(cancellationsAddress).cancelledOffers(data.offerSignature)), "Offer cancelled");
        require(block.timestamp < data.sale.expiry + 3 minutes, "Listing expired");
        require(data.nftData.royalty <= manager.maxRoyaltyFee(), "Royalty too high");
        require(data.auth.fee <= manager.maxPlatformFee(), "Platform fee too high");
        require(data.offer.listingId == data.sale.listingId, "Listing id mismatch");
        require(data.nftData.nftId == data.sale.nftId, "NFT id mismatch");
    }

    function checkMintToPreconditions(GUCollections collections, GUTradeManager manager, TradeLib.MintTo calldata data) external view
    {
        require(manager.authorizedSigners(data.authorized), "Signer not authorized");
        require(data.nftData.creator == msg.sender, "Unauthorized");
        require(data.nftData.royalty <= manager.maxRoyaltyFee(), "Royalty too high");
        require(TradeLib.checkForSupplyOverflow(collections, data.nftData.nftId, data.nftData.supply, data.amount), "Supply overflow");
        require(TradeLib.verifyNftSignature(data.authorized, data.nftData, data.nftSignature), "Invalid mint data / signature provided");
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    struct AuctionData {
        uint listingId;
        uint nftId;
        uint amount;
        address tokenAddress;
        uint startPrice;
        uint reservePrice;
        uint start;
        uint expiry;
    }

    function verifyAuctionSignature(address signer, AuctionData memory auction, bytes memory signature) internal pure returns (bool)
    {
        bytes memory toHash = abi.encodePacked(auction.listingId, auction.nftId, auction.amount, auction.tokenAddress, auction.startPrice, auction.reservePrice, auction.start, auction.expiry);
        bytes32 _hash = keccak256(toHash);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    struct SaleData {
        uint listingId;
        uint nftId;
        uint amount;
        address tokenAddress;
        uint price;
        uint start;
        uint expiry;
    }

    function verifySaleSignature(address signer, SaleData memory sale, bytes memory signature) internal pure returns (bool)
    {
        bytes memory toHash = abi.encodePacked(sale.listingId, sale.nftId, sale.amount, sale.tokenAddress, sale.price, sale.start, sale.expiry);
        bytes32 _hash = keccak256(toHash);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    struct BidData {
        address to;
        uint listingId;
        uint amount;
    }

    function verifyBidSignature(address signer, BidData memory bid, bytes memory signature) internal pure returns (bool)
    {
        bytes memory toHash = abi.encodePacked(bid.to, bid.listingId, bid.amount);
        bytes32 _hash = keccak256(toHash);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    struct OfferData {
        address to;
        uint listingId;
        uint amount;
        uint expiry;
    }

    function verifyOfferSignature(address signer, OfferData memory offer, bytes memory signature) internal pure returns (bool)
    {
        bytes memory toHash = abi.encodePacked(offer.to, offer.listingId, offer.amount, offer.expiry);
        bytes32 _hash = keccak256(toHash);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    function verifyAuthBidOfferSignature(address signer, bytes memory message, bytes memory signature) internal pure returns (bool)
    {
        bytes32 _hash = keccak256(message);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    struct NFTData {
        address creator;
        uint nftId;
        string cid;
        uint supply;
        uint royalty;
        address nftContract;
    }

    function verifyNftSignature(address signer, NFTData memory nft, bytes memory signature) internal pure returns (bool)
    {
        bytes memory toHash = abi.encodePacked(nft.creator, nft.royalty, nft.nftId, nft.supply, nft.nftContract);
        bytes32 _hash = keccak256(toHash);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    struct AuthData {
        bytes signature;
        uint fee;
    }
    
    function verifyAuthSignature(address signer, AuthData memory auth, bytes memory signature) internal pure returns (bool)
    {
        bytes memory toHash = abi.encodePacked(auth.signature, auth.fee);
        bytes32 _hash = keccak256(toHash);
        return recoverSigner(getEthSignedMessageHash(_hash), signature) == signer;
    }

    struct MintTo {
        address authorized;
        NFTData nftData;
        bytes nftSignature;

        uint amount;
        address to;
    }

    struct FinalizePurchase {
        address nftSigner;
        NFTData nftData;
        bytes nftSignature;

        address seller;
        SaleData sale;
        bytes saleSignature;

        address authorized;
        AuthData auth;
        bytes authSignature;

        address to;
    }

    function verifyPurchaseSignatures(FinalizePurchase calldata data) external pure {
        require(verifyNftSignature(data.nftSigner, data.nftData, data.nftSignature), "Invalid nft data / signature");
        require(verifySaleSignature(data.seller,data. sale, data.saleSignature), "Invalid Sale data / seller signature provided");
        require(verifyAuthSignature(data.authorized, data.auth, data.authSignature), "Invalid auth signature");
    }

    struct FinalizeAuction {

        address nftSigner;
        NFTData nftData;
        bytes nftSignature;

        address seller;
        AuctionData auction;
        bytes auctionSignature;

        address authorized;
        AuthData auth;
        bytes authSignature;

        address bidder;
        BidData bid;
        bytes bidSignature;

        address bidAuth;
        bytes bidAuthSignature;

    }

    struct TransferERC1155Data{
        address seller;
        address to;
        uint amount; 
        bytes nftSignature;
    }

    function verifyFinalizeAuctionSignatures(FinalizeAuction calldata data) external pure 
    {
        require(verifyNftSignature(data.nftSigner, data.nftData, data.nftSignature));
        require(verifyAuctionSignature(data.seller, data.auction, data.auctionSignature), "Invalid Auction data / seller signature provided");
        require(verifyAuthSignature(data.authorized, data.auth, data.authSignature), "Invalid auction auth signature");
        require(verifyBidSignature(data.bidder, data.bid, data.bidSignature), "Invalid bid signature");
        require(verifyAuthBidOfferSignature(data.bidAuth, data.bidSignature, data.bidAuthSignature),"Invalid bid auth signature");
    }

    struct FinalizeOffer {

        address nftSigner;
        NFTData nftData;
        bytes nftSignature;

        address seller;
        SaleData sale;
        bytes saleSignature;

        address authorized;
        AuthData auth;
        bytes authSignature;

        address offerer;
        OfferData offer;
        bytes offerSignature;

        address offerAuth;
        bytes offerAuthSignature;

    }

    function verifyFinalizeOfferSignatures(FinalizeOffer calldata data) external pure
    {
        require(verifyNftSignature(data.nftSigner, data.nftData, data.nftSignature));
        require(verifySaleSignature(data.seller, data.sale, data.saleSignature), "Invalid Sale data / seller signature provided");
        require(verifyAuthSignature(data.authorized, data.auth, data.authSignature), "Invalid auth signature");        
        require(verifyOfferSignature(data.offerer, data.offer, data.offerSignature), "Invalid Offer data / offerer signature provided");
        require(verifyAuthBidOfferSignature(data.offerAuth, data.offerSignature, data.offerAuthSignature),"Invalid bid auth signature");
    }

    function checkForSupplyOverflow(GUCollections collections, uint nftId, uint supply, uint amount) internal view returns (bool)
    {
        uint noOfMinted = collections.totalSupply(nftId);
        
        return !(noOfMinted + amount > supply);
    }

    function transferOrMintERC1155(NFTData calldata nftData, TransferERC1155Data calldata transferData) external
    {
        GUCollections collections = GUCollections(nftData.nftContract);

        uint noOfMinted = collections.totalSupply(nftData.nftId);

        if (noOfMinted>0)
        {
            require (keccak256(transferData.nftSignature) == keccak256(collections.nftSignatures(nftData.nftId)), "Nft signature tampered");
        }

        if (nftData.creator != transferData.seller)
        {
            collections.safeTransferFrom(transferData.seller, transferData.to, nftData.nftId, transferData.amount, "");
        }
        else
        {
            uint unMinted = nftData.supply - noOfMinted;
            uint balance = collections.balanceOf(transferData.seller, nftData.nftId);

            require(balance + unMinted <= transferData.amount, 'Insufficient amount of tokens');

            if (transferData.amount <= unMinted)
            {
                collections.mint(transferData.to, nftData.nftId, transferData.amount, transferData.nftSignature, nftData.cid);
            }
            else
            {
                uint remainder = transferData.amount - unMinted;

                if (unMinted>0)
                collections.mint(transferData.to, nftData.nftId, unMinted, transferData.nftSignature, nftData.cid);

                collections.safeTransferFrom(transferData.seller, transferData.to, nftData.nftId, remainder, "");
            }
        }
    }

    function transferERC20(NFTData calldata nftData, address tokenAddress, address sender, address seller, address beneficiary, uint amount, uint fee) external
    {
        ERC20 token = ERC20(tokenAddress);

        require(token.transferFrom(sender, seller, ((10000 - fee - nftData.royalty) * amount) / 10000), "GUC transfer to seller failed");
        require(token.transferFrom(sender, beneficiary, (fee * amount) / 10000), "GUC transfer to beneficiary failed");
        
        if (nftData.royalty > 0)
        require(token.transferFrom(sender, nftData.creator, (nftData.royalty * amount) / 10000), "GUC transfer to creator failed");
    }
}