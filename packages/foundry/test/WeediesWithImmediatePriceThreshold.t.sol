// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/YourContract.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WeediesWithImmediatePriceThreshold is Test {
    YourContract public yourContract;

    address mintRoyaltyRecipient = vm.addr(1);
    address USER = vm.addr(2);
    address ADMIN = vm.addr(3);

    string BASE_URI =
        "https://nft.bueno.art/api/contract/0zJlzGVsEKj7cALqS-QMX/chain/1/metadata/";

    uint256 s_maxTokenCount = 24420;

    uint256 MINT_PRICE = 0.0006942 ether;

    function setUp() public {
        YourContract.MintingThreshold[] memory thresholds =
            new YourContract.MintingThreshold[](1);
        thresholds[0] =
            YourContract.MintingThreshold(0, type(uint256).max, MINT_PRICE);
        yourContract = new YourContract(
            ADMIN,
            mintRoyaltyRecipient,
            BASE_URI,
            s_maxTokenCount,
            0,
            100,
            thresholds
        );

        vm.prank(ADMIN);
        yourContract.setUpMintableTokenIds(s_maxTokenCount);
    }

    function testMint() public {
        vm.deal(USER, MINT_PRICE);

        vm.prank(USER);
        yourContract.mint{value: MINT_PRICE}();
    }

    function testRevertMintShortedTheDealer() public {
        vm.prank(USER);
        vm.expectRevert(YourContract.Weedies__YouShortedTheDealer.selector);
        yourContract.mint();
    }
}
