import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.
*/

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64; // should be 0
    amount: Int as coins; // should be amount of jettons to send
    destination: Address; // should be user address / TokenNotification.from
    responseDestination: Address?; // should be myAddress()
    customPayload: Cell?; // should be null
    forwardTonAmount: Int as coins; // should be ton("0.01")
    forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
    owner: Address;
    aAmount: Int;
    bAmount: Int;
    jettonAddressA: Address;
    jettonAddressB: Address;
    decimal: Int;
    init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address){
        self.owner = admin;
        self.jettonAddressA = newJettonAddressA;
        self.jettonAddressB = newJettonAddressB;
        self.aAmount = 0;
        self.bAmount = 0;
        self.decimal = 1000000000;
    }

    receive(msg: TokenNotification){
        if (sender() == self.jettonAddressA) {
            if (msg.from == self.owner) {
                self.aAmount = self.aAmount + msg.amount;
            } else {
                if (msg.amount <= self.aAmount) {
                    let bSent: Int = self.bAmount * self.decimal / self.aAmount * msg.amount / self.decimal;
                    self.aAmount = self.aAmount + msg.amount;
                    self.bAmount = self.bAmount - bSent;
                    send(SendParameters{to: sender(),
                            bounce: true,
                            value: 0,
                            mode: SendPayGasSeparately,
                            body: TokenTransfer{queryId: 0,
                                amount: bSent,
                                destination: msg.from,
                                responseDestination: myAddress(),
                                customPayload: null,
                                forwardTonAmount: ton("0.01"),
                                forwardPayload: emptySlice()
                            }.toCell()
                        }
                    );
                } else {
                    self.reply(TokenTransfer{queryId: 0,
                            amount: msg.amount,
                            destination: msg.from,
                            responseDestination: myAddress(),
                            customPayload: null,
                            forwardTonAmount: ton("0.01"),
                            forwardPayload: emptySlice()
                        }.toCell()
                    );
                }
            }
        } else if (sender() == self.jettonAddressB) {
            if (msg.from == self.owner) {
                self.bAmount = self.bAmount + msg.amount;
            } else {
                if (msg.amount <= self.bAmount) {
                    let aSent: Int = self.aAmount * self.decimal / self.bAmount * msg.amount / self.decimal;
                    self.bAmount = self.bAmount + msg.amount;
                    self.aAmount = self.aAmount - aSent;
                    send(SendParameters{to: sender(),
                            bounce: true,
                            value: 0,
                            body: TokenTransfer{queryId: 0,
                                amount: aSent,
                                destination: msg.from,
                                responseDestination: myAddress(),
                                customPayload: null,
                                forwardTonAmount: ton("0.01"),
                                forwardPayload: emptySlice()
                            }.toCell(),
                            mode: SendPayGasSeparately
                        }
                    );
                } else {
                    self.reply(TokenTransfer{queryId: 0,
                            amount: msg.amount,
                            destination: msg.from,
                            responseDestination: myAddress(),
                            customPayload: null,
                            forwardTonAmount: ton("0.01"),
                            forwardPayload: emptySlice()
                        }.toCell()
                    );
                }
            }
        } else {
            throw(123);
        }
    }

    get fun price(jetton: Address): Int {
        if (jetton == self.jettonAddressA) {
            return self.aAmount * self.decimal / self.bAmount / self.decimal;
        } else {
            return self.bAmount * self.decimal / self.aAmount / self.decimal;
        }
    }

    get fun balance(jetton: Address): Int {
        if (jetton == self.jettonAddressA) {
            return self.aAmount;
        } else {
            return self.bAmount;
        }
    }
}