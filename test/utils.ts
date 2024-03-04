import { ethers } from "hardhat";

function encodePacked(challengeNumber: string, senderAddress: string, nonce: number) {
  // Convert each argument to a hex string (without '0x') and concatenate

  const packed = challengeNumber.replace('0x', '') +
    senderAddress.replace('0x', '').padStart(40, '0') +
    nonce.toString(16).padStart(64, '0');

  return '0x' + packed;
}

const findValidNonce = async (
  senderAddress: string,
  challengeNumber: string,
  miningTarget: bigint
): Promise<number> => {
  let nonce = 0;
  let isValid = false;
  while (!isValid) {
    const digest = ethers.keccak256(encodePacked(challengeNumber, senderAddress, nonce))

    isValid = ethers.toBigInt(digest) < miningTarget;

    if (!isValid) nonce++;
  }
  return nonce;
};

export { encodePacked, findValidNonce }
