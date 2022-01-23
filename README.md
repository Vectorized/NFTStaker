Gas optimized NFT staker
========================

**Install:**

cd into the directory and run

```
npm install
```

**Test:**

```
npx hardhat test
```

**To generate packed rates:**
1. cd into `rates_packer` directory.
2. Edit the `rarities.json`.
3. Run `node pack.js`
4. Examine the generated `rates.json` and copy the values to (Remix, Etherscan, etc) to write to the contract.

