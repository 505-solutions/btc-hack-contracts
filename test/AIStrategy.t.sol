// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AIStrategy} from "../src/AIStrategy.sol";
import {Halo2Verifier} from "../src/Verifier.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {ISwapRouter} from "src/interfaces/ISwapRouter.sol";

import {MockERC20} from "src/Mocks/MockERC20.sol";
import {MockUniswapV3} from "src/Mocks/MockUniV3.sol";

import "forge-std/Vm.sol";

contract CounterTest is Test {
    AIStrategy public strategy;
    Halo2Verifier public verifier;

    MockUniswapV3 public uniswapV3;

    MockERC20 public weth;
    MockERC20 public usdc;

    address constant owner = address(0);

    function setUp() public {
        verifier = new Halo2Verifier();

        deployMocks();

        string memory strategyName = "AIStrategy";
        string memory symbol = "AIS";
        address positionManager = address(uniswapV3);
        address swapRouter = address(uniswapV3);

        uint256[3] memory scalers =
            [uint256(7455504813211), uint256(2953758299944270168064), uint256(1838876263346026577920)];
        uint256[3] memory minAddition = [uint256(1729926753534472704), uint256(262951735771738), uint256(0)];

        strategy = new AIStrategy(
            address(weth), strategyName, symbol, positionManager, swapRouter, address(verifier), scalers, minAddition
        );
    }

    function deployMocks() public {
        // Deploy mocks
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        usdc = new MockERC20("USD Coin", "USDC", 18);

        weth.mint(owner, 1_000_000 * 10 ** 18);
        usdc.mint(owner, 1_000_000_000 * 10 ** 18);

        uniswapV3 = new MockUniswapV3();

        uniswapV3.setPrice(address(weth), address(usdc), 1_000 * 1e8);
        uniswapV3.setPrice(address(usdc), address(weth), 1e5);

        // Fund the uniV3 with some funds
        vm.startPrank(owner);
        weth.transfer(address(uniswapV3), 1_000 * 10 ** 18);
        usdc.transfer(address(uniswapV3), 1_000_000 * 10 ** 18);
    }

    function test_deposit() public payable {
        uint256 assets = 5 * 10 ** 18;
        address receiver = address(this);

        vm.startPrank(owner);
        MockERC20(address(weth)).approve(address(strategy), assets);

        strategy.deposit(assets, receiver);

        // logBalances(address(weth));
        // logBalances(address(weth));
    }

    // forge verify-contract \
    //     --chain-id 11155111 \
    //     --watch \
    //     --constructor-args $(cast abi-encode "constructor(address,string,string,address,address,address,uint256[3],uint256[3])" \
    //         0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14 \
    //         AIStrategy \
    //         AIS \
    //         0x1238536071E1c677A632429e3655c799b22cDA52 \
    //         0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E \
    //         0xF26585263D5C18750870314e7Cf16fE2ED3c0A90 \
    //         '[7455504813211,2953758299944270168064,1838876263346026577920]' \
    //         '[1729926753534472704,262951735771738,0]' \
    //     ) \
    //     --etherscan-api-key N8SP1UH648EFP6486Y2KZA8DYQPU3Y7RRM \
    //     0xFa1332EC1F9955B7D61C94E9842920D7EAc0aF49 \
    //     src/AIStrategy.sol:AIStrategy

    function testUpdateStrategy() public {
        test_deposit();

        uint256 tokenId = 1;
        LiquidityManager.PoolInfo memory info = LiquidityManager.PoolInfo(address(usdc), address(weth), 3000);
        bytes memory proof =
            hex"2eec74b5cf63c4aa936cacd3e0e80048ea1d9248d8bac98b5cbd7cd28a80cc5a110bd51e6518cef05e1388b23b554766857413264ff86dc4793550bead5db7ec1c5fed6229c48b88bc2c3708ae99034881ee6a7c5dd23c686bc7b81eb0e4350e0bc7713a0fffdb78a9bc7b60d1ea622239868e13563a07ff690ca617795eaf1a020844ea405f1bf0d436a58e97aa34179eee1ad0ed10920c8fd618027ed53d7530491385295512697b2658853c9dce9831fba060baa9ec360a406be298d9153326c373bb74a431b8dae8140dbdc8022a0c545526b1e54fd164140978c36457492b299ebf4dfb306cb0d111fc638a35f8fc56d940882955dd5740e8c4d78331e7055dc056de8c0b9d264d92ef1ca56589c4d22546fa5b6854adf0f1709ec668e106a5ca2186eeaf7f9a0649995f2dca61f211a010cc241c85523ae40a1f4378fc056c0b9c674ed5858946b7de8b8b4f7c3d82d8a8a12fac84a5a0a70a98f160f2135ed071aa011311eade3cd6326b85b6d8fcfa8fd458f52ccd4faa00d5c320690351c228270a988980fb5907bfa44fcdfef110a0fffc18be64c55e9043d1a6b7007b1e6a7563791bc1b12b3720d2096fcc1f2b29348b76ce439686b5e13ddfce132fe4f4d38eb1902f65b6d31f06dda1f2c44966dbaecc7f74326add5b2722ec002e13cb035ddabff7e0ecb658aea0e0fd427d663097cabd353c417882c8ac1f15e6ebeac9e6e5986b842f3838e8e5ae6d4d37be3a56871e1310a8d6546f6d8d24e78842ee34801f291ebaf65a4fca72db59122edd2658f9d5b80f19018fe91d1230a3612af78d4296ead894c874ad9b2eac89f4c13416a37698804ac70693101ee79ed033c84dfa6b0b8dc616734ffdd6ea6945ebc97813f5c4ab7fb3dae2271d6dadf1b9dc4f15683dba79c81d6fce2f71edbd12afb556ea52fa4777834ebc2f9e85def8cf48c2f8f8a9a59ffc048268f427ef1cb86be6a6a2f7c5cd9a59151b9c649e96f7c9c8f24ad7d6c3ade54d44dc3444bb02ebf08f0b74b4e5f425d91dfaf1cd40975c307319e92f8755a9b82a7b1968b1bc034b8316fd74d529b00b0a766a651e1e2d8ef8b5288a064b38315163a62edf31ef174b8fcecbc18618a4150d30b49241cada937b1a2e5e2343875c4547f6a97264ffc16b9cb097d01c991598b34676f6ca4c39debf87b5b7dd7131ac81bd8329f0a381c402a6542b9427038e7286508364e022d59bf5b13d3981a162e827429ce6bc0c4366402a4f3dbb07aa4e68705e9f6161d20e5d3215c599e9ddd63995684fc5a9e380bd52e1d4611887912fae46c33a93c524888a8684f90bf9f7da692ed64b1fa676b32889cdac13e1cf8b6d8d322dd518d87e3c050a14cea9e14d9076982c72795a7b751169e41cb54eb68ae48d11c58e8db7f504d36b11ca6a1c688cea5ac82d423177ebd5e127bdcda970b07effe4ce839a19e0f294010cd949324a488f2518aa2efe30ddbf2f9295b00ab0d1c9bda52947f290585dfe6ac40f0ad28b1180901099597fcf1f278954ea1559dab1d4ca40263e04574596f5624a77a4f8f0c1d51427f9a2e6d8063facd4e08be8d62bc1f0affa8ba7f4f60c0605b8cfcf5c7199c7a8c2263d880923ac2fa5a439f944f4458d40b908073b3d3410ccd7fb4d1349e156533488fb1136e251f304d45b2c87b0f9d93c5baeeb4a53c4d943401a56f889eb7766af8026e5c1c103daaaad64f100f521d5cb819ed6b19c8c19e76785a1139ded6d6b022fe2aecd9dbd6f5f4ddca67ee99cca157c3256ecf4cf90590b76568b9e6338a82cdac1d843aae099394984fdb4d928b8597ae9a0b35c4541b9eec0ca95cdf8911d5a7bac282cbb710a79e4f799111d1d004a5bebd0c7c52dcd8c6d6f0d4687280d277f97025f9f751bfc67579df32de2b930c2ef074e652f09a5d5b83b939fb4244926fb89d2c2cd2b0344d250b4d2129099ddfd3e7b814db0bc08aa0fc57b780ee01df856a2a1c066d40afe960f51d50f8e2a7f571a5c00475bd14d271662071ec1e8e7c4956a3c797331a12392635e3e95239527cb712dda98b7d762cccb40007721808df15a92634c3e5358b983828f1c4a161436f66e2b1c349b92f5f60210cda87347b34eb9ce5925b0bb6f1f5875de6232dc6f9f7f28c78820d0a99e0a1a99127b3a03a6621d384fa472740acc86b5c62eeabbbd15c3754fa9d67ba1c214ab39c677bc3727272513a884a732947200435bdd1eea842ae1816ed52711b308a60994308e74ddd5a9c7f219b2f2d79dea1910dcf2374f4bc0a55b03899749027395acb6ca29c9aa27d81855f3d6e7a8cbe6db2bceb2a0afd3046f0c0c93ad119c27e0b1989c920924afd9391ace9b1c100fc401fd3af9f90acfe204c5a9811981c9c0d4c8325ebaa02bb88f58de680a0481ef9d6bd86eea036325845d07000220909e4b20b9ad01c385ba6649f54ab789b2e8023dd12c46435d570446c2270f66040e6cd809aea72da790dffaea31179d754a1595a9fd94bc6d05177d7b2200f832723b1ab6350f17c537ad8da4cbe5a6818828bc201e6c18133a1fd79da32623aed9b2829347db14a5ae2c6db91b757d17441bc9540e9a78ff9626cf24ce271cd8cd1a566eac11fc0a476c35b1b30f415aace4c16ba2474f64917b39641f11632c378912b25ad3353380e2b5c781243dd0d3e069b7185a31aa54719cb03d25fc60d1e41a9eff4d05e73b8ceca5d383982af7e9108bfb773e9dcb8b6dc47b0584a900d46cb6c38e71561661b7a2b9d9731c3bb309f07383b7de085d3b5a9f15050b71b18da3843b7af69228db45c8e05be95af6de3ad9d1520bc312f298af2e4aac2bc5085abc45d65ee59d922ac5fc6f7f0511e531308a4d1b6075dc15311d01dce478ab717e60951383bdb3cf7ec46a3f24633a6c3fcee28591e1bc851414e8a3270dc4384f3d4484d65935e631116e8983006c82280e65a6d7fd68bddd2d452b47630672af0892c2296296be2eddf88bb6b545a75923ffa3abc1a58eb414ad093aee5a818e50f4a804215a9e0d9656193491827c1d675485053e51f95e0a2f13d1e7772f31d514983b703a384e69721d0f803dc54673af5cc851b3dec10a1c67f42e286ac03cbacebe9db7c042d879709264123cd8409713b6ae4da56017d0a61410029e5857456d63581d50adba2cd084ed0ae3e9effc8545935570e126653a96d40cdb3a524726667d870fb424e019c4d7a2249c74eeba797b479da410ad4dfc564bbed4bdfb82aec247f4ca34a674f3650965f2fc7e36cf2beb23e92b3692618c3766de38a17cfc4e8daf00abd3b635821bbd236864a379bd605acc0000000000000000000000000000000000000000000000000000000000000000067f225b315c1b1820a7cd0722d129858f294db1d8f73f4a41b67021cb10276d22986a260a9de37eec327ed67bfe66dc7ac7b420d376ceac7a78d97c9c1a04c31d879a6c979b7f98a3867e304be912bcc55ae74639de010d52b49e82566a8eac2960b1d12d98fed6733480b58f231712e2d1220fb6460686d15857b09a508cb0079e1bdc44875b1d3cb594acfde92ca4586003827775f71e20d71674e4baa5922c087f7ddbffc922c32b418b1788fcef4dc07efe1bfc46ca41d0bdf0b7500cf11f2c4b2fd5f65774e1fc90410fa65e5615eb1626460e5e58f1df1d8c8d95078512f77e87b6e7afecb00e68a768352f7da97541ff4cd6294065dc50d12787ff4e2362ae112d84537db14471d2948126ca44a9241b5bd42b8f19d17f426c6b4ff411a8006af22f98874c73e28457e91e8579b53d79d85f34e8bd66ee012c30a53f2e0ee7c501a09e0e8f7748c23b150cfe87fe04f7ba2f6d99ac6efef33f904b0f0985a2e616aaaa8b7fc4571cd63ebfeb98bd965b2705a6c33457cb2a358d2f6c0609328216196bcdd3b4bd59e415e5c523d78c322b33a033a4a8d915fbaae15f1578b95a0224b967bda8d343778fc9cfdedddac7f594da6f319a64add6d1164b055a11238da79aef2c5b84f5e9dba80491e7b7227f4b56459216f91b8a8a98810a91aa7b11d81bcfca4a2631157187300e547f91d44a4bf38407de3e5469b12d2aec6f912d3d85191ceaf48789a1ef334a5868683851a846520b5e6be1f4ebee0d0105622d26536fcd00000af95b944ebd548860489d1a6803e86f31a6fd2f5a0b8f2e6ef556339616b1f435b0640071df8c4db06fc7a9331e7396f158ba7b6e029007d8a9ec0cbd49c75b355f9d54ab9a5928b31009f6d709b46bc7a4dbe730278c2098376cd1bf173700aff22365fc6e627131185516e6b87fdd385db280c70be1666e8a596683d4dfcfd2a39a476d802a2d2d180e64825e7c3fa7b9758aef008cf3907b91da3d28c331ad2717b28364876316dba8cd138a7b86352a9280af1ff1f50f38819bf29b43af33c954f8b0026b344bc4edde3e0a5dad295dc43e8d20e83bebf12ce8d0b73d40f4b613c816e5378597abd326f7e19a7b037925e73c02c9d6be76917a4fb96aab8283fdef21e3ec61e04aa3692ef0e5774a920026d30a4792b7ad2e9eb5ed5c8423f064388cf2a4e9579f2aa4d7ab52290b23981ab515af6a85d11eee4b48416a31bbc0e4d2267e7cb614ab39486d4e1916287dbbab204aabf8688c3685aef006085712f2db0aadfc89f2acd35e95e25311767093f927f1e5f136ce374a1fcaa6938d3852c86ff6adbe1c52d2b11bb167dec3aa0ae01a9576fa3757deefb72489bdeb6cd329b788308da054de1addbadfd2dc7ab7640fa7f5a92a86b7d1eedd802b93cb92d583e1826f76041ea13c64d359a4717a35303bd7480c33be5f5a7d76541ce86c53267b49bb5ddc8455728c91c206db9d16247b7fdfa25946fdeaabe0172cc4cebe8c993a81b721a2a97ba4122dbcd2e4051df6f8897f3244c66ecfb40579a773541267ad3d4405105e82e58cc859b3015d0bd2f04d4865c3f60dd071526983a72d9c1d61c8fa114a2a0546e6b965eb99881305505b5341711f7f019ab3ec81a5f2343531495c13a15aabacb69bad2cc7492273b20027f35e4de7a9abb47384902a9b8db80dd100d6f85ea71ea4f597bb9d00dd7228994fa647c9b4d785ad1dbd8705620f72f044771776e9b0d4a4e23abb";
        uint256[] memory instances = new uint256[](3);
        instances[0] = 0x000000000000000000000000000000000000000000000000000000000000086e;
        instances[1] = 0x00000000000000000000000000000000000000000000000000000000000002c7;
        instances[2] = 0x0000000000000000000000000000000000000000000000000000000000000714;

        verifier.verifyProof(proof, instances);

        vm.recordLogs();
        strategy.updateLiquidity(tokenId, info, proof, instances);
        // AIStrategy(0x3440Ba25F86f39FB85a07CB8c235e7fB3793b827).updateLiquidity(tokenId, info, proof, instances);

        // test_deposit();
        // strategy.updateLiquidity(tokenId, info, proof, instances);

        // test_deposit();
        // strategy.updateLiquidity(tokenId, info, proof, instances);

        console.log("done");

        logBalances(address(weth));
    }

    // * HELPERS
    function logBalances(address token) public view returns (uint256) {
        uint256 testBalance = MockERC20(token).balanceOf(address(this));
        uint256 ownerBalance = MockERC20(token).balanceOf(address(owner));
        uint256 uniV3Balance = MockERC20(token).balanceOf(address(uniswapV3));
        uint256 strategyBalance = MockERC20(token).balanceOf(address(strategy));

        console.log("Test balance: ", testBalance);
        console.log("Owner balance: ", ownerBalance);
        console.log("UniV3 balance: ", uniV3Balance);
        console.log("Strategy balance: ", strategyBalance);

        uint128 shares = uniswapV3.s_liquidity(1);

        console.log("Liquidity: ", shares);
    }
}
