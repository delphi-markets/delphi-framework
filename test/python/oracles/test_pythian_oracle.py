from ..abstract_test import AbstractTestContracts, keys


class TestContracts(AbstractTestContracts):

    def __init__(self, *args, **kwargs):
        super(TestContracts, self).__init__(*args, **kwargs)
        self.majority_oracle_factory = self.create_contract('Oracles/MajorityOracleFactory.sol')
        self.arbiter_factory = self.create_contract('Oracles/ArbiterFactory.sol')
        self.majority_oracle_abi = self.create_abi('Oracles/MajorityOracle.sol')
        self.arbiter_abi = self.create_abi('Oracles/Arbiter.sol')

    def test(self):
        # Create oracles
        ipfs_hash = b'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG'
        owner_1 = 0
        owner_2 = 1
        owner_3 = 1
        oracle_1 = self.contract_at(self.arbiter_factory.createArbiter(ipfs_hash, sender=keys[owner_1]),
                                    self.arbiter_abi)
        oracle_2 = self.contract_at(self.arbiter_factory.createArbiter(ipfs_hash, sender=keys[owner_2]),
                                    self.arbiter_abi)
        oracle_3 = self.contract_at(self.arbiter_factory.createArbiter(ipfs_hash, sender=keys[owner_3]),
                                    self.arbiter_abi)
        majority_oracle = self.contract_at(self.majority_oracle_factory.createMajorityOracle([oracle_1.address, oracle_2.address, oracle_3.address]),
                                           self.majority_oracle_abi)
        # Majority oracle unable to resolve yet
        self.assertFalse(majority_oracle.isOutcomeSet())
        # Set outcome in first arbiter oracle
        oracle_1.setOutcome(1, sender=keys[owner_1])
        # Majority vote is not reached yet
        self.assertFalse(majority_oracle.isOutcomeSet())
        # Set outcome in second arbiter oracle
        oracle_2.setOutcome(1, sender=keys[owner_2])
        # Majority vote reached
        self.assertTrue(majority_oracle.isOutcomeSet())
        self.assertEqual(majority_oracle.getOutcome(), 1)
