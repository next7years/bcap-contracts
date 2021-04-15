## Useful commands to help you get started with the dev

See the accounts
```
npx hardhat accounts
```

Compile contracts, file is under contracts/
```
npx hardhat compile
```

Test contracts, test file is under test/
```
npx hardhat test
```

Deploy contracts by running the scripts under scripts/
```
npx hardhat run scripts/xxx.js
```

Test your deployed contracts with metamask or other wallet
```
npx hardhat node
``` 
Then use your metamask connect to http://127.0.0.1:8545/