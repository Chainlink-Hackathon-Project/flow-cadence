flow transactions send ./cadence/transactions/createBounty.cdc 100000.0 yoflow   100000.0
flow transactions send ./cadence/transactions/createClaim.cdc 0 "aaaaaaaabve123"

flow transactions send ./cadence/transactions/cancelBounty.cdc 0
flow transactions send ./cadence/transactions/acceptClaim.cdc 0 0