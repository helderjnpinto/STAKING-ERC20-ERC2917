import { expect, use } from 'chai';
import { Contract, Wallet} from 'ethers';
import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
import Stake from '../build/ProveOfStake.json'
import ERC2917 from '../build/ERC2917Impl.json'
import { BigNumber } from 'bignumber.js'
import { ProveOfStake } from "../typechain/ProveOfStake";
import { ERC2917Impl } from "../typechain/ERC2917Impl";

const { waffle } = require("hardhat");

use(solidity);

function convertBigNumber(bnAmount: BigNumber | string, divider: number) {
  const _bnAmount = bnAmount instanceof BigNumber ? bnAmount.toString() : bnAmount;
  return new BigNumber(_bnAmount).dividedBy(new BigNumber(divider)).toFixed();
}


describe('Stake testing', () => {
  // let provider = new MockProvider();
  const provider = waffle.provider;

  const [staker1, staker2, staker3] = provider.getWallets();

  let ERC2917Contract: ERC2917Impl;
  let StakeContract: ProveOfStake;

  async function takeWithBlock(title: string, address : any) {
    // Returns how much a user could earn plus the giving block number.
    /**
     Similar to take(), but with the block height joined to calculate return.
     For instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
     It returns amount of interests and the block height.
     */
    let [_amount, _block] = await ERC2917Contract.connect(address).takeWithBlock();
    console.log('\n > takeWithBlock > ' + title + ' ' + convertBigNumber(new BigNumber(_amount.toString()), 1e18) + '@' + _block);
  }
  
  async function mineBlock() {
    console.log("\n \t [Mine block force with incNounce()]")
    await StakeContract.incNounce();
  }

  async function balanceOf(wallet: Wallet, label: string = '') {
    const balance = await ERC2917Contract.connect(wallet).balanceOf(wallet.address)
    console.log("\t balanceOf " + label, convertBigNumber(balance.toString(), 1e18));
  }

  async function take(wallet: Wallet, label: string = '') {
    const take = await ERC2917Contract.connect(wallet).take()
    console.log('\t take callee ' + label, take.toString())
  }

  async function getProductivity(wallet: Wallet, label: string = '') {
    const prod = await ERC2917Contract.getProductivity(wallet.address)
    console.log('\t getProductivity of callee ' + label, prod.toString())
  }

  async function stake(wallet: Wallet, label: string = '', amount: number = 0) {
    await StakeContract.connect(wallet).stake({ value: amount, gasLimit: 400000 });
    console.log('\t [Mine block] stake callee ' + label + ' ', amount)
  }

  async function unStake(wallet: Wallet, label: string = '', amount: number = 0) {
    await StakeContract.connect(wallet).stake({ value: amount });
    console.log('\t [Mine block] stake callee ' + label + ' ', amount)
  }

  async function totalSupply() {
    const total = (await ERC2917Contract.totalSupply()).toString()
    console.log('\t totalSupply', total)
  }

  async function balancesERC20() {
    [staker1, staker2, staker3].forEach(async (wallet: Wallet) => {
      await balanceOf(wallet)
    })
  }

  async function printContractStatus() {
    console.log("\n ==== Print status ==== ")
    const inter = (await ERC2917Contract.interestsPerBlock()).toString()
    console.log('\t InterestsPerBlock with rate of 100 per block: ', inter)

    const [
      lastRewardBlock,
      totalProductivity,
      accAmountPerShare,
      mintCumulation
    ] = await ERC2917Contract.getStatus();

    console.log('\t accAmountPerShare', accAmountPerShare.toString())
    console.log('\t totalProductivity', totalProductivity.toString())
    console.log('\t lastRewardBlock', lastRewardBlock.toString())
    console.log('\t mintCumulation', mintCumulation.toString())

    await balancesERC20()
    console.log("\n ===================== ")
  }

  before(async () => {
    // deployment of ERC2917 token, with input initial interests produced per block.
    ERC2917Contract = (await deployContract(staker1, ERC2917, [1])) as ERC2917Impl;

    // deployment of Prove of Stake contract, with the input of deployed ERC2917's token contract address.
    StakeContract = (await deployContract(staker1, Stake, [ERC2917Contract.address])) as ProveOfStake;

    // update the ERC2917's implementation to StakeContract just deployed.
    await ERC2917Contract.connect(staker1).upgradeImpl(StakeContract.address);

    console.log('staker1 = ', staker1.address);
    console.log('staker2 = ', staker2.address);
    console.log('ERC2917 address = ', ERC2917Contract.address);
    console.log('Stake address = ', StakeContract.address);
  });

  it('testing stake', async () => {
    await totalSupply()
    await stake(staker1, 'staker1', 100)
    // await getProductivity(staker1, 'staker1')
    
    // await totalSupply()

    // await stake(staker2, 'staker2', 100)
    // await totalSupply()

    
    // await printContractStatus()

    // await mineBlock()
    
    // //
    // await takeWithBlock('staker1', staker1.address);
		// await takeWithBlock('staker2', staker2.address);

    // await unStake(staker1, 'staker1', 100)

    // await takeWithBlock('staker1', staker1.address);
    // await takeWithBlock('staker2', staker2.address);

    // await takeWithBlock('staker1', staker1.address);
    // await takeWithBlock('staker2', staker2.address);
    
    // take(staker2, 'staker2')

    // await balanceOf(staker1, 'staker1')
    // await balanceOf(staker2, 'staker2')
    // await balanceOf(staker3, 'staker3')
    // await printContractStatus()


    console.log('\t contract-> totalSupply: ', (await ERC2917Contract.totalSupply()).toString())
  })

});
