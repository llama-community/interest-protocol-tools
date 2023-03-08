// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGovernorCharlieDelegate {
    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @param emergency Bool to determine if proposal an emergency proposal
     * @return Proposal id of new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        bool emergency
    ) external returns (uint256);
}

library IPGovernance {
    IGovernorCharlieDelegate internal constant GOV =
        IGovernorCharlieDelegate(0x266d1020A84B9E8B0ed320831838152075F8C4cA);
}
