import { ethers } from "hardhat"

async function main() {
  const FiftysixERC20 = await ethers.getContractFactory("FiftysixERC20")
  const fiftysixERC20 = await FiftysixERC20.deploy(
    ethers.parseEther("1000000") // token supply
  )
  console.log("FiftysixERC20 deployed to:", fiftysixERC20.target)

  const FiftysixERC721 = await ethers.getContractFactory("FiftysixERC721")
  const fiftysixERC721 = await FiftysixERC721.deploy()
  console.log("FiftysixERC721 deployed to:", fiftysixERC721.target)

  const FiftysixERC1155 = await ethers.getContractFactory("FiftysixERC1155")
  const fiftysixERC1155 = await FiftysixERC1155.deploy()
  console.log("FiftysixERC1155 deployed to:", fiftysixERC1155.target)

  const FiftysixDN404 = await ethers.getContractFactory("FiftysixDN404")
  const fiftysixDN404 = await FiftysixDN404.deploy(
    "Fiftysix", // name
    "56", // symbol
    "1000000", // initialTokenSupply
  )  
  console.log("FiftysixDN404 deployed to:", fiftysixDN404.target)

  const FiftysixERC918 = await ethers.getContractFactory("FiftysixERC918")
  const fiftysixERC918 = await FiftysixERC918.deploy()
  
  console.log("FiftysixERC918 deployed to:", fiftysixERC918.target)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
