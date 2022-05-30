# FRC721

As Address and ContractId are distinct types in Sway, only Addresses can own Tokens in this implementation

consequently, as there is no need to worry about wether or not recieving smart contracts can candle these Tokens, there is no implementations of "safe" methods such as "safeTransfer" and "safeMint"


And due to poor support for strings currently I couldnt implement URIs.. so no metadata
