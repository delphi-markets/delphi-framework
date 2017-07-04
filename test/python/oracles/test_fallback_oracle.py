from ..abstract_test import AbstractTestContracts, keys, TransactionFailed


class TestContracts(AbstractTestContracts):

    def __init__(self, *args, **kwargs):
        super(TestContracts, self).__init__(*args, **kwargs)
        self.math = self.create_contract('Utils/Math.sol')
        self.ether_token = self.create_contract('Tokens/EtherToken.sol', libraries={'Math': self.math})
        self.fallback_oracle_factory = self.create_contract('Oracles/FallbackOracleFactory.sol',
                                                            libraries={'Math': self.math})
        self.arbiter_factory = self.create_contract('Oracles/ArbiterFactory.sol')
        self.fallback_oracle_abi = self.create_abi('Oracles/FallbackOracle.sol')
        self.arbiter_abi = self.create_abi('Oracles/Arbiter.sol')

    def test(self):
        # Create oracles
        ipfs_hash = b'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG'
        arbiter = self.contract_at(self.arbiter_factory.createArbiter(ipfs_hash,),
                                              self.arbiter_abi)
        spread_multiplier = 3
        challenge_period = 200  # 200s
        challenge_amount = 100  # 100 Wei
        front_runner_period = 50  # 50s
        fallback_oracle = self.contract_at(
            self.fallback_oracle_factory.createFallbackOracle(arbiter.address, self.ether_token.address,
                                                              spread_multiplier, challenge_period, challenge_amount,
                                                              front_runner_period),
            self.fallback_oracle_abi)
        # Set outcome in central oracle
        arbiter.setOutcome(1)
        self.assertEqual(arbiter.getOutcome(), 1)
        # Set outcome in fallback oracle
        fallback_oracle.setForwardedOutcome()
        self.assertEqual(fallback_oracle.forwardedOutcome(), 1)
        self.assertFalse(fallback_oracle.isOutcomeSet())
        # Challenge outcome
        sender_1 = 0
        self.ether_token.deposit(value=100, sender=keys[sender_1])
        self.ether_token.approve(fallback_oracle.address, 100, sender=keys[sender_1])
        fallback_oracle.challengeOutcome(2)
        self.assertEqual(fallback_oracle.frontRunner(), 2)
        # Sender 2 overbids sender 1
        sender_2 = 1
        self.ether_token.deposit(value=200, sender=keys[sender_2])
        self.ether_token.approve(fallback_oracle.address, 200, sender=keys[sender_2])
        fallback_oracle.voteForOutcome(3, 200, sender=keys[sender_2])
        self.assertEqual(fallback_oracle.frontRunner(), 3)
        # Trying to withdraw before front runner period ends fails
        self.assertRaises(TransactionFailed, fallback_oracle.withdraw, sender=keys[sender_2])
        # Wait for front runner period to pass
        self.assertFalse(fallback_oracle.isOutcomeSet())
        self.s.block.timestamp += front_runner_period + 1
        self.assertTrue(fallback_oracle.isOutcomeSet())
        self.assertEqual(fallback_oracle.getOutcome(), 3)
        # Withdraw winnings
        self.assertEqual(fallback_oracle.withdraw(sender=keys[sender_2]), 300)
