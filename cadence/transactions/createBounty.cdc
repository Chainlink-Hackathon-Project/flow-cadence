import FungibleToken from "../contracts/lib/FungibleToken.cdc"
import FlowToken from "../contracts/lib/FlowToken.cdc"
import Escrow from "../contracts/Escrow.cdc"

transaction(amount: UFix64, message: String, duration: UFix64) {
    let funds: @FungibleToken.Vault
    let ftDepositCap: Capability<&{FungibleToken.Receiver}>
    let ticketHolder: &Escrow.TicketHolder

    prepare(signer: AuthAccount){

        if signer.borrow<&Escrow.TicketHolder>(from: /storage/ticketHolder) == nil {
            let ticketHolder <- Escrow.createTicketHolder()
            signer.save(<-ticketHolder, to: /storage/ticketHolder)            
        }

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Get a capability for the signer's stored vault to return funds if they cancel
        self.ftDepositCap = signer.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        // Withdraw tokens from the signer's stored vault
        self.funds <- vaultRef.withdraw(amount: amount)
        self.ticketHolder = signer.borrow<&Escrow.TicketHolder>(from: /storage/ticketHolder) ?? panic("Could not borrow reference to the ticket holder")
    }

    execute {
        let resource <- Escrow.createBounty(funds: <- self.funds, message: message, duration: duration, ftDepositCap: self.ftDepositCap)
        self.ticketHolder.deposit(<-resource)
    }
}