pragma solidity 0.4.11;
import "../Oracles/Arbiter.sol";


/// @title Arbiter factory contract - Allows creation of arbiter oracle contracts
/// @author Delphi - <delphimarkets@gmail.com>
contract ArbiterFactory {

    /*
     *  Events
     */
    event ArbiterCreation(address indexed creator, Arbiter arbiter, bytes ipfsHash);

    /*
     *  Public functions
     */
    /// @dev Creates a new arbiter oracle contract
    /// @param ipfsHash Hash identifying off chain event description
    /// @return Oracle contract
    function createArbiter(bytes ipfsHash)
        public
        returns (Arbiter arbiter)
    {
        arbiter = new Arbiter(msg.sender, ipfsHash);
        ArbiterCreation(msg.sender, arbiter, ipfsHash);
    }
}
