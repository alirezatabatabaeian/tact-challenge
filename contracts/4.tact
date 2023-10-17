import "@stdlib/deploy";

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message NftWithdrawal {
    queryId: Int as uint64;
    nftAddress: Address;
}

contract Task4 with Deployable {
    seed: Int as uint128;
    nft_address: Address;
    owner: Address;
    time: Int as uint32;
    init(seed: Int){
        self.seed = seed;
        self.nft_address = newAddress(0, 0);
        self.owner = newAddress(0, 0);
        self.time = 0;
    }

    receive(msg: OwnershipAssigned){
        if (self.owner == newAddress(0, 0)) {
            self.nft_address = sender();
            self.owner = msg.prevOwner;
            self.time = msg.forwardPayload.preloadUint(32);
        } else {
            self.reply(Transfer{queryId: 0,
                    newOwner: msg.prevOwner,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardAmount: ton("0.01"),
                    forwardPayload: emptySlice()
                }.toCell()
            );
        }
    }

    receive(msg: NftWithdrawal){
        require(msg.nftAddress == self.nft_address, "Invalid NFT Address");
        require(sender() == self.owner, "Invalid sender");
        if (now() < self.time) {
            self.reply("NFT is still locked".asComment());
        } else {
            send(SendParameters{to: self.nft_address,
                    bounce: true,
                    value: 0,
                    mode: SendRemainingBalance,
                    body: Transfer{queryId: 0,
                        newOwner: sender(),
                        responseDestination: myAddress(),
                        customPayload: null,
                        forwardAmount: ton("0.01"),
                        forwardPayload: emptySlice()
                    }.toCell()
                }
            );
            // todo: make the storage empty (maybe not necessary)
        }
    }

    get fun time(): Int {
        // todo: make sure about having nft (maybe not necessary)
        return self.time - now();
    }

    get fun nft(): Address? {
        // todo: return null
        return self.nft_address;
    }

    get fun owner(): Address? {
        // todo: return null
        return self.owner;
    }
}