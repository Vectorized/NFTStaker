// Load dependencies
const { expect } = require('chai');

// Start test block
describe('NFTStaker', function () {

	this.timeout(2000000000);

	const contractNames = ['NFT', 'Coin', 'NFTStaker'];

	function getRandomSubarray(arr, size) {
	    var shuffled = arr.slice(0), i = arr.length, temp, index;
	    while (i--) {
	        index = Math.floor((i + 1) * Math.random());
	        temp = shuffled[index];
	        shuffled[index] = shuffled[i];
	        shuffled[i] = temp;
	    }
	    return shuffled.slice(0, size);
	}

	before(async function () {
		this.factories = {};
		for (var i = 0; i < contractNames.length; ++i) {
			const name = contractNames[i];
			this.factories[name] = await ethers.getContractFactory(name);
		}
		
	});

	beforeEach(async function () {
		this.contracts = {};
		for (var i = 0; i < contractNames.length; ++i) {
			const name = contractNames[i];
			this.contracts[name] = await this.factories[name].deploy(); 
		}
		
	});

	var NFT, Coin, NFTStaker, coinSupply, stakeSupply, signers;
	var BN; // BigNumber constructor
	
	it('Init all.', async function () {
		
		signers = await ethers.getSigners();
		
		NFT = this.contracts.NFT;
		Coin = this.contracts.Coin;
		NFTStaker = this.contracts.NFTStaker;

		coinSupply = await Coin.connect(signers[0]).totalSupply();
		BN = coinSupply.constructor.from;

		stakeSupply = coinSupply.mul(60).div(100);

		expect(coinSupply.toString())
			.to.equal('1000000000000000000000000');

	});

	it('Mint NFTs.', async function () {
		await NFT.connect(signers[1]).mint(30);
		await NFT.connect(signers[2]).mint(30);
	});

	it('Stake and Unstake.', async function () {

		for (var t = 0; t < 10; ++t) {
			var i = 1 + Math.floor(Math.random() * 2);

			await NFT.connect(signers[i]).setApprovalForAll(NFTStaker.address, true);
			
			var tokenIds = await NFT.connect(signers[i]).tokensOfOwner(signers[i].address);

			var n = tokenIds.length;

			var m = 1 + Math.floor(Math.random() * (Math.min(n, 50) - 1));

			var toStake = getRandomSubarray(tokenIds, m);
			
			var expectedStakes = (
				await NFTStaker.connect(signers[i]).staked(signers[i].address)
			).concat(toStake);

			var expectedStakesString = expectedStakes.join(',');

			if (toStake.length > 0) {
				await NFTStaker.connect(signers[i]).stake(toStake);	
			}
			
			expect((await NFT.connect(signers[i]).tokensOfOwner(signers[i].address)).length)
				.to.equal(n - m);

			expect((await NFTStaker.connect(signers[i]).staked(signers[i].address)).join(','))
				.to.equal(expectedStakesString);

			var indices = [];
			if (Math.random() < 0.5) {
				for (var k = 0; k < expectedStakes.length; ++k) {
					indices.push(expectedStakes.length - 1 - k);
				}	
			} else {
				for (var k = 0; k < expectedStakes.length; ++k) {
					if (Math.random() < 0.5)
						indices.push(expectedStakes.length - 1 - k);
				}
				if (indices.length < 1)
					indices.push(0);
			}
			
			await NFTStaker.connect(signers[i]).unstake(indices, expectedStakes.length);
		}

		for (var i = 1; i <= 2; ++i) {
			var a = await NFTStaker.connect(signers[i]).staked(signers[i].address);
			if (a.length > 0) {
				var indices = [];
				for (var k = 0; k < a.length; ++k) {
					indices.push(a.length - 1 - k);
				}
				await NFTStaker.connect(signers[i]).unstake(indices, a.length);
				expect((await NFTStaker.connect(signers[i]).staked(signers[i].address)).length)
					.to.equal(0);
			}
		}
	});

	it('Stake and Harvest.', async function () {

		await Coin.connect(signers[0]).transfer(NFTStaker.address, stakeSupply);
		
		expect((await NFTStaker.connect(signers[0]).coinBalance()).toString())
			.to.equal(stakeSupply.toString());			

		for (var i = 1; i <= 2; ++i) {
			
			await NFT.connect(signers[i]).setApprovalForAll(NFTStaker.address, true);

			var tokenIds = await NFT.connect(signers[i]).tokensOfOwner(signers[i].address);
			
			var toStake = tokenIds;
			var tx = await NFTStaker.connect(signers[i]).stake(toStake);
			var receipt = await tx.wait();

			var harvest = 0;

			try {
				harvest = await NFTStaker.connect(signers[i]).callStatic.harvest();
			} catch (e) {}

			expect(harvest).to.equal(0);
			
		}

		await NFTStaker.connect(signers[0]).setBlockNum(Math.floor(86400 / 13 * 180));

		for (var i = 1; i <= 2; ++i) {
			
			var harvest = await NFTStaker.connect(signers[i]).callStatic.harvest();
			expect(harvest).not.to.equal(0);
			
		}

	})

});