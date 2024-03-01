/* eslint-disable @typescript-eslint/no-explicit-any */
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'

import { FiftysixERC20, FiftysixERC721 } from '../typechain-types'

async function deploy(name: string, params: string[] = [], signer?: SignerWithAddress): Promise<any> {
  return (await (await ethers.getContractFactory(name, signer)).deploy(...params)).waitForDeployment()
}

async function coreSetup() {
  const owner = (await ethers.getSigners())[0]

  const erc20Token = (await deploy('FiftysixERC20', [ethers.parseEther('1000000').toString()], owner)) as FiftysixERC20

  const erc721Token = (await deploy('FiftysixERC721', [], owner)) as FiftysixERC721

  return { erc20Token, erc721Token }
}

export { coreSetup, deploy }
