// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable reason-string */

import {Ownable} from "@openzeppelin-v5.0.0/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin-v5.0.0/contracts/utils/introspection/IERC165.sol";
import {IEntryPoint} from "@account-abstraction-v7/interfaces/IEntryPoint.sol";

import {EntryPointValidator} from "../interfaces/EntryPointValidator.sol";

/**
 * Helper class for creating a paymaster.
 * provides helper methods for staking.
 * Validates that the postOp is called only by the entryPoint.
 */
abstract contract BaseMultiPaymaster is Ownable, EntryPointValidator {
    mapping(address entryPoints => bool isValidEntryPoint) public entryPoints;

    constructor(address[] memory _entryPoints, address _owner) Ownable(_owner) {
        for (uint256 i = 0; i < _entryPoints.length; i++) {
            entryPoints[_entryPoints[i]] = true;
        }
    }

    function removeEntryPoint(address _entryPoint) public onlyOwner {
        entryPoints[_entryPoint] = false;
    }

    function addEntryPoint(address _entryPoint) public onlyOwner {
        entryPoints[_entryPoint] = true;
    }

    /**
     * Add a deposit for this paymaster, used for paying for transaction fees.
     */
    function deposit(address entryPoint) public payable {
        IEntryPoint(entryPoint).depositTo{value: msg.value}(address(this));
    }

    /**
     * Withdraw value from the deposit.
     * @param withdrawAddress - Target to send to.
     * @param amount          - Amount to withdraw.
     */
    function withdrawTo(address entryPoint, address payable withdrawAddress, uint256 amount) public onlyOwner {
        IEntryPoint(entryPoint).withdrawTo(withdrawAddress, amount);
    }

    /**
     * Add stake for this paymaster.
     * This method can also carry eth value to add to the current stake.
     * @param unstakeDelaySec - The unstake delay for this paymaster. Can only be increased.
     */
    function addStake(address entryPoint, uint32 unstakeDelaySec) external payable onlyOwner {
        IEntryPoint(entryPoint).addStake{value: msg.value}(unstakeDelaySec);
    }

    /**
     * Return current paymaster's deposit on the entryPoint.
     */
    function getDeposit(address entryPoint) public view returns (uint256) {
        return IEntryPoint(entryPoint).balanceOf(address(this));
    }

    /**
     * Unlock the stake, in order to withdraw it.
     * The paymaster can't serve requests once unlocked, until it calls addStake again
     */
    function unlockStake(address entryPoint) external onlyOwner {
        IEntryPoint(entryPoint).unlockStake();
    }

    /**
     * Withdraw the entire paymaster's stake.
     * stake must be unlocked first (and then wait for the unstakeDelay to be over)
     * @param withdrawAddress - The address to send withdrawn value.
     */
    function withdrawStake(address entryPoint, address payable withdrawAddress) external onlyOwner {
        IEntryPoint(entryPoint).withdrawStake(withdrawAddress);
    }

    /**
     * Validate the call is made from a valid entrypoint
     */
    function _requireFromEntryPoint() internal view override {
        require(entryPoints[msg.sender], "Sender not EntryPoint");
    }
}