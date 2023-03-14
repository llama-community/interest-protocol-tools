// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Proposal {
    /// @notice Unique id for looking up a proposal
    uint256 id;
    /// @notice Creator of the proposal
    address proposer;
    /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    /// @notice the ordered list of target addresses for calls to be made
    address[] targets;
    /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    /// @notice The ordered list of function signatures to be called
    string[] signatures;
    /// @notice The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    /// @notice The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    /// @notice The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    /// @notice Current number of votes in favor of this proposal
    uint256 forVotes;
    /// @notice Current number of votes in opposition to this proposal
    uint256 againstVotes;
    /// @notice Current number of votes for abstaining for this proposal
    uint256 abstainVotes;
    /// @notice Flag marking whether the proposal has been canceled
    bool canceled;
    /// @notice Flag marking whether the proposal has been executed
    bool executed;
    /// @notice Whether the proposal is an emergency proposal
    bool emergency;
    /// @notice quorum votes requires
    uint256 quorumVotes;
    /// @notice time delay
    uint256 delay;
}

interface IGovernorCharlieDelegate {
    /// @notice The total number of proposals
    function proposalCount() external view returns (uint256);

    /// @notice The official record of all proposals ever proposed
    function proposals(uint256 proposalId) external view returns (Proposal memory);

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
