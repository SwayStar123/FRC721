//this is meant as a template contract
contract;

use std::storage::StorageMap;
use std::address::Address;
use std::assert::require;
use std::revert::revert;
use std::chain::auth::{Sender, msg_sender};
use std::result::Result;

abi MyContract {
    pub fn balanceOf(owner: Address) -> u64;
    pub fn ownerOf(tokenId: u64) -> Address;
    pub fn getName() -> str[11];
    pub fn getSymbol() -> str[6];
    pub fn isApprovedForAll(owner: Address, operator: Address) -> bool;
    pub fn approve(to: Address, tokenId: u64);
    pub fn getApproved(tokenId: u64) -> Address;
    pub fn setApprovalForAll(operator: Address, approved: bool);
    pub fn transferFrom(from: Address, to: Address, tokenId: u64);
}

storage {
    //change str lengths to length of respective strings
    name: str[11] = "example-nft",
    symbol: str[6] = "ex-nft",

    //Maps the NFT id to an owner address, note- this means contracts cannot own NFTs with this model
    owners: StorageMap<u64, Address> = StorageMap::new::<u64, Address>, //How many tokens each address holds
    balances: StorageMap<Address, u64> = StorageMap::new::<Address, u64>, //Token id to approved address
    tokenApprovals: StorageMap<u64,
    Address> = StorageMap::new::<u64,
    Address>, //owner to operator approval
    operatorApprovals: StorageMap<Address,
    StorageMap<Address, bool>> = StorageMap::new::<Address,
    StorageMap<Address, bool>>, 
}

impl MyContract for Contract {
    pub fn balanceOf(owner: Address) -> u64 {
        require(owner != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: Address zero is not a valid owner");
        return storage.balances.get(owner);
    }

    pub fn ownerOf(tokenId: u64) -> Address {
        let owner: Address = storage.owners.get(tokenId);
        require(owner != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: Owner query for non-existant token");
        return owner;
    }

    pub fn getName() -> str[11] {
        return storage.name;
    }

    pub fn getSymbol() -> str[6] {
        return storage.symbol;
    }

    pub fn isApprovedForAll(owner: Address, operator: Address) -> bool {
        return storage.operatorApprovals.get(owner).get(operator);
    }

    pub fn approve(to: Address, tokenId: u64) {
        let owner = ownerOf(tokenId);
        require(to != owner, "FRC721: approval to current owner");
        require((getSender() == owner) || isApprovedForAll(owner, getSender()), "FRC721: approve caller is not token owner nor approved for all");
    }

    pub fn getApproved(tokenId: u64) -> Address {
        require(exists(tokenId), "FRC721: approved query for nonexistent token");
        return storage.tokenApprovals.get(tokenId);
    }

    pub fn setApprovalForAll(operator: Address, approved: bool) {
        internalSetApprovalForAll(getSender(), operator, approved);
    }

    pub fn transferFrom(from: Address, to: Address, tokenId: u64) {
        require(isApprovedOrOwner(getSender(), tokenId), "FRC721: caller is not token owner nor approved");

        internalTransfer(from, to, tokenId);
    }
}

fn exists(tokenId: u64) -> bool {
    return storage.owners.get(tokenId) != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000);
}

fn internalApprove(to: Address, tokenId: u64) {
    storage.tokenApprovals.insert(tokenId, to);
}

fn getSender() -> Address {
    let unwrapped = match msg_sender() {
        Result::Ok(inner_value) => inner_value, _ => revert(0), 
    };

    let ad = match unwrapped {
        Sender::Address(addr) => addr, _ => revert(0), 
    };
    ad
}

fn internalSetApprovalForAll(owner: Address, operator: Address, approved: bool) {
    require(owner != operator, "FRC721: approve to caller");
    storage.operatorApprovals.get(owner).insert(operator, approved);
}

fn isApprovedOrOwner(spender: Address, tokenId: u64) -> bool {
    let owner = ownerOf(tokenId);
    return(spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
}

fn beforeTokenTransfer(from: Address, to: Address, tokenId: u64) {
    //insert whatever code you want
}

fn afterTokenTransfer(from: Address, to: Address, tokenId: u64) {
    //insert whatever code you want
}

fn internalTransfer(from: Address, to: Address, tokenId: u64) {
    require(ownerOf(tokenId) == from, "FRC721: transfer from incorrect owner");
    require(to != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: transfer to the zero address");

    beforeTokenTransfer(from, to, tokenId);

    //clear approvals from previous owner
    approve(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);

    storage.balances.insert(from, storage.balances.get(from) - 1);
    storage.balances.insert(to, storage.balances.get(from) + 1);
    storage.owners.insert(tokenId, to);

    afterTokenTransfer(from, to, tokenId);
}

pub fn mint(to: Address, tokenId: u64) {
    require(to != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: mint to the zero address");
    require(!exists(tokenId), "FRC721: token already minted");

    beforeTokenTransfer(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), to, tokenId);

    storage.balances.insert(to, storage.balances.get(to) + 1);
    storage.owners.insert(tokenId, to);

    afterTokenTransfer(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), to, tokenId);
}

pub fn burn(tokenId: u64) {
    let owner: Address = ownerOf(tokenId);

    beforeTokenTransfer(owner, ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);

    approve(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);
    storage.balances.insert(owner, storage.balances.get(owner) - 1);
    //deleting the owner
    storage.owners.insert(tokenId, ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000));

    afterTokenTransfer(owner, ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);
}
