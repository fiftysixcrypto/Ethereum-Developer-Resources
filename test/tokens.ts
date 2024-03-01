import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

import { FiftysixERC1155, FiftysixERC20, FiftysixERC721 } from '../typechain-types'

import { coreSetup, deploy } from './fixture'

const ZERO_ADDRESS = ethers.ZeroAddress

describe('Token tests', function () {
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
