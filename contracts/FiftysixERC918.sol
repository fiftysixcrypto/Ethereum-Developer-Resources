// SPDX-License-Identifier: MIT

// Code based off: Era Bitcoin (eraBTC) (https://EraBitcoin.org/)
//
// Credits: 0xBitcoin

pragma solidity ^0.8.24;

import {IERC20} from "./tokens/interfaces/IERC20.sol";

contract FiftysixERC918 is IERC20 {
  
  uint256 public constant TOTAL_SUPPLY = 21_000_000 * 10**18;
  uint256 override public totalSupply = TOTAL_SUPPLY;
  uint256 public constant START_REWARD = 50 * 10**18;
  uint256 public targetTime = 60 * 12;
  
  uint256 public epochOld = 0;  // epoch count at each readjustment 
  uint256 public lastAdjustmentTimestamp = block.timestamp;
  uint256 public lastAdjustmentBlockNumber = block.number;

  uint256 public epochCount = 0; // number of 'blocks' mined
  uint256 public constant BLOCKS_PER_READJUSTMENT = 1024;
  uint256 public constant MAXIMUM_TARGET = 2**254; // potentially should be toned down for prod, ~234
  uint256 public constant MINIMUM_TARGET = 2**16; 
  uint256 public miningTarget = 2**254; // potentially should be toned down for prod, ~234
  
  bytes32 public challengeNumber = blockhash(block.number - 1); // generate a new one when a new reward is minted
  
  uint256 public rewardEra = 0;
  uint256 public maxSupplyForEra = totalSupply - (totalSupply / (2 ** (rewardEra + 1)));
  uint256 public rewardAmount = START_REWARD;
  
  uint256 public tokensMinted = 0;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;
  mapping(bytes32 => bytes32) public solutionForChallenge;

  // metadata
  string public name = "FiftysixBitcoin";
  string public constant symbol = "56BTC";
  uint8 public constant decimals = 18;

  // Events
  event Mint(address indexed from, uint256 rewardAmount, uint256 epochCount, bytes32 newChallengeNumber);

	constructor() {
    _startNewMiningEpoch();
	}

/////////////////////////////
// Main Contract Functions //
/////////////////////////////

	function mint(uint256 nonce_, bytes32 challengeDigest_) external returns (bool success) {
	  bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce_));
    
    require(digest == challengeDigest_, "Invalid digest");
    require(uint256(digest) < miningTarget, "Digest doesn't meet target");

		// save digest
    solutionForChallenge[challengeNumber] = digest;

		_startNewMiningEpoch();

		balances[msg.sender] = balances[msg.sender] + rewardAmount;
		tokensMinted = tokensMinted + rewardAmount;

		emit Mint(msg.sender, rewardAmount, epochCount, challengeNumber);

		return true;
	}

	function _startNewMiningEpoch() internal {
		// if max supply for the era will be exceeded next reward round then enter the new era before that happens
		// 48 is the final reward era.
		if (tokensMinted + rewardAmount > maxSupplyForEra && rewardEra < 49) {
			rewardEra = rewardEra + 1;
			maxSupplyForEra = totalSupply - totalSupply / ( 2 ** (rewardEra + 1));
			rewardAmount = (50 * 10 ** uint256(decimals)) / ( 2 ** (rewardEra));
		}

		epochCount = epochCount + 1;

		// every so often, readjust difficulty
		if ((epochCount) % (BLOCKS_PER_READJUSTMENT) == 0) {
			if (totalSupply < tokensMinted){
				rewardAmount = 0;
			}
			_reAdjustDifficulty();
		}

		challengeNumber = blockhash(block.number - 1);
		bytes32 solution = solutionForChallenge[challengeNumber];
		if(solution != 0x0) revert(); // prevent the same answer from awarding twice
	}

	function _reAdjustDifficulty() internal {
		uint256 timeSinceLastAdjustment = block.timestamp - lastAdjustmentTimestamp;
		uint256 epochTotal = epochCount - epochOld;
		uint256 targetAdjustmentInterval = targetTime * epochTotal; 
		epochOld = epochCount;

		// if there were less eth blocks passed in time than expected
		if (timeSinceLastAdjustment < targetAdjustmentInterval) {
			uint256 excessTimePercentage = (targetAdjustmentInterval * 100) / (timeSinceLastAdjustment);
			uint256 adjustedExcessPercentage = excessTimePercentage - 100;
      adjustedExcessPercentage = adjustedExcessPercentage > 1000 ? 1000 : adjustedExcessPercentage;

			miningTarget = miningTarget - (miningTarget / 2000)  * adjustedExcessPercentage; // harder by up to 1/2x
		} else {
			uint256 shortageTimePercentage = (timeSinceLastAdjustment * 100) / targetAdjustmentInterval;
      uint256 adjustedShortagePercentage = shortageTimePercentage - 100;
      adjustedShortagePercentage = adjustedShortagePercentage > 1000 ? 1000 : adjustedShortagePercentage;

			miningTarget = miningTarget + (miningTarget / 1000) * adjustedShortagePercentage; // easier by up to 2x
		}

		lastAdjustmentTimestamp = block.timestamp;
		lastAdjustmentBlockNumber = block.number;

		if (miningTarget < MINIMUM_TARGET) { // very difficult
			miningTarget = MINIMUM_TARGET;
		}

		if (miningTarget > MAXIMUM_TARGET) { // very easy
			miningTarget = MAXIMUM_TARGET;
		}
	}

//////////////////////////
//// Helper Functions ////
//////////////////////////

	function reAdjustsToWhatDifficulty() public view returns (uint256 difficulty) {
    if (epochCount - epochOld == 0) {
			return MAXIMUM_TARGET / miningTarget;
		}

		uint256 timeSinceLastAdjustment = block.timestamp - lastAdjustmentTimestamp;
		uint256 epochTotal = epochCount - epochOld;
		uint256 targetAdjustmentInterval = targetTime * epochTotal; 
    uint256 miningTarget2 = 0;
		
    // if there were less eth blocks passed in time than expected
		if (timeSinceLastAdjustment < targetAdjustmentInterval) {
			uint256 excessTimePercentage = (targetAdjustmentInterval * 100) / timeSinceLastAdjustment;
			uint256 adjustedExcessPercentage = excessTimePercentage - 100;
      adjustedExcessPercentage = adjustedExcessPercentage > 1000 ? 1000 : adjustedExcessPercentage;

			miningTarget2 = miningTarget - (miningTarget / 2000) * adjustedExcessPercentage; // harder by up to 1/2x
		} else {
			uint256 shortageTimePercentage = (timeSinceLastAdjustment * 100) / targetAdjustmentInterval;
			uint256 adjustedShortagePercentage = shortageTimePercentage - 100;
      adjustedShortagePercentage = adjustedShortagePercentage > 1000 ? 1000 : adjustedShortagePercentage;

			miningTarget2 = miningTarget + (miningTarget / 1000) * adjustedShortagePercentage; // easier by up to 2x
		}
		
		if (miningTarget2 < MINIMUM_TARGET) { // very difficult
			miningTarget2 = MINIMUM_TARGET;
		}
		if (miningTarget2 > MAXIMUM_TARGET) { // very easy
			miningTarget2 = MAXIMUM_TARGET;
		}

		difficulty = MAXIMUM_TARGET / miningTarget2;
		
    return difficulty;
	}

/////////////////////////
/// Debug Functions  ////
/////////////////////////

	function checkMintSolution(uint256 nonce_, bytes32 challengeDigest_, bytes32 challengeNumber_, uint256 testTarget_) public view returns (bool success) {
		bytes32 digest = bytes32(keccak256(abi.encodePacked(challengeNumber_, msg.sender, nonce_)));
    if(uint256(digest) > testTarget_) revert();

		return (digest == challengeDigest_);
	}

	function checkMintSolutionForAddress(uint256 nonce_, bytes32 challengeDigest_, bytes32 challengeNumber_, uint256 testTarget_, address sender_) public pure returns (bool success) {
		bytes32 digest = bytes32(keccak256(abi.encodePacked(challengeNumber_, sender_, nonce_)));
		if(uint256(digest) > testTarget_) revert();

		return (digest == challengeDigest_);
	}


	//this is a recent ethereum block hash, used to prevent pre-mining future blocks
	function getChallengeNumber() public view returns (bytes32) {
		return challengeNumber;
	}

	//find current blockhash to prevent double submits in mining program until blockhash is fixed on zk sync era
	function getCurrentBlockHash() public view returns (bytes32) {
		return blockhash(block.number - 1);
	}

	//the number of zeroes the digest of the PoW solution requires.  Auto adjusts
	function getMiningDifficulty() public view returns (uint256) {
		return MAXIMUM_TARGET / miningTarget;
	}

	function getMiningTarget() public view returns (uint256) {
		return miningTarget;
	}

	function getMiningMinted() public view returns (uint256) {
		return tokensMinted;
	}

	function getCirculatingSupply() public view returns (uint256) {
		return tokensMinted;
	}

	//~21m coins total in minting
	//reward begins at 50 and stays same for the first 4 eras (0-3), targetTime doubles to compensate for first 4 eras
	//After rewardEra = 4 it halves the reward every Era because no more targetTime is added
	function getMiningReward() public view returns (uint256) {
		return (50 * 10 ** uint256(decimals)) / (2 ** (rewardEra));
	}

	function getEpoch() public view returns (uint256) {
		return epochCount;
	}

	// help debug mining software
	function getMintDigest(uint256 nonce_, bytes32 challengeDigest_, bytes32 challengeNumber_) public view returns (bytes32 digesttest) {
		return keccak256(abi.encodePacked(challengeNumber_, msg.sender, nonce_));
	}

/////////////////////////
///  ERC20 Functions  ///
/////////////////////////

  // ------------------------------------------------------------------------
  // Get the token balance for account `tokenOwner`
  // ------------------------------------------------------------------------
  function balanceOf(address tokenOwner) external view override returns (uint256 balance) {
    return balances[tokenOwner];
  }

  // ------------------------------------------------------------------------
  // Transfer the balance from token owner's account to `to` account
  // - Owner's account must have sufficient balance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
  function transfer(address to, uint256 tokens) external override returns (bool success) {
    require(balances[msg.sender] >= tokens, "Insufficient balance");
    
    balances[msg.sender] -= tokens;
    balances[to] += tokens;
    emit Transfer(msg.sender, to, tokens);
    
    return true;
  }

  // ------------------------------------------------------------------------
  // Token owner can approve for `spender` to transferFrom(...) `tokens`
  // from the token owner's account
  //
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
  // recommends that there are no checks for the approval double-spend attack
  // as this should be implemented in user interfaces
  // ------------------------------------------------------------------------
	function approve(address spender, uint256 tokens) public override returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}


  // ------------------------------------------------------------------------
  // Transfer `tokens` from the `from` account to the `to` account
  //
  // The calling account must already have sufficient tokens approve(...)-d
  // for spending from the `from` account and
  // - From account must have sufficient balance to transfer
  // - Spender must have sufficient allowance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
	function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
		balances[from] = balances[from] - tokens;
		allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
		balances[to] = balances[to] + tokens;

		emit Transfer(from, to, tokens);
		return true;
	}

  // ------------------------------------------------------------------------
  // Returns the amount of tokens approved by the owner that can be
  // transferred to the spender's account
  // ------------------------------------------------------------------------
	function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
		return allowed[tokenOwner][spender];
	}

  // do not allow ETH to enter the contract
	receive() external payable {
    revert("I don't accept ETH");
	}

	fallback() external payable {
    revert("Fallback disabled");
	}
}
