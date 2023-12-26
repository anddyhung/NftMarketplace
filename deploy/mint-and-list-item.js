const {ethers} = require('hardhat')
const PRICE = ethers.utils.parseEther('0.1')

async function mintAndList(){
    const accounts = await ethers.getSigners()
    const [deployer, owner, buyer1] = accounts;
    const IDENTITIES = {
        [deployer.address]:'DEPLOYER',
        [owner.address]:'OWNER',
        [buyer1.address]:'BUYER1'
    }
    const nftMarketplaceContract = await ethers.getContract('NftMarketplace')
    const basicNftContract = await ethers.getContract('BasicNft')
    console.log(`Minting NFT for ${owner.address}`)
    const minTx = await basicNftContract.connect(owner).mintNft()
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId = mintTxReceipt.events[0].args.tokenId

    console.log('Approving Marketplace as operator of nftMarketplaceContract...')
}