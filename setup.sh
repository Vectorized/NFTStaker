npm init -y; 
npm install --save-dev hardhat;
npm install --save-dev @openzeppelin/contracts;
npm install --save-dev @nomiclabs/hardhat-ethers ethers;
npm install --save-dev chai;
npm install --save-dev @openzeppelin/test-helpers;
npm install --save-dev @rari-capital/solmate;

# npm install --save-dev @openzeppelin/contracts@3.4.0; #for solc-0.7.0

# npx hardhat compile; #compile
# npx hardhat node; #start local blockchain
# npx hardhat run --network localhost ./scripts/deploy.js
# npx hardhat run --network localhost ./scripts/index.js
# npx hardhat console --network localhost; #start node cli
# npx hardhat test; #test the contracts