import { ethers } from "hardhat"

async function main() {
  const FiftysixERC20 = await ethers.getContractFactory("FiftysixERC20")
  const fiftysixERC20 = await FiftysixERC20.deploy(ethers.parseEther("1000000"))
  console.log("FiftysixERC20 deployed to:", fiftysixERC20.target)

  const FiftysixERC721 = await ethers.getContractFactory("FiftysixERC721")
  const fiftysixERC721 = await FiftysixERC721.deploy()
  console.log("FiftysixERC721 deployed to:", fiftysixERC721.target)

  const FiftysixERC1155 = await ethers.getContractFactory("FiftysixERC1155")
  const fiftysixERC1155 = await FiftysixERC1155.deploy()
  console.log("FiftysixERC1155 deployed to:", fiftysixERC1155.target)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
