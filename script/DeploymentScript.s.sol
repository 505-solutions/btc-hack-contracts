// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {MockERC20} from "src/Mocks/MockERC20.sol";
import {MockUniswapV3} from "src/Mocks/MockUniV3.sol";
import {Halo2Verifier} from "../src/Verifier.sol";
import {AIStrategy} from "../src/AIStrategy.sol";

contract DeploymentScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Mock ERC20 tokens
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 18);
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 18);

        console.log("Token0 deployed at:", address(weth));
        console.log("Token1 deployed at:", address(usdc));

        // 2. Mint tokens
        weth.mint(deployer, 1_000_000 * 10 ** 18);
        usdc.mint(deployer, 1_000_000_000 * 10 ** 18);

        console.log("Tokens minted to:", msg.sender);

        // 3. Deploy MockUniV3
        MockUniswapV3 uniswapV3 = new MockUniswapV3();

        uniswapV3.setPrice(address(weth), address(usdc), 1_000 * 1e8);
        uniswapV3.setPrice(address(usdc), address(weth), 1e5);
        console.log("MockUniV3 deployed at:", address(uniswapV3));

        // 4. Transfer tokens to MockUniV3
        weth.transfer(address(uniswapV3), 1_000 * 10 ** 18);
        usdc.transfer(address(uniswapV3), 1_000_000 * 10 ** 18);

        console.log("Tokens transferred to MockUniV3");

        vm.stopBroadcast();
    }
}

contract DeploymentVerifier is Script {
    function setUp() public {}

    function run() public returns (Halo2Verifier verifier) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9);

        vm.startBroadcast(deployerPrivateKey);

        verifier = new Halo2Verifier();
        vm.stopBroadcast();
    }
}

contract DeploymentStrategy is Script {
    function setUp() public {}

    function run() public returns (AIStrategy strategy) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9);

        vm.startBroadcast(deployerPrivateKey);

        string memory strategyName = "AIStrategy";
        string memory symbol = "AIS";
        address positionManager = address(0xc04625c8d25bD8bF6788AB53457080A0B4b32329);
        address swapRouter = address(0xc04625c8d25bD8bF6788AB53457080A0B4b32329);

        uint256[3] memory scalers =
            [uint256(7455504813211), uint256(2953758299944270168064), uint256(1838876263346026577920)];
        uint256[3] memory minAddition = [uint256(1729926753534472704), uint256(262951735771738), uint256(0)];

        address verifier = address(0xDfD349eC493C6afC77F859d00c8f03B36f9842b9);
        address weth = address(0xD000c22719930511aCc1cd6482F5A5b944E1Ec01);
        strategy = new AIStrategy(
            address(weth), strategyName, symbol, positionManager, swapRouter, address(verifier), scalers, minAddition
        );

        vm.stopBroadcast();
    }
}

contract DepositScript is Script {
    function setUp() public {}

    function run() public returns (Halo2Verifier verifier) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9);

        address strategyAddress = address(0x2e293Bd3Bc02e83D3ef7794C4F64E4F1D1729Fb6);
        AIStrategy strategy = AIStrategy(strategyAddress);

        vm.startBroadcast(deployerPrivateKey);

        uint256 wethAmount = 1e18;
        address weth = address(0xD000c22719930511aCc1cd6482F5A5b944E1Ec01);

        MockERC20(address(weth)).approve(address(strategy), wethAmount);

        strategy.deposit(wethAmount, deployer);

        vm.stopBroadcast();
    }
}


