// Owner of this software is Nikola Radošević PR Innolab Solutions Serbia. All rights reserved.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";

contract GUCollections is ERC1155Supply, ERC1155URIStorage {
    mapping (address => bool) public traders;
    mapping (uint => bytes) public nftSignatures;

    address public adminSafe;

    event TraderAuthorized(address indexed traderAddress);
    event TraderDisauthorized(address indexed traderAddress);
    event AdminSafeChanged(address indexed safeAddress);

    modifier onlyTraders {
        require(traders[msg.sender], 'You are not whitelisted.');
        _;
    }

    modifier onlyAdminSafe {
        require(msg.sender==adminSafe, 'You are not whitelisted.');
        _;
    }

    constructor(string memory uri_, address safe) ERC1155(uri_) {
        adminSafe = safe;
    }

    function changeAdminSafe(address safe) public onlyAdminSafe
    {
        require(adminSafe!=safe, "Provided address already safe address");
        adminSafe = safe;
        emit AdminSafeChanged(safe);
    }

    function setTraderPermission(address trader, bool permitted) external onlyAdminSafe
    {
        traders[trader]=permitted;
        if (permitted) emit TraderAuthorized(trader);
        else emit TraderDisauthorized(trader);
    }

    function uri(uint256 tokenId) public view override(ERC1155URIStorage, ERC1155) returns (string memory) {
        string memory tokenURI = tokenURIs(tokenId);

        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(baseURI(), tokenURI, "/metadata.json")) : super.uri(tokenId);
    }

    function setBaseURI(string calldata baseURI) external onlyAdminSafe {
        _setBaseURI(baseURI);
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {}

    function mint(address to, uint256 id, uint256 amount, bytes calldata signature, string calldata cid) external onlyTraders {
        if (totalSupply(id) == 0)
        {
            _setURI(id, cid);
            nftSignatures[id] = signature;
        }
        _mint(to, id, amount, "");
    }

}