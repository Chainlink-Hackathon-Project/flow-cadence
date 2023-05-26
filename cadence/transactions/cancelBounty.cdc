import FungibleToken from "../contracts/lib/FungibleToken.cdc"
import FlowToken from "../contracts/lib/FlowToken.cdc"
import Escrow from "../contracts/Escrow.cdc"

transaction(bountyId: UInt64) {
    prepare(account: AuthAccount){
        let bounty = Escrow.getBounty(bountyId: bountyId)
        let ticketHolder = account.borrow<&Escrow.TicketHolder>(from: /storage/ticketHolder) ?? panic("Could not borrow ticket holder")
        let ticket <- ticketHolder.withdraw(bounty.ticketUUID) !
        Escrow.cancelBounty(bountyId: bountyId, ticket: <- ticket)     
    }

    execute {
    }
}