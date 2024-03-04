import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

import {
  FiftysixERC20,
  FiftysixERC721,
  FiftysixERC1155,
  FiftysixDN404,
  FiftysixERC918,
} from '../typechain-types'

import { coreSetup, deploy } from './fixture'
import { encodePacked, findValidNonce } from './utils'

describe('Simple Token tests (ERC-20, ERC-721, ERC-1155)', function () {
  let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress
  const baseURI = 'https://fiftysix.xyz/metadata'

  let erc20Token: FiftysixERC20
  let erc721Token: FiftysixERC721
  let erc1155Token: FiftysixERC1155

  before(async function () {
    // eslint-disable-next-line no-extra-semi
    ;[owner, user1, user2] = await ethers.getSigners()
  })

  beforeEach(async function () {
    // eslint-disable-next-line no-extra-semi
    ;({ erc20Token, erc721Token } =
      await loadFixture(coreSetup))

    erc1155Token = (await deploy('FiftysixERC1155', [], owner)) as FiftysixERC1155
  })

  describe('ERC20 tests', function () {
    let tokenAmount = ethers.parseEther('10')
  
    beforeEach(async function () {
      await erc20Token.connect(owner).transfer(user1.address, tokenAmount)
    })
  
    it('transfers token from owner to user1', async function () {
      expect(await erc20Token.balanceOf(user1.address)).to.equal(tokenAmount)
    })
  
    it('approves tokens for delegated transfer', async function () {
      await erc20Token.connect(user1).approve(user2.address, tokenAmount)
      expect(await erc20Token.allowance(user1.address, user2.address)).to.equal(tokenAmount)
    })
  
    it('executes delegated token transfers', async function () {
      // user1 approves user2 to spend on their behalf
      await erc20Token.connect(user1).approve(user2.address, tokenAmount)
      // user2 transfers those tokens from user1 to themselves
      await erc20Token.connect(user2).transferFrom(user1.address, user2.address, tokenAmount)
      expect(await erc20Token.balanceOf(user2.address)).to.equal(tokenAmount)
    })

    it('rejects insufficient balance transfers', async function () {
      const largeAmount = ethers.parseEther('1000')
      // expect revert due to insufficient balance
      await expect(erc20Token.connect(user1).transfer(user2.address, largeAmount)).to.be.reverted
    })
  
    it('rejects unauthorized delegated transfer', async function () {
      // expect revert due to transfer without sufficient allowance
      await expect(erc20Token.connect(user2).transferFrom(user1.address, user2.address, tokenAmount)).to.be.reverted
    })
  })

  describe('ERC721 tests', function () {
    let tokenId = 101
  
    beforeEach(async function () {
      await erc721Token.connect(owner).mint(user1.address, tokenId)
    })
  
    it('should mint a new token successfully to user1', async function () {
      expect(await erc721Token.ownerOf(tokenId)).to.equal(user1.address)
    })
  
    it('should return correct balance of user1', async function () {
      expect(await erc721Token.balanceOf(user1.address)).to.equal(1)
    })
  
    it('should be able to transfer token from user1 to user2', async function () {
      // User1 transfers token to User2
      await erc721Token.connect(user1).transferFrom(user1.address, user2.address, tokenId)
      expect(await erc721Token.ownerOf(tokenId)).to.equal(user2.address)
    })
  
    it('should not allow unauthorized transfers', async function () {
      // Attempt to transfer token from User1 to User2 by User3 (unauthorized)
      await expect(
        erc721Token.connect(user2).transferFrom(user1.address, user2.address, tokenId)
      ).to.be.reverted
    })
  
    it('should allow owner to approve a token for transfer by another account', async function () {
      // Owner approves User2 to manage the token
      await erc721Token.connect(user1).approve(user2.address, tokenId)
      // User2 transfers token to themselves
      await erc721Token.connect(user2).transferFrom(user1.address, user2.address, tokenId)
      expect(await erc721Token.ownerOf(tokenId)).to.equal(user2.address)
    })
  })  

  describe('ERC1155 tests', function () {
    let id = Math.floor(Math.random() * 99) + 1
    let amount = 0n
  
    beforeEach(async function () {
      erc1155Token = (await deploy('FiftysixERC1155', [], owner)) as FiftysixERC1155
      await erc1155Token.mint(user1.address, id, id * 7)
      amount = await erc1155Token.balanceOf(user1.address, id)
    })
  
    it('should mint the correct amount of tokens to user1', async function () {
      const expectedAmount = id * 7
      expect(amount.toString()).to.equal(expectedAmount.toString())
    })
  
    it('should be able to transfer tokens between accounts', async function () {
      const transferAmount = id * 2
      await erc1155Token.connect(user1).safeTransferFrom(user1.address, user2.address, id, transferAmount, '0x')
      const balanceUser2AfterTransfer = await erc1155Token.balanceOf(user2.address, id)
      expect(balanceUser2AfterTransfer.toString()).to.equal(transferAmount.toString())
    })
  
    it('should not allow transfer more than the balance', async function () {
      const invalidTransferAmount = 10000000n
      await expect(
        erc1155Token.connect(user1).safeTransferFrom(user1.address, user2.address, id, invalidTransferAmount, '0x')
      ).to.be.reverted
    })
  
    it('balanceOfBatch should correctly report balances', async function () {
      const ids = [id, id]
      const addresses = [user1.address, user2.address]
      const balances = await erc1155Token.balanceOfBatch(addresses, ids)
  
      expect(balances[0].toString()).to.equal(amount.toString())
      expect(balances[1].toString()).to.equal('0')
    })
  })
})

describe("DN404 -- Half ERC-20/ERC-721", function () {
  let fiftysixDN404: FiftysixDN404
  let owner: any, user1: any, user2: any

  beforeEach(async function () {
    const [deployer, addr1, addr2] = await ethers.getSigners()
    owner = deployer
    user1 = addr1
    user2 = addr2

    const FiftysixDN404 = await ethers.getContractFactory("FiftysixDN404", owner)
    fiftysixDN404 = await FiftysixDN404.deploy("FiftysixDN404Token", "SDN404", 1000000)
  })

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await fiftysixDN404.governor()).to.equal(owner.address)
    })

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await fiftysixDN404.balanceOf(owner.address)
      expect(await fiftysixDN404.totalSupply()).to.equal(ownerBalance)
    })
  })

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      await fiftysixDN404.connect(owner).transfer(user1.address, 50)
      const user1Balance = await fiftysixDN404.balanceOf(user1.address)
      expect(user1Balance).to.equal(50)
    })

    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await fiftysixDN404.balanceOf(owner.address)

      // Try to send 1 token from user1 (0 tokens) to owner (1000000 tokens)
      await expect(fiftysixDN404.connect(user1).transfer(owner.address, 1)).to.be.reverted

      expect(await fiftysixDN404.balanceOf(owner.address)).to.equal(initialOwnerBalance)
    })

    it("Should update balances after transfers", async function () {
      await fiftysixDN404.connect(owner).transfer(user1.address, 100)
      await fiftysixDN404.connect(owner).transfer(user2.address, 50)

      const user1Balance = await fiftysixDN404.balanceOf(user1.address)
      expect(user1Balance).to.equal(100)

      const user2Balance = await fiftysixDN404.balanceOf(user2.address)
      expect(user2Balance).to.equal(50)
    })
  })

  describe("Governance", function () {
    it("Should only allow the governor to call restricted functions", async function () {
      // Attempt to call a governor-restricted function from another account should be reverted
      await expect(fiftysixDN404.connect(user1).mint(user1.address, 1000)).to.be.revertedWith("not governor")

      await expect(fiftysixDN404.connect(owner).mint(user1.address, 1000)).to.not.be.reverted
      expect(await fiftysixDN404.balanceOf(user1.address)).to.equal(1000)
    })

    it("Should allow governor to withdraw contract balance", async function () {
      const sendValue = ethers.parseEther("1")
      await owner.sendTransaction({ to: fiftysixDN404.target, value: sendValue })

      expect(await ethers.provider.getBalance(fiftysixDN404.target)).to.equal(sendValue)

      await fiftysixDN404.connect(owner).withdraw()

      expect(await ethers.provider.getBalance(fiftysixDN404.target)).to.equal(0)
    })
  })

  describe("Minting", function () {
    it("Should mint tokens upon receiving ETH", async function () {
      const sendValue = ethers.parseEther("1")
      const expectedMintAmount = "1000000000000000000000" // Assuming 1000 tokens per ETH

      await user1.sendTransaction({
        to: fiftysixDN404.target,
        value: sendValue,
      })

      expect(await fiftysixDN404.balanceOf(user1.address)).to.equal(expectedMintAmount)
    })

    it("Should not mint tokens beyond the maximum supply", async function () {
      const sendValue = ethers.parseEther("1000")

      await expect(
        user1.sendTransaction({
          to: fiftysixDN404.target,
          value: sendValue,
        })
      ).to.be.reverted
    })
  })

  describe("Metadata", function () {
    it("Should correctly set and affect token URI", async function () {
      const baseURI = "https://fiftysix.xyz/metadata/"
      await fiftysixDN404.setBaseURI(baseURI)
      
      await fiftysixDN404.mint(owner.address, ethers.parseEther("1"))

      expect(await fiftysixDN404.tokenURI(1)).to.equal(baseURI + "1")
    })
  })
})

describe("ERC918 -- PoW Minable Ethereum Token", function () {
  let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress

  let fiftysixBitcoin: FiftysixERC918

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const FiftysixBitcoin = await ethers.getContractFactory("FiftysixERC918");
    fiftysixBitcoin = await FiftysixBitcoin.deploy();

    // Assuming the existence of a function to get the current challenge for simplicity
    const challengeNumber = await fiftysixBitcoin.getChallengeNumber();
    const miningTarget = await fiftysixBitcoin.getMiningTarget();

    // Simulate finding a valid nonce
    const validNonce = await findValidNonce(owner.address, challengeNumber, miningTarget);
    const challengeDigest = ethers.keccak256(encodePacked(challengeNumber, owner.address, validNonce));
    
    // Ensure the digest meets the mining target
    const meetsTarget = await fiftysixBitcoin.checkMintSolution(validNonce, challengeDigest, challengeNumber, miningTarget);
    expect(meetsTarget).to.equal(true);
    
    // Mint the tokens
    await expect(fiftysixBitcoin.mint(validNonce, challengeDigest)).to.emit(fiftysixBitcoin, 'Mint')
  });

  it("Should expect first mint of tokens after successfully solving a challenge", async function () {
    const rewardAmount = await fiftysixBitcoin.getMiningReward();

    // Verify the balance has increased by the reward amount
    expect(await fiftysixBitcoin.balanceOf(owner.address)).to.equal(rewardAmount);
    
    // Verify the increase in total tokens minted
    expect(await fiftysixBitcoin.getMiningMinted()).to.equal(rewardAmount);
  });

  it("Should initialize with the correct total supply", async function () {
    expect(await fiftysixBitcoin.totalSupply()).to.equal(ethers.parseEther("21000000"));
  });

  it("Should transfer tokens between accounts", async function () {
    // Transfer 50 tokens from owner to user1
    await fiftysixBitcoin.transfer(user1.address, ethers.parseEther("50"));
    expect(await fiftysixBitcoin.balanceOf(user1.address)).to.equal(ethers.parseEther("50"));

    // Transfer 50 tokens from user1 to user2
    await fiftysixBitcoin.connect(user1).transfer(user2.address, ethers.parseEther("50"));
    expect(await fiftysixBitcoin.balanceOf(user2.address)).to.equal(ethers.parseEther("50"));
  });

  it("Should approve and then transfer tokens when called through transferFrom", async function () {
    const approveAmount = ethers.parseEther("50");
    await fiftysixBitcoin.approve(user1.address, approveAmount);
    expect(await fiftysixBitcoin.allowance(owner.address, user1.address)).to.equal(approveAmount);
  
    await fiftysixBitcoin.connect(user1).transferFrom(owner.address, user2.address, approveAmount);
    expect(await fiftysixBitcoin.balanceOf(user2.address)).to.equal(approveAmount);
  });
});
