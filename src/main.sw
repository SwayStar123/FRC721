//this is meant as a template contract
contract;

use std::storage::StorageMap;
use std::address::Address;
use std::assert::require;
use std::chain::msg_sender;

// const NAME_LEN: u64 = 11;
// const SYMBOL_LEN: u64 = 6;

abi MyContract {
    pub fn balanceOf(owner: Address) -> u64;
    pub fn ownerOf(tokenId: u64) -> Address;
    pub fn getName() -> str[11];
    pub fn getSymbol() -> str[6];
}

storage {
    //change str lengths to length of respective strings
    name: str[11] = "example-nft",
    symbol: str[6] = "ex-nft",

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
    pub fn balanceOf(owner: Address) -> u64 {
        require(owner != Address::from(0), "FRC721: Address zero is not a valid owner");
        return storage.balances.get(owner);
    }

    pub fn ownerOf(tokenId: u64) -> Address {
        let owner: Address = storage.owners.get(tokenId);
        require(owner != Address::from(0), "FRC721: Owner query for non-existant token");
        return owner;        
    }

    pub fn getName() -> str[11] {
        return storage.name;
    }

    pub fn getSymbol() -> str[6] {
        return storage.symbol;
    }

    // pub fn tokenURI(tokenId: u64) -> str[5] { 
    //     require(exists(tokenId), "FRC721: URI query for non-existant token")

    //     let bURI = baseURI();
    //     return bURI + //tokenId.toString() replace with actual code
    // }

    pub fn isApprovedForAll(owner: Address, operator: Address) -> bool {
        return storage.operatorApprovals.get(owner).get(operator);
    }

    pub fn approve(to: Address, tokenId: u64) {
        let owner = ownerOf(tokenId);
        require(to != owner, "FRC721: approval to current owner");
        require((getSender() == owner) || isApprovedForAll(owner, getSender()),
            "FRC721: approve caller is not token owner nor approved for all");
    }

    pub fn getApproved(tokenId: u64) -> Address {
        require(exists(tokenId), "FRC721: approved query for nonexistent token");
        return storage.tokenApprovals.get(tokenId);
    }

    pub fn setApprovalForAll(operator: Address, approved: bool) {
        internalSetApprovalForAll(getSender(), operator, approved);
    }

    pub fn isApprovedForAll(owner: Address, operator: Address) -> bool {
        return storage.operatorApprovals.get(owner).get(operator);
    }

    pub fn transferFrom(from: Address, to: Address, tokenId: u64) {
        require(isApprovedOrOwner(getSender(), tokenId), "FRC721: caller is not token owner nor approved");

        internalTransfer(from, to, tokenId);
    }
}

fn exists(tokenId: u64) -> bool {
    return storage.owners.get(tokenId) != Address::from(0);
}

//replace with your own base URI
// fn baseURI() -> str[0] {
//     return ""
// }

fn internalApprove(to: Address, tokenId: u64) {
    storage.tokenApprovals.insert(tokenId, to);
}

fn getSender() -> Address {
    let unwrapped = 
    if let Result::Ok(inner_value) = msg_sender() {
            inner_value
    } else {
            revert(0);
    };

    let ad = if let Sender::Address(addr) = unwrapped {
        addr
    } else {
        revert(0);
    };
    ad
}

fn internalSetApprovalForAll(owner: Address, operator: Address, approved: bool) {
    require(owner != operator, "FRC721: approve to caller");
    //Not sure if this is correct, need to insert to a storage map nested within a storage map
    storage.operatorApprovals.insert(owner, (operator, approved));
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
    require(to != Address::from(0), "FRC721: transfer to the zero address");

    beforeTokenTransfer(from, to, tokenId);

    //clear approvals from previous owner
    approve(Address::from(0), tokenId);

    storage.balances.insert(from, storage.balances.get(from) - 1);
    storage.balances.insert(to, storage.balances.get(from) + 1);
    storage.owners.insert(tokenId, to);

    afterTokenTransfer();
}

pub fn mint(to: Address, tokenId: u64) {
        require(to != Address::from(0), "FRC721: mint to the zero address");
        require(!exists(tokenId), "FRC721: token already minted");

        beforeTokenTransfer(Address::from(0), to, tokenId);

        storage.balances.insert(to, storage.balances.get(to) + 1);
        storage.owners.insert(tokenId, to);

        afterTokenTransfer(Address::from(0), to, tokenId);
}

pub fn burn(tokenId: u64) {
    let owner: Address = ownerOf(tokenId);

    beforeTokenTransfer(owner, Address::from(0), tokenId);

    approve(Address::from(0), tokenId);
    storage.balances.insert(owner, storage.balances.get(owner) - 1);
    //deleting the owner
    storage.owners.insert(tokenId, Address:from(0));

    afterTokenTransfer(owner, Address::from(0), tokenId);
}