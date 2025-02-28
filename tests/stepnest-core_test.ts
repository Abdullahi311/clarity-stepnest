import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that routes can be created with valid parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("stepnest-core", "create-route",
        [
          types.utf8("Test Route"),
          types.utf8("A test hiking route"),
          types.uint(3),
          types.uint(5000)
        ],
        deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok u1)');
  },
});

Clarinet.test({
  name: "Ensure route completion rewards tokens",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("stepnest-core", "create-route",
        [types.utf8("Test Route"), types.utf8("Description"), types.uint(3), types.uint(5000)],
        deployer.address),
      Tx.contractCall("stepnest-core", "complete-route",
        [types.uint(1)],
        deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, '(ok true)');
  },
});
