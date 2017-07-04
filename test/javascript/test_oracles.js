const utils = require('./utils')

const { wait } = require('@digix/tempo')(web3)

const EtherToken = artifacts.require('EtherToken')
const Arbiter = artifacts.require('Arbiter')
const ArbiterFactory = artifacts.require('ArbiterFactory')
const DifficultyOracle = artifacts.require('DifficultyOracle')
const DifficultyOracleFactory = artifacts.require('DifficultyOracleFactory')
const MajorityOracle = artifacts.require('MajorityOracle')
const MajorityOracleFactory = artifacts.require('MajorityOracleFactory')
const FallbackOracle = artifacts.require('FallbackOracle')
const FallbackOracleFactory = artifacts.require('FallbackOracleFactory')

contract('Oracle', function (accounts) {
    let arbiterFactory
    let difficultyOracleFactory
    let majorityOracleFactory
    let fallbackOracleFactory
    let etherToken
    let ipfsHash, ipfsBytes
    let spreadMultiplier, challengeWindow, challengeAmount, frontRunnerPeriod

    beforeEach(async () => {
        // deployed factory contracts
        arbiterFactory = await ArbiterFactory.deployed()
        difficultyOracleFactory = await DifficultyOracleFactory.deployed()
        majorityOracleFactory = await MajorityOracleFactory.deployed()
        fallbackOracleFactory = await FallbackOracleFactory.deployed()
        etherToken = await EtherToken.deployed()

        // ipfs hashes
        ipfsHash = 'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG'
        ipfsBytes = '0x516d597741504a7a7635435a736e4136323573335866326e656d7459675070486457457a37396f6a576e50626447'

        // Fallback oracle stuff
        spreadMultiplier = 3
        challengeWindow = 200 // 200s
        challengeAmount = 100 // 100wei
        frontRunnerPeriod = 50 // 50s
    })

    it('test arbiter oracle', async () => {
        // Create arbiter oracle factory
        const owner1 = 0
        const owner2 = 1

        // create arbiter oracle
        const arbiter = utils.getParamFromTxEvent(
            await arbiterFactory.createArbiter(ipfsHash, { from: accounts[owner1] }),
            'arbiter', Arbiter
        )
        // Replace account resolving outcome
        assert.equal(await arbiter.owner(), accounts[owner1])
        await arbiter.replaceOwner(accounts[owner2], {from: accounts[owner1]})
        assert.equal(await arbiter.owner(), accounts[owner2])

        // Set outcome
        await utils.assertRejects(arbiter.setOutcome(0, {from: accounts[owner1]}), "owner1 is not the arbiter oracle owner")
        assert.equal(await arbiter.isOutcomeSet(), false)

        await arbiter.setOutcome(1, {from: accounts[owner2]})
        assert.equal(await arbiter.isOutcomeSet(), true)
        assert.equal(await arbiter.getOutcome(), 1)
        assert.equal(await arbiter.ipfsHash(), ipfsBytes)
    })

    it('test difficulty oracle', async () => {
        // Create difficulty oracle
        const targetBlock = (await web3.eth.getBlock('latest')).number + 100
        const difficultyOracle = utils.getParamFromTxEvent(
            await difficultyOracleFactory.createDifficultyOracle(targetBlock),
            'difficultyOracle', DifficultyOracle
        )

        // Set outcome
        await utils.assertRejects(difficultyOracle.setOutcome())
        assert.equal(await difficultyOracle.isOutcomeSet(), false)

        // TODO: TestRPC difficulty is 0, so these tests won't pass there

        // // Wait until block 100
        // await waitUntilBlock(20, targetBlock)

        // await difficultyOracle.setOutcome()
        // assert.equal(await difficultyOracle.isOutcomeSet(), true)
        // assert.isAbove(await difficultyOracle.getOutcome(), 0)
    })

    // TODO: test futarchy oracle

    it('test majority oracle', async () => {
        // create Oracles
        const owners = [0, 1, 2]
        const oracles = (await Promise.all(
            owners.map((owner) => arbiterFactory.createArbiter(ipfsHash, {from: accounts[owner]}))
        )).map((tx) => utils.getParamFromTxEvent(tx, 'arbiter', Arbiter))

        const majorityOracle = utils.getParamFromTxEvent(
            await majorityOracleFactory.createMajorityOracle(oracles.map((o) => o.address)),
            'majorityOracle', MajorityOracle
        )

        // Majority oracle cannot be resolved yet
        assert.equal(await majorityOracle.isOutcomeSet(), false)

        // Set outcome in first arbiter oracle
        await oracles[0].setOutcome(1, { from: accounts[owners[0]] })

        // Majority vote is not reached yet
        assert.equal(await majorityOracle.isOutcomeSet(), false)

        // Set outcome in second arbiter oracle
        await oracles[1].setOutcome(1, { from: accounts[owners[1]] })

        // // majority vote is reached
        assert.equal(await majorityOracle.isOutcomeSet(), true)
        assert.equal(await majorityOracle.getOutcome(), 1)
    })

    // TODO: test signed message oracle

    it('test fallback oracle', async () => {
        // Create Oracles
        const arbiter = utils.getParamFromTxEvent(
            await arbiterFactory.createArbiter(ipfsHash),
            'arbiter', Arbiter
        )
        const fallbackOracle = utils.getParamFromTxEvent(
            await fallbackOracleFactory.createFallbackOracle(
                arbiter.address, etherToken.address,
                spreadMultiplier, challengeWindow, challengeAmount, frontRunnerPeriod),
            'fallbackOracle', FallbackOracle
        )
        
        // Set outcome in central oracle
        await arbiter.setOutcome(1)
        assert.equal(await arbiter.getOutcome(), 1)
        
        // Set outcome in fallback oracle
        await fallbackOracle.setForwardedOutcome()
        assert.equal(await fallbackOracle.forwardedOutcome(), 1)
        assert.equal(await fallbackOracle.isOutcomeSet(), false)
        
        // Challenge outcome
        const sender1 = 0
        await etherToken.deposit({value: 100, from: accounts[sender1]})
        await etherToken.approve(fallbackOracle.address, 100, { from: accounts[sender1] })
        await fallbackOracle.challengeOutcome(2)
        
        // Sender 2 overbids sender 1
        const sender2 = 1
        await etherToken.deposit({value: 200, from: accounts[sender2]})
        await etherToken.approve(fallbackOracle.address, 200, { from: accounts[sender2] })
        await fallbackOracle.voteForOutcome(3, 200, { from: accounts[sender2] })
        
        // Trying to withdraw before front runner period ends fails
        await utils.assertRejects(
            fallbackOracle.withdraw({from: accounts[sender2]}),
            'withdrew before front runner period')
        
        // Wait for front runner period to pass
        assert.equal(await fallbackOracle.isOutcomeSet(), false)
        await wait(frontRunnerPeriod + 1)
        assert.equal(await fallbackOracle.isOutcomeSet(), true)

        assert.equal(await fallbackOracle.getOutcome(), 3)
        
        // Withdraw winnings
        assert.equal(utils.getParamFromTxEvent(
            await fallbackOracle.withdraw({from: accounts[sender2]}), 'amount'
        ).valueOf(), 300)
    })

    it('test fallback oracle challenge period', async () => {
        // create Oracles
        const owner1 = 0
        const arbiter = utils.getParamFromTxEvent(
            await arbiterFactory.createArbiter(ipfsHash, {from: accounts[owner1]}),
            'arbiter', Arbiter
        )
        const fallbackOracle = utils.getParamFromTxEvent(
            await fallbackOracleFactory.createFallbackOracle(
                arbiter.address, etherToken.address,
                spreadMultiplier, challengeWindow, challengeAmount, frontRunnerPeriod),
                'fallbackOracle', FallbackOracle
        )
        
        // Set outcome in central oracle
        await arbiter.setOutcome(1)
        assert.equal(await arbiter.getOutcome(), 1)
        
        // Set outcome in fallback oracle
        await fallbackOracle.setForwardedOutcome()
        assert.equal(await fallbackOracle.forwardedOutcome(), 1)
        assert.equal(await fallbackOracle.isOutcomeSet(), false)
        
        // Wait for challenge period to pass
        await wait(challengeWindow + 1)
        assert.equal(await fallbackOracle.isOutcomeSet(), true)
        assert.equal(await fallbackOracle.getOutcome(), 1)
    })
})
