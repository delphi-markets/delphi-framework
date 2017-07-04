pragma solidity 0.4.11;
import "../Oracles/Oracle.sol";


/// @title Signed message oracle contract - Allows setting of an outcome with a signed message
/// @author Delphi - <delphimarkets@gmail.com>
contract SignedMessageOracle is Oracle {

    /*
     *  Events
     */
    event SignatoryReplacement(address indexed newSignatory);
    event OutcomeAssignment(int outcome);

    /*
     *  State
     */
    address public signatory;
    bytes32 public descriptionHash;
    uint nonce;
    bool public isSet;
    int public outcome;

    /*
     *  Modifiers
     */
    modifier isSignatory () {
        // Only signatory is allowed to proceed
        require(msg.sender == signatory);
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor sets signatory address based on signature
    /// @param _descriptionHash Hash identifying off chain event description
    /// @param v Signature parameter
    /// @param r Signature parameter
    /// @param s Signature parameter
    function SignedMessageOracle(bytes32 _descriptionHash, uint8 v, bytes32 r, bytes32 s)
        public
    {
        signatory = ecrecover(_descriptionHash, v, r, s);
        descriptionHash = _descriptionHash;
    }

    /// @dev Replaces signatory
    /// @param newSignatory New signatory
    /// @param _nonce Unique nonce to prevent replay attacks
    /// @param v Signature parameter
    /// @param r Signature parameter
    /// @param s Signature parameter
    function replaceSignatory(address newSignatory, uint _nonce, uint8 v, bytes32 r, bytes32 s)
        public
        isSignatory
    {
        // Result is not set yet and nonce and signatory are valid
        require(   !isSet
                && _nonce > nonce
                && signatory == ecrecover(keccak256(descriptionHash, newSignatory, _nonce), v, r, s));
        nonce = _nonce;
        signatory = newSignatory;
        SignatoryReplacement(newSignatory);
    }

    /// @dev Sets outcome based on signed message
    /// @param _outcome Signed event outcome
    /// @param v Signature parameter
    /// @param r Signature parameter
    /// @param s Signature parameter
    function setOutcome(int _outcome, uint8 v, bytes32 r, bytes32 s)
        public
    {
        // Result is not set yet and signatory is valid
        require(   !isSet
                && signatory == ecrecover(keccak256(descriptionHash, _outcome), v, r, s));
        isSet = true;
        outcome = _outcome;
        OutcomeAssignment(_outcome);
    }

    /// @dev Returns if winning outcome
    /// @return Is outcome set?
    function isOutcomeSet()
        public
        constant
        returns (bool)
    {
        return isSet;
    }

    /// @dev Returns winning outcome
    /// @return Outcome
    function getOutcome()
        public
        constant
        returns (int)
    {
        return outcome;
    }
}
