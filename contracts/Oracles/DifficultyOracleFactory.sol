pragma solidity 0.4.11;
import "../Oracles/DifficultyOracle.sol";


/// @title Difficulty oracle factory contract - Allows cration of difficulty oracle contracts
/// @author Delphi - <delphimarkets@gmail.com>
contract DifficultyOracleFactory {

    /*
     *  Events
     */
    event DifficultyOracleCreation(address indexed creator, DifficultyOracle difficultyOracle, uint blockNumber);

    /*
     *  Public functions
     */
    /// @dev Creates a new difficulty oracle contract
    /// @param blockNumber Target block number
    /// @return Oracle contract
    function createDifficultyOracle(uint blockNumber)
        public
        returns (DifficultyOracle difficultyOracle)
    {
        difficultyOracle = new DifficultyOracle(blockNumber);
        DifficultyOracleCreation(msg.sender, difficultyOracle, blockNumber);
    }
}
