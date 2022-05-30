# FRC721

## What I tried to make:

I tried to make a 1:1 replica of the OpenZeppelin implementation of the ERC721 standard, in Sway

## What I made:

A somewhat close implementation of the ERC721 standard, as ContractId and Address, are distinct types in Sway, I could not allow for usage of both in this contract. So only Addresses are supported in this implementation, meaning there is no need to check whether or not the recieving contract has the ability to handle this token so there is no implementations of "safe" methods such as "safeTransfer" and "safeMint"

## Limitations: 

Due to poor support for strings currently I couldnt implement URIs.. so no metadata. And since you cannot currently store strings in storage, I had to hardcode the name and symbol in its respective function, not sure whether or not it really makes a difference in the end though.
