/*
    Escrow contract.

    Users can create an escrow.
    Users can create a claim for a particular escrow.
    The creator of the escrow can accept or reject any open claims.

    - create escrow
    - claim escrow

 */

 import FungibleToken from "./lib/FungibleToken.cdc"

pub contract Escrow {

    pub let bountys: @{UInt64: Bounty}
    pub let claims: {UInt64: Claim} 

    pub var nextbountyId: UInt64
    pub var nextClaimId: UInt64

    pub event BountyCreated(bountyId: UInt64, message: String)
    pub event ClaimCreated(claimId: UInt64, bountyId: UInt64, message: String)
    pub event ClaimAccepted(claimId: UInt64, bountyId: UInt64)

    // simple resource to act as unique identifier for escrow
    pub resource Ticket {}

    pub resource TicketHolder {
        pub let tickets: @{UInt64: Ticket}

        init() {
            self.tickets <- {}
        }

        pub fun deposit(_ ticket: @Ticket) {
            self.tickets[ticket.uuid] <-! ticket
        }

        pub fun withdraw(_ id: UInt64): @Ticket {
            let ticket <- self.tickets.remove(key: id) ?? panic("Ticket not found")
            return <-ticket
        }

        pub fun getTicketIds(): [UInt64] {
            return self.tickets.keys
        }

        destroy() {
            destroy self.tickets
        }
    }

    pub fun createTicketHolder(): @TicketHolder {
        return <- create TicketHolder()
    }

    pub struct BountyMeta {
        pub let balance: UFix64
        pub let ticketUUID: UInt64
        pub let message: String

        init(balance: UFix64, ticketUUID: UInt64, message: String) {
            self.balance = balance
            self.ticketUUID = ticketUUID
            self.message = message
        }
    }

    // resource that holds the escrowed funds
    pub resource Bounty {
        pub let funds: @FungibleToken.Vault
        pub let ticketUUID: UInt64
        pub let message: String

        init(funds: @FungibleToken.Vault, ticketUUID: UInt64, message: String) {
            self.funds <- funds
            self.ticketUUID = ticketUUID
            self.message = message
        }

        pub fun getMetadata(): BountyMeta {
            return BountyMeta(
                balance: self.funds.balance,
                ticketUUID: self.ticketUUID,
                message: self.message
            )
        }

        destroy() {
            destroy self.funds
        }
    }

    pub fun createBounty(funds: @FungibleToken.Vault, message: String): @Ticket {
        let bountyId = UInt64(self.nextbountyId)
        let ticket <- create Ticket()
        let bounty <- create Bounty(funds: <-funds, ticketUUID: ticket.uuid, message: message)
        self.bountys[bountyId] <-! bounty
        self.nextbountyId = self.nextbountyId + 1

        emit BountyCreated(bountyId: bountyId, message: message)

        return <- ticket
    }

    pub fun getBounty(bountyId: UInt64): BountyMeta {
        pre {
            self.bountys[bountyId] != nil: "Bounty does not exist"
        }
        return self.bountys[bountyId]?.getMetadata()!
    }

    pub fun getBountys(): {UInt64: AnyStruct} {
        let bountys: {UInt64: AnyStruct} = {}
        for id in self.bountys.keys {
            let bounty = &self.bountys[id] as &Bounty?
            bountys[id] = bounty?.getMetadata()
        } 
        return bountys
    }

    // a claim on an escrow
    pub struct Claim {
        pub let bountyId: UInt64
        pub let message: String
        pub let ftDepositCap: Capability<&{FungibleToken.Receiver}>

        pub fun getClaim(): {String:AnyStruct} {
            let claim: {String:AnyStruct} = {
                "bountyId": self.bountyId,
                "message": self.message
            }
            return claim
        }

        init(id: UInt64, message: String, ftDepositCap: Capability<&{FungibleToken.Receiver}>) {
            self.bountyId = id
            self.message = message
            self.ftDepositCap = ftDepositCap
        }
    }

    pub fun createClaim(bountyId: UInt64, message: String, ftDepositCap: Capability<&{FungibleToken.Receiver}>) {
        pre {
            self.bountys[bountyId] != nil: "Bounty does not exist"
        }
        let claim = Claim(id: bountyId, message: message, ftDepositCap: ftDepositCap)
        self.claims[self.nextClaimId] = claim
        self.nextClaimId = self.nextClaimId + 1

        emit ClaimCreated(claimId: self.nextClaimId - 1, bountyId: bountyId, message: message)
    }

    pub fun getClaims(): {UInt64: AnyStruct} {
        let claims: {UInt64: AnyStruct} = {}
        for id in self.claims.keys {
            let claim = self.claims[id]!
            claims[id] = claim.getClaim()
        }
        return claims
    }

    pub fun acceptClaim(bountyId: UInt64, claimId: UInt64, ticket: @Ticket) {
        pre {
            self.bountys[bountyId] != nil: "Bounty does not exist"
            self.claims[claimId] != nil: "Claim does not exist"
            ticket.uuid == self.bountys[bountyId]?.ticketUUID: "Ticket does not match bounty"
        }
        let claim = self.claims[claimId]!
        self.claims[claimId] = claim
        let bounty <- self.bountys[bountyId] <- nil
        claim.ftDepositCap.borrow()?.deposit(from: <-bounty?.funds?.withdraw(amount: bounty?.funds?.balance!)!)
        self.cleanUpClaims(bountyId: bountyId)
        destroy ticket
        destroy bounty
        emit ClaimAccepted(claimId: claimId, bountyId: bountyId)
    }

    access(contract) fun cleanUpClaims(bountyId: UInt64) {
        for id in self.claims.keys {
            let claim = self.claims[id]!
            if claim.bountyId == bountyId {
                self.claims[id] = nil
            }
        }
    }

    init() {
        self.nextbountyId = 0
        self.nextClaimId = 0

        self.bountys <- {}
        self.claims = {}
    }
}