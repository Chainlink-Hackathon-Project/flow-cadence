import FungibleToken from "../contracts/lib/FungibleToken.cdc"
import FlowToken from "../contracts/lib/FlowToken.cdc"
import Escrow from "../contracts/Escrow.cdc"

transaction(amount: UFix64, message: String) {
    let funds: @FungibleToken.Vault
    let ticketHolder: &Escrow.TicketHolder

    prepare(account: AuthAccount){

        if account.borrow<&Escrow.TicketHolder>(from: /storage/ticketHolder) == nil {
            let ticketHolder <- Escrow.createTicketHolder()
            account.save(<-ticketHolder, to: /storage/ticketHolder)            
        }
        // Get a reference to the signer's stored vault
        let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.funds <- vaultRef.withdraw(amount: amount)
        self.ticketHolder = account.borrow<&Escrow.TicketHolder>(from: /storage/ticketHolder) ?? panic("Could not borrow reference to the ticket holder")
    }

    execute {
        let resource <- Escrow.createBounty(funds: <- self.funds, message: message)
        self.ticketHolder.deposit(<-resource) 
    }
}