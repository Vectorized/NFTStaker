// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract Coin is ERC20 {

    constructor() ERC20("Coin", "Coin", 18) {
        _mint(msg.sender, 1000000 * 1000000000000000000);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            allowance[account][msg.sender] -= amount;
        }
        _burn(account, amount);
    }
}