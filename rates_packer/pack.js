var fs = require("fs");

const NUM_TIERS = 10;
const BITWIDTH_RATE = 4; // Min number of bits to represent 1 ... NUM_TIERS
const BITMOD_RATE = 256 / BITWIDTH_RATE;

var rarities;

try {
    rarities = JSON.parse(fs.readFileSync("rarities.json"));
    for (var i = 0; i < rarities.length; ++i) {
    	var numBelow = 0;
    	var tokenId = rarities[i][0];
    	var rarity = rarities[i][1];
    	for (var j = 0; j < rarities.length; ++j) {
    		if (rarities[j][1] < rarity) {
    			numBelow++;
    		}
    	}
    	var rate = Math.ceil((numBelow / rarities.length) * NUM_TIERS);
    	rate = Math.max(1, Math.min(rate, NUM_TIERS));
    	rarities[i].push(rate); 
    }
    
} catch (e) {
    rarities = null;
}

// Sort by tokenId
rarities.sort(function (a,b) { return a[0] - b[0] });

var nftRates = {indices: [], rates: []};
for (var i = 0; i < Math.ceil(rarities.length / BITMOD_RATE); ++i) {
	var a = [];
	for (var j = 0; j < BITMOD_RATE; ++j) {
		a.push('0');
	}
	nftRates.indices.push(i);
	nftRates.rates.push(a);
}

for (var i = 0; i < rarities.length; ++i) {
	var tokenId = rarities[i][0];
	var rate = rarities[i][2];

	var u = Math.floor(tokenId / BITMOD_RATE);
    var v = (tokenId % BITMOD_RATE);
    
    nftRates.rates[u][v] = rate.toString(16);
}

for (var i = 0; i < Math.ceil(rarities.length / BITMOD_RATE); ++i) {
	nftRates.rates[i] = '0x' + nftRates.rates[i].reverse().join('');
}

fs.writeFileSync('rates.json', 
    JSON.stringify(nftRates, null, 4));