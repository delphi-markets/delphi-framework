pragma solidity 0.4.11;
import "../Oracles/Oracle.sol";


/// @title Pythian oracle contract - Allows resolution of an event based on multiple voters in weighted vote schemes
/// @author Delphi - <delphimarkets@gmail.com>
contract PythianOracle is Oracle {

    /*
     *  State
     */
    Oracle[] public voters;
    uint[] public weights;
    uint public weightThreshold;

    /*
     *  Public functions
     */
    /// @dev Allows creation of a Pythian Oracle, determining outcome resolution based on weighted vote schemes
    /// @param _voters List of voters taking part in the vote
    /// @param _weights List of weights corresponding to voters
    function PythianOracle(Oracle[] _voters, uint[] _weights, uint _weightThreshold)
        public
    {
        // At least 3 voters must be defined for a meaningful majority
        require(_voters.length > 2);
        for (uint i = 0; i < _voters.length; i++)
            // Oracle address cannot be null
            require(address(_voters[i]) != 0);
        voters = _voters;
        weights = _weights;
        weightThreshold = _weightThreshold;
    }

    /// @dev Allows voter registration for a weight-impacted vote
    /// @return Is outcome set?
    /// @return Outcome
    function getStatusAndOutcome()
        public
        returns (bool outcomeSet, int outcome)
    {
        uint i;
        int[] memory outcomes = new int[](voters.length);
        uint[] memory validations = new uint[](voters.length);
        for (i = 0; i < voters.length; i++)
            if (voters[i].isOutcomeSet()) {
                int _outcome = voters[i].getOutcome();
                for (uint j = 0; j <= i; j++)
                    if (_outcome == outcomes[j]) {
                        validations[j] += weights[i];
                        break;
                    }
                    else if (validations[j] == 0) {
                        outcomes[j] = _outcome;
                        validations[j] = weights[i];
                        break;
                    }
            }
        uint outcomeValidations = 0;
        uint outcomeIndex = 0;
        for (i = 0; i < voters.length; i++)
            if (validations[i] > outcomeValidations) {
                outcomeValidations = validations[i];
                outcomeIndex = i;
            }
        // There is a majority vote
        if (outcomeValidations > weightThreshold) {
            outcomeSet = true;
            outcome = outcomes[outcomeIndex];
        }
    }

    /// @dev Returns true if winning outcome is set
    /// @return Is outcome set?
    function isOutcomeSet()
        public
        constant
        returns (bool)
    {
        var (outcomeSet, ) = getStatusAndOutcome();
        return outcomeSet;
    }

    /// @dev Returns winning outcome
    /// @return Outcome
    function getOutcome()
        public
        constant
        returns (int)
    {
        var (, winningOutcome) = getStatusAndOutcome();
        return winningOutcome;
    }
}
