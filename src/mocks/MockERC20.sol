// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockERC20 is ERC20, ERC20Permit, ERC20Pausable, ERC20Burnable {
    uint8 public immutable DECIMALS;

    constructor(uint256 _initialSupply, uint8 _decimals) ERC20("Mock Token", "MOCK") ERC20Permit("Mock Token") {
        _mint(msg.sender, _initialSupply);
        DECIMALS = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }

    // The following function is an override required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
