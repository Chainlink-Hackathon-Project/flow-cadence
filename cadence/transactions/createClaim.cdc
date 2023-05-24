import FungibleToken from "../contracts/lib/FungibleToken.cdc"
import FlowToken from "../contracts/lib/FlowToken.cdc"
import Escrow from "../contracts/Escrow.cdc"

transaction(bountyId: UInt64, message: String) {
    prepare(account: AuthAccount){
        let ftDepositCap = account.getCapability<&FungibleToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        Escrow.createClaim(bountyId: bountyId, message: message, ftDepositCap: ftDepositCap)       
    }

    execute {
    }
}