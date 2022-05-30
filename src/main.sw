//this is meant as a template contract
contract;

use std::storage::StorageMap;
use std::address::Address;
use std::assert::require;
use std::revert::revert;
use std::chain::auth::{Sender, msg_sender};
use std::result::Result;
use std::context::call_frames::contract_id;

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
    //Maps the NFT id to an owner address, note- this means contracts cannot own NFTs with this model
    owners: StorageMap<u64, Address> = StorageMap::new::<u64, Address>, 
    //How many tokens each address holds
    balances: StorageMap<Address, u64> = StorageMap::new::<Address, u64>, 
    //Token id to approved address
    tokenApprovals: StorageMap<u64, Address> = StorageMap::new::<u64, Address>, 
    //owner to operator approval
    operatorApprovals: StorageMap<Address, StorageMap<Address, bool>> = StorageMap::new::<Address, StorageMap<Address, bool>>, 
}

impl MyContract for Contract {
    //returns how many tokens any address holds
    pub fn balanceOf(owner: Address) -> u64 {
        require(owner != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: Address zero is not a valid owner");
        return storage.balances.get(owner);
    }

    //returns the Address owner of any tokenId
    pub fn ownerOf(tokenId: u64) -> Address {
        return internalOwnerOf(tokenId);
    }

    //Returns a hardcoded name for this token contract
    pub fn getName() -> str[11] {
        return "example-nft";
    }

    //Returns a hardcoded symbol for this token contract
    pub fn getSymbol() -> str[6] {
        return "ex-nft";
    }

    //Returns whether all tokens of owner are approved for operator
    pub fn isApprovedForAll(owner: Address, operator: Address) -> bool {
        return internalIsApprovedForAll(owner, operator);
    }

    //Approves an address
    pub fn approve(to: Address, tokenId: u64) {
        return internalApprove(to, tokenId);
    }

    //Returns which address is approved for a tokenId
    pub fn getApproved(tokenId: u64) -> Address {
        return internalGetApproved(tokenId);
    }

    //Sets all addresses as approved for operator
    pub fn setApprovalForAll(operator: Address, approved: bool) {
        internalSetApprovalForAll(getSender(), operator, approved);
    }

    //Transfers token
    pub fn transferFrom(from: Address, to: Address, tokenId: u64) {
        require(isApprovedOrOwner(getSender(), tokenId), "FRC721: caller is not token owner nor approved");

        internalTransfer(from, to, tokenId);
    }
}

//Unwraps the msg_sender() value and returns only Address, reverts on ContractId
fn getSender() -> Address {
    let unwrapped = match msg_sender() {
        Result::Ok(inner_value) => inner_value, _ => revert(0), 
    };

    let ad = match unwrapped {
        Sender::Address(addr) => addr, _ => revert(0), 
    };
    ad
}

//Retrieves the corressponding owner of the tokenId in the StorageMap, reverts if Address(0), ie non existant token
fn internalOwnerOf(tokenId: u64) -> Address {
    let owner: Address = storage.owners.get(tokenId);
    require(owner != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: Owner query for non-existant token");
    return owner;
}

//Returns whether or not operator is approved for all of owners tokens
fn internalIsApprovedForAll(owner: Address, operator: Address) -> bool {
    return storage.operatorApprovals.get(owner).get(operator);
}

//Approve an address to transfer tokens
fn internalApprove(to: Address, tokenId: u64) {
    let owner = internalOwnerOf(tokenId);
    require(to != owner, "FRC721: approval to current owner");
    require((getSender() == owner) || internalIsApprovedForAll(owner, getSender()), "FRC721: approve caller is not token owner nor approved for all");
}

//Get address approved to transfer token for particular tokenId
fn internalGetApproved(tokenId: u64) -> Address {
    require(exists(tokenId), "FRC721: approved query for nonexistent token");
    return storage.tokenApprovals.get(tokenId);
}

//Check whether or not a tokenId exists
fn exists(tokenId: u64) -> bool {
    return storage.owners.get(tokenId) != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000);
}

//Approves a address to transfer token
fn internalApprove(to: Address, tokenId: u64) {
    storage.tokenApprovals.insert(tokenId, to);
}

//Sets approval for all tokens to operator
fn internalSetApprovalForAll(owner: Address, operator: Address, approved: bool) {
    require(owner != operator, "FRC721: approve to caller");
    storage.operatorApprovals.get(owner).insert(operator, approved);
}

//Checks whether spender has permission to transfer (is approved or owner)
fn isApprovedOrOwner(spender: Address, tokenId: u64) -> bool {
    let owner = internalOwnerOf(tokenId);
    return(spender == owner || internalIsApprovedForAll(owner, spender) || internalGetApproved(tokenId) == spender);
}

//Function called before every transfer of tokens
fn beforeTokenTransfer(from: Address, to: Address, tokenId: u64) {
    //insert whatever code you want
}

//Function called after every transfer of tokens
fn afterTokenTransfer(from: Address, to: Address, tokenId: u64) {
    //insert whatever code you want
}

//Transfers a token
fn internalTransfer(from: Address, to: Address, tokenId: u64) {
    require(internalOwnerOf(tokenId) == from, "FRC721: transfer from incorrect owner");
    require(to != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: transfer to the zero address");

    beforeTokenTransfer(from, to, tokenId);

    //clear approvals from previous owner
    internalApprove(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);

    storage.balances.insert(from, storage.balances.get(from) - 1);
    storage.balances.insert(to, storage.balances.get(from) + 1);
    storage.owners.insert(tokenId, to);

    afterTokenTransfer(from, to, tokenId);
}

//Mints(makes) a new token at to address
pub fn mint(to: Address, tokenId: u64) {
    require(to != ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), "FRC721: mint to the zero address");
    require(!exists(tokenId), "FRC721: token already minted");

    beforeTokenTransfer(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), to, tokenId);

    storage.balances.insert(to, storage.balances.get(to) + 1);
    storage.owners.insert(tokenId, to);

    afterTokenTransfer(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), to, tokenId);
}

//Burns a token from existance
pub fn burn(tokenId: u64) {
    let owner: Address = internalOwnerOf(tokenId);

    beforeTokenTransfer(owner, ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);

    internalApprove(~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);
    storage.balances.insert(owner, storage.balances.get(owner) - 1);
    //deleting the owner
    storage.owners.insert(tokenId, ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000));

    afterTokenTransfer(owner, ~Address::from(0x0000000000000000000000000000000000000000000000000000000000000000), tokenId);
}
