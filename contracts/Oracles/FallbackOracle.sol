pragma solidity 0.4.11;
import "../Oracles/Oracle.sol";
import "../Tokens/Token.sol";
import "../Utils/Math.sol";


/// @title Fallback oracle contract - Allows the swap of an oracle result for fallback oracle result
/// @author Delphi - <delphimarkets@gmail.com>
contract FallbackOracle is Oracle {
    using Math for *;

    /*
     *  Events
     */
    event ForwardedOracleOutcomeAssignment(int outcome);
    event OutcomeChallenge(address indexed sender, int outcome);
    event OutcomeVote(address indexed sender, int outcome, uint amount);
    event Withdrawal(address indexed sender, uint amount);

    /*
     *  State
     */
    Oracle public forwardedOracle;
    Token public collateralToken;
    uint8 public spreadMultiplier;
    uint public challengeWindow;
    uint public challengeAmount;
    uint public frontRunnerPeriod;

    int public forwardedOutcome;
    uint public forwardedOutcomeSetTimestamp;
    int public frontRunner;
    uint public frontRunnerSetTimestamp;

    uint public totalAmount;
    mapping (int => uint) public totalOutcomeAmounts;
    mapping (address => mapping (int => uint)) public outcomeAmounts;

    /*
     *  Public functions
     */
    /// @dev Constructor sets FallbackOracle properties
    /// @param _forwardedOracle Oracle address
    /// @param _collateralToken Collateral token address
    /// @param _spreadMultiplier Defines the spread as a multiple of the money bet on other outcomes
    /// @param _challengeWindow Time (seconds) in which oracle outcome can be challenged
    /// @param _challengeAmount Amount to challenge the outcome
    /// @param _frontRunnerPeriod Time to overbid the front-runner
    function FallbackOracle(
        Oracle _forwardedOracle,
        Token _collateralToken,
        uint8 _spreadMultiplier,
        uint _challengeWindow,
        uint _challengeAmount,
        uint _frontRunnerPeriod
    )
        public
    {
        // Validate inputs
        require(   address(_forwardedOracle) != 0
                && address(_collateralToken) != 0
                && _spreadMultiplier >= 2
                && _challengeWindow > 0
                && _challengeAmount > 0
                && _frontRunnerPeriod > 0);
        forwardedOracle = _forwardedOracle;
        collateralToken = _collateralToken;
        spreadMultiplier = _spreadMultiplier;
        challengeWindow = _challengeWindow;
        challengeAmount = _challengeAmount;
        frontRunnerPeriod = _frontRunnerPeriod;
    }

    /// @dev Allows setting of oracle outcome
    function setForwardedOutcome()
        public
    {
        // There was no challenge and the outcome was not set yet in the fallback oracle but in the forwarded oracle
        require(   !isChallenged()
                && forwardedOutcomeSetTimestamp == 0
                && forwardedOracle.isOutcomeSet());
        forwardedOutcome = forwardedOracle.getOutcome();
        forwardedOutcomeSetTimestamp = now;
        ForwardedOracleOutcomeAssignment(forwardedOutcome);
    }

    /// @dev Allows challenge of the oracle outcome
    /// @param _outcome Outcome to bid on
    function challengeOutcome(int _outcome)
        public
    {
        // There was no challenge yet or the challenge period expired
        require(   !isChallenged()
                && !isChallengeWindowOver()
                && collateralToken.transferFrom(msg.sender, this, challengeAmount));
        outcomeAmounts[msg.sender][_outcome] = challengeAmount;
        totalOutcomeAmounts[_outcome] = challengeAmount;
        totalAmount = challengeAmount;
        frontRunner = _outcome;
        frontRunnerSetTimestamp = now;
        OutcomeChallenge(msg.sender, _outcome);
    }

    /// @dev Allows challenge of the oracle outcome
    /// @param _outcome Outcome to bid on
    /// @param amount Amount to bid
    function voteForOutcome(int _outcome, uint amount)
        public
    {
        uint maxAmount = (totalAmount - totalOutcomeAmounts[_outcome]).mul(spreadMultiplier);
        if (amount > maxAmount)
            amount = maxAmount;
        // Outcome is challenged and front runner period is not over yet and tokens can be transferred
        require(   isChallenged()
                && !isFrontRunnerPeriodOver()
                && collateralToken.transferFrom(msg.sender, this, amount));
        outcomeAmounts[msg.sender][_outcome] = outcomeAmounts[msg.sender][_outcome].add(amount);
        totalOutcomeAmounts[_outcome] = totalOutcomeAmounts[_outcome].add(amount);
        totalAmount = totalAmount.add(amount);
        if (_outcome != frontRunner && totalOutcomeAmounts[_outcome] > totalOutcomeAmounts[frontRunner])
        {
            frontRunner = _outcome;
            frontRunnerSetTimestamp = now;
        }
        OutcomeVote(msg.sender, _outcome, amount);
    }

    /// @dev Withdraws winnings for user
    /// @return Winnings
    function withdraw()
        public
        returns (uint amount)
    {
        // Outcome was challenged and fallback outcome decided
        require(isFrontRunnerPeriodOver());
        amount = totalAmount.mul(outcomeAmounts[msg.sender][frontRunner]) / totalOutcomeAmounts[frontRunner];
        outcomeAmounts[msg.sender][frontRunner] = 0;
        // Transfer earnings to contributor
        require(collateralToken.transfer(msg.sender, amount));
        Withdrawal(msg.sender, amount);
    }

    /// @dev Checks if time to challenge the outcome is over
    /// @return Is challenge period over?
    function isChallengeWindowOver()
        public
        returns (bool)
    {
        return forwardedOutcomeSetTimestamp != 0 && now.sub(forwardedOutcomeSetTimestamp) > challengeWindow;
    }

    /// @dev Checks if time to overbid the front runner is over
    /// @return Is front runner period over?
    function isFrontRunnerPeriodOver()
        public
        returns (bool)
    {
        return frontRunnerSetTimestamp != 0 && now.sub(frontRunnerSetTimestamp) > frontRunnerPeriod;
    }

    /// @dev Checks if outcome was challenged
    /// @return Is challenged?
    function isChallenged()
        public
        returns (bool)
    {
        return frontRunnerSetTimestamp != 0;
    }

    /// @dev Returns if winning outcome is set
    /// @return Is outcome set?
    function isOutcomeSet()
        public
        constant
        returns (bool)
    {
        return    isChallengeWindowOver() && !isChallenged()
               || isFrontRunnerPeriodOver();
    }

    /// @dev Returns winning outcome
    /// @return Outcome
    function getOutcome()
        public
        constant
        returns (int)
    {
        if (isFrontRunnerPeriodOver())
            return frontRunner;
        return forwardedOutcome;
    }
}
