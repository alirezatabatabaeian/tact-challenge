import "@stdlib/deploy";
message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

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

contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  nfts: map<Int as uint16, Address>;
  totalNftsHeld: Int as uint64;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed;
    self.totalNftsHeld = 0;
  }

  receive(msg: OwnershipAssigned) {
    if(msg.prevOwner == self.owner){
        self.nfts.set(self.totalNftsHeld, sender());
        self.totalNftsHeld = self.totalNftsHeld + 1;
    }
    else{
        if(context().value < ton("2.1")){
            send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: Transfer{queryId: msg.queryId,
                newOwner: msg.prevOwner,
                responseDestination: msg.prevOwner,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
              }.toCell()
            });
        }
        else{
          let random_index: Int = random(0, self.totalNftsHeld);
          if(random_index == self.totalNftsHeld){
            send(SendParameters{
                to: sender(),
                value: context().value - ton("2"),
                mode: SendPayGasSeparately,
                body: Transfer{queryId: msg.queryId,
                    newOwner: msg.prevOwner,
                    responseDestination: msg.prevOwner,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell()
              });
          }
          else{
            send(SendParameters{ 
            to: self.nfts.get(random_index)!!,
            value: context().value - ton("2"),
            mode: SendPayGasSeparately,
            body: Transfer{queryId: msg.queryId,
                newOwner: msg.prevOwner,
                responseDestination: msg.prevOwner,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
            }.toCell()
          });
            self.nfts.set(random_index, sender());
          }
        }
    }
  }

  receive(msg: AdminWithdrawalProfit) {
    require(self.owner == sender(), "Insufficient privelegies");
    send(SendParameters{to: sender(),
                      bounce: true,
                      value: myBalance() - ton("0.1"),
                      mode: SendRemainingValue,
                      body: AdminFetchProfit{queryId: msg.queryId}.toCell()});
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    require(context().value >= ton("1") + self.totalNftsHeld * ton("0.08"), "Insufficent funds");
    require((self.owner == sender()) || (myAddress() == sender()), "Invalid sender");
    // let index: Int = self.totalNftsHeld - 1; // remove index and use self.totalNftsHeld
    if(self.totalNftsHeld <= 100){
      repeat(self.totalNftsHeld){
        send(SendParameters{
            to: self.nfts.get(self.totalNftsHeld - 1)!!,
            bounce: true,
            value: ton("0.08"),
            mode: 0,
            body: Transfer{
                queryId: msg.queryId,
                newOwner: self.owner,
                responseDestination: self.owner,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
                }.toCell()});
        self.totalNftsHeld = self.totalNftsHeld - 1;
      }
      self.nfts = emptyMap();
    }
    else{
      repeat(100){
        send(SendParameters{
            to: self.nfts.get(self.totalNftsHeld - 1)!!,
            bounce: true,
            value: ton("0.08"),
            mode: 0,
            body: Transfer{
                queryId: msg.queryId,
                newOwner: self.owner,
                responseDestination: self.owner,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice()
                }.toCell()});
        self.totalNftsHeld = self.totalNftsHeld - 1;
      }
        send(SendParameters{
              to: myAddress(),
              bounce: true,
              value: 0,
              mode: SendRemainingBalance,
              body: AdminWithdrawalAllNFTs{
                  queryId: msg.queryId
                  }.toCell()});
    }
  }

  get fun profit(): Int {
    if(myBalance() <= ton("0.1")) {
      return 0;
    }
    else{
      return myBalance() - ton("0.1");
    }
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.nfts;
  }
}