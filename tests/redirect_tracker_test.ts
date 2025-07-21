import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';

Clarinet.test({
  name: "Verify goal visibility modification works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const testUser = accounts.get('wallet_1')!;

    // Create a test goal hash
    const goalHash = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    
    // Modify goal visibility (successful case)
    let block = chain.mineBlock([
      Tx.contractCall('redirect-tracker', 'modify-goal-visibility', 
        [types.buff(goalHash), types.uint(1)], 
        testUser.address)
    ]);

    // Check the result
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Prevent unauthorized goal visibility modification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const testUser = accounts.get('wallet_1')!;
    const anotherUser = accounts.get('wallet_2')!;

    // Create a test goal hash
    const goalHash = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    
    // Attempt to modify goal visibility by unauthorized user
    let block = chain.mineBlock([
      Tx.contractCall('redirect-tracker', 'modify-goal-visibility', 
        [types.buff(goalHash), types.uint(1)], 
        anotherUser.address)
    ]);

    // Check that the call fails with not authorized error
    block.receipts[0].result.expectErr().expectUint(200);
  }
});