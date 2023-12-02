pragma solidity 0.8.21;

import {Test} from "forge-std/test.sol";
import {UniswapV2Pair, ERC20} from "../src/UniswapV2Pair.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";

contract UniswapV2PairTest is Test {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    dummyToken token0;
    dummyToken token1;

    function setUp() public {
        token0 = new dummyToken("token0", "T0");
        token1 = new dummyToken("token1", "T1");
        factory = new UniswapV2Factory(address(this));
        factory.createPair(address(token0), address(token1));
        pair = UniswapV2Pair(factory.getPair(address(token0), address(token1)));

        token0.mint(address(this), 10e18);
        token1.mint(address(this), 10e18);
    }

    function testMint() public {
        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 1e18);

        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 999999999999999000);
        assertEq(pair.balanceOf(address(0)), pair.MINIMUM_LIQUIDITY());
        assertEq(token0.balanceOf(address(pair)), 1e18);
        assertEq(token1.balanceOf(address(pair)), 1e18);
    }

    // function testBurn() public {
    //     pair.burn(address(0));
    // }

    // function testSwap() public {
    //     pair.swap(0, 0, address(0), "");
    // }

    // function testSkim() public {
    //     pair.skim(address(0));
    // }

    // function testSync() public {
    //     pair.sync();
    // }

    // function testInitialize() public {
    //     pair.initialize(address(0), address(0));
    // }
}

contract dummyToken is ERC20 {

    constructor(string memory name_, string memory symbol_) {
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function name() public view override returns (string memory) {
        return "name";
    }

    function symbol() public view override returns (string memory) {
        return "symbole";
    }

}