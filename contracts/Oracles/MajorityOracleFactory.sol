pragma solidity 0.4.11;
import "../Oracles/MajorityOracle.sol";


/// @title Majority oracle factory contract - Allows creation of majority oracle contracts
/// @author Delphi - <delphimarkets@gmail.com>
contract MajorityOracleFactory {

    /*
     *  Events
     */
    event MajorityOracleCreation(address indexed creator, MajorityOracle majorityOracle, Oracle[] oracles);

    /*
     *  Public functions
     */
    /// @dev Creates a new majority oracle contract
    /// @param oracles List of oracles taking part in the majority vote
    /// @return Oracle contract
    function createMajorityOracle(Oracle[] oracles)
        public
        returns (MajorityOracle majorityOracle)
    {
        majorityOracle = new MajorityOracle(oracles);
        MajorityOracleCreation(msg.sender, majorityOracle, oracles);
    }
}
