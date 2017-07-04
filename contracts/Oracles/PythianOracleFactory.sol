pragma solidity 0.4.11;
import "../Oracles/PythianOracle.sol";


/// @title Majority oracle factory contract - Allows creation of majority oracle contracts
/// @author Delphi - <delphimarkets@gmail.com>
contract PythianOracleFactory {

    /*
     *  Events
     */
    event PythianOracleCreation(address indexed creator, PythianOracle pythianOracle, Oracle[] oracles, uint[] weights, uint weightThreshold);

    /*
     *  Public functions
     */
    /// @dev Creates a new majority oracle contract
    /// @param oracles List of oracles taking part in the majority vote
    /// @return Oracle contract
    function createPythianOracle(Oracle[] oracles, uint[] weights, uint weightThreshold)
        public
        returns (PythianOracle pythianOracle)
    {
        pythianOracle = new PythianOracle(oracles, weights, weightThreshold);
        PythianOracleCreation(msg.sender, pythianOracle, oracles, weights, weightThreshold);
    }
}
