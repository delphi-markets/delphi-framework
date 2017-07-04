pragma solidity 0.4.11;
import "../Oracles/FallbackOracle.sol";


/// @title Fallback oracle factory contract - Allows creation of fallback oracle contracts
/// @author Delphi - <delphimarkets@gmail.com>
contract FallbackOracleFactory {

    /*
     *  Events
     */
    event FallbackOracleCreation(
        address indexed creator,
        FallbackOracle fallbackOracle,
        Oracle oracle,
        Token collateralToken,
        uint8 spreadMultiplier,
        uint challengeWindow,
        uint challengeAmount,
        uint frontRunnerPeriod
    );

    /*
     *  Public functions
     */
    /// @dev Creates a new FallbackOracle contract
    /// @param oracle Oracle address
    /// @param collateralToken Collateral token address
    /// @param spreadMultiplier Defines the spread as a multiple of the money staked on other outcomes
    /// @param challengeWindow Time (seconds) in which oracle outcome can be challenged
    /// @param challengeAmount Amount to challenge outcome
    /// @param frontRunnerPeriod Time to overbid the front-runner
    /// @return Oracle contract
    function createFallbackOracle(
        Oracle oracle,
        Token collateralToken,
        uint8 spreadMultiplier,
        uint challengeWindow,
        uint challengeAmount,
        uint frontRunnerPeriod
    )
        public
        returns (FallbackOracle fallbackOracle)
    {
        fallbackOracle = new FallbackOracle(
            oracle,
            collateralToken,
            spreadMultiplier,
            challengeWindow,
            challengeAmount,
            frontRunnerPeriod
        );
        FallbackOracleCreation(
            msg.sender,
            fallbackOracle,
            oracle,
            collateralToken,
            spreadMultiplier,
            challengeWindow,
            challengeAmount,
            frontRunnerPeriod
        );
    }
}
