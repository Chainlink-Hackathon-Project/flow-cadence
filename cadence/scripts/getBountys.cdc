
import Escrow from "../contracts/Escrow.cdc"

pub fun main(): {UInt64: AnyStruct} {
    return Escrow.getBountys()
}