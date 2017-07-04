let Math = artifacts.require('Math')
let EventFactory = artifacts.require('EventFactory')
let EtherToken = artifacts.require('EtherToken')
let ArbiterFactory = artifacts.require('ArbiterFactory')
let MajorityOracleFactory = artifacts.require('MajorityOracleFactory')
let PythianOracleFactory = artifacts.require('PythianOracleFactory')
let DifficultyOracleFactory = artifacts.require('DifficultyOracleFactory')
let FutarchyOracleFactory = artifacts.require('FutarchyOracleFactory')
let FallbackOracleFactory = artifacts.require('FallbackOracleFactory')
let LMSRMarketMaker = artifacts.require('LMSRMarketMaker')
let StandardMarketFactory = artifacts.require('StandardMarketFactory')
let CampaignFactory = artifacts.require('CampaignFactory')

module.exports = function (deployer) {
    deployer.deploy(Math)

    deployer.link(Math, EventFactory)
    deployer.deploy(EventFactory).then(() => {
        deployer.deploy(FutarchyOracleFactory, EventFactory.address)
    })

    deployer.deploy(ArbiterFactory)
    deployer.deploy(MajorityOracleFactory)
    deployer.deploy(PythianOracleFactory)
    deployer.deploy(DifficultyOracleFactory)

    deployer.link(Math, FallbackOracleFactory)
    deployer.deploy(FallbackOracleFactory)

    deployer.link(Math, LMSRMarketMaker)
    deployer.deploy(LMSRMarketMaker)

    deployer.link(Math, StandardMarketFactory)
    deployer.deploy(StandardMarketFactory)

    deployer.link(Math, EtherToken)
    deployer.deploy(EtherToken)

    deployer.link(Math, CampaignFactory)
    deployer.deploy(CampaignFactory)
}
