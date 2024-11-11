// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {MockERC20} from "src/Mocks/MockERC20.sol";
import {MockUniswapV3} from "src/Mocks/MockUniV3.sol";
import {AIStrategy} from "src/AIStrategy.sol";

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
