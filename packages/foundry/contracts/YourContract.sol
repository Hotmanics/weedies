//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/Test.sol";

contract YourContract is AccessControl, ERC721 {
    error Weedies__AllWeediesAreTwisted();

    error YourContract__DidNotSendEnoughEther();
    error YourContract__PastMintWindow();
    error YourContract__BeforeMintWindow();
    error YourContract__MintNotStarted();
    error YourContract__MintAlreadyStarted();

    struct MintingThreshold {
        uint256 minThreshold;
        uint256 maxThreshold;
        uint256 mintPrice;
    }

    address immutable s_mintRoyaltyRecipient;
    uint256 immutable s_mintPrice;
    uint256 s_mintCount;

    MintingThreshold[] s_mintingThresholds;

    uint256 s_maxMintCount;

    uint256 s_mintDuration = 24 hours;
    uint256 s_startMintTimestamp;

    bool s_isMintStarted;

    string s_baseURI;

    uint256 s_maxTokenCount;

    uint256[] s_randomNumbers;

    constructor(
        address admin,
        address mintRoyaltyRecipient,
        uint256 mintDuration,
        string memory baseURI,
        uint256 maxTokenCount,
        MintingThreshold[] memory mintingThresholds
    )
        // MintingThreshold[] memory thresholds
        ERC721("Weedies", "W")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        s_mintRoyaltyRecipient = mintRoyaltyRecipient;
        s_mintPrice = 0;
        s_mintDuration = mintDuration;
        s_baseURI = baseURI;
        s_maxTokenCount = maxTokenCount;

        for (uint256 i = 0; i < mintingThresholds.length; i++) {
            s_mintingThresholds.push(mintingThresholds[i]);
        }

        for (uint256 i = 1; i <= maxTokenCount; i++) {
            s_randomNumbers.push(i);
        }
    }

    function startMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // if (s_isMintStarted) {
        //     revert YourContract__MintAlreadyStarted();
        // }

        // s_startMintTimestamp = block.timestamp;
        // s_isMintStarted = true;
    }

    function getIsMintStarted() external view returns (bool isMintStarted) {
        isMintStarted = s_isMintStarted;
    }

    function getMintDuration() external view returns (uint256 mintDuration) {
        mintDuration = s_mintDuration;
    }

    function getStartMintTimestamp()
        external
        view
        returns (uint256 startMintTimestamp)
    {
        startMintTimestamp = s_startMintTimestamp;
    }

    function getPregeneratedTokenURI(address user)
        external
        view
        returns (string memory uri)
    {
        if (getPregeneratedId(user) == 0) {
            revert();
        }

        uri = string.concat(
            "https://nft.bueno.art/api/contract/0zJlzGVsEKj7cALqS-QMX/chain/1/metadata/",
            Strings.toString(getPregeneratedId(user))
        );
    }

    function getPregeneratedId(address user) public view returns (uint256) {
        return pregeneratedTokenForUser[user];
    }

    function mint() external payable {
        if (!s_isMintStarted) {
            revert YourContract__MintNotStarted();
        }

        if (block.timestamp < s_startMintTimestamp) {
            revert YourContract__BeforeMintWindow();
        }

        if (block.timestamp > s_startMintTimestamp + s_mintDuration) {
            revert YourContract__PastMintWindow();
        }

        if (!isUserRolling[msg.sender]) {
            revert();
        }

        // uint256 mintPrice = getAcitveMintingThreshold().mintPrice;

        // if (msg.value < mintPrice) {
        //     revert YourContract__DidNotSendEnoughEther();
        // }

        isUserRolling[msg.sender] = false;
        s_mintCount++;
        _mint(msg.sender, s_mintCount);
        tokenUriId[s_mintCount] = getPregeneratedId(msg.sender);
    }

    mapping(uint256 tokenId => uint256 uriId) tokenUriId;

    function withdraw() external {
        (bool sent,) =
            s_mintRoyaltyRecipient.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    mapping(address user => uint256 pregeneratedId) pregeneratedTokenForUser;
    mapping(address user => bool isRolling) isUserRolling;

    mapping(address user => uint256 id) s_rolledTokenId;

    function getRolledTokenId(address user) public view returns (uint256) {
        return s_rolledTokenId[user];
    }

    function getRolledTokenURI(address user)
        public
        view
        returns (string memory uri)
    {
        uri =
            string.concat(_baseURI(), Strings.toString(getRolledTokenId(user)));
    }

    function rollOneUp() external returns (uint256 tokenId) {
        uint256 result = generateRandomNumberWithFilter(s_maxTokenCount);
        s_rolledTokenId[msg.sender] = result;
        tokenId = result;
    }

    function generateRandomNumberWithFilter(uint256 seed)
        public
        returns (uint256)
    {
        (uint256 randomIndex, uint256 resultNumber) =
            generateRandomNumberWithFilterNoWrite(seed);

        // write the last number of the array to the current position.
        // thus we take out the used number from the circulation and store the last number of the array for future use
        s_randomNumbers[randomIndex] =
            s_randomNumbers[s_randomNumbers.length - 1];

        // reduce the size of the array by 1 (this deletes the last record we’ve copied at the previous step)
        s_randomNumbers.pop();

        return resultNumber;
    }

    function generateRandomNumberWithFilterNoWrite(uint256 seed)
        public
        view
        returns (uint256 randomIndex, uint256 resultNumber)
    {
        if (s_randomNumbers.length == 0) {
            revert Weedies__AllWeediesAreTwisted();
        }

        uint256 randomSeed = generateRandomNumber(seed);

        // get the random number, divide it by our array size and store the mod of that division.
        // this is to make sure the generated random number fits into our required range
        randomIndex = (randomSeed % s_randomNumbers.length);

        // draw the current random number by taking the value at the random index
        resultNumber = (s_randomNumbers[randomIndex]);
    }

    function generateRandomNumberWithIndexAccomodation(uint256 seed)
        public
        view
        returns (uint256 randomNumberWithIndexAccomodation)
    {
        randomNumberWithIndexAccomodation = generateRandomNumber(seed) + 1;
    }

    function generateRandomNumber(uint256 ceiling)
        public
        view
        returns (uint256 randomNumber)
    {
        uint256 randomHash = generateRandomHash();
        randomNumber = (randomHash % ceiling);
    }

    function generateRandomHash() public view returns (uint256 randomHash) {
        randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender, blockhash(block.number - 1), block.timestamp
                )
            )
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory i)
    {
        return string.concat(_baseURI(), Strings.toString(tokenUriId[tokenId]));
    }

    function _baseURI() internal view override returns (string memory) {
        return s_baseURI;
    }

    function getMaxMintCount() external view returns (uint256 maxMintCount) {
        maxMintCount = s_maxMintCount;
    }

    function getMintCount() external view returns (uint256 mintCount) {
        mintCount = s_mintCount;
    }

    function getRoyaltyRecipient() external view returns (address) {
        return s_mintRoyaltyRecipient;
    }

    // function getAcitveMintingThreshold()
    //     public
    //     view
    //     returns (MintingThreshold memory threshold)
    // {
    //     for (uint256 i = 0; i < mintingThresholds.length; i++) {
    //         if (
    //             (s_mintCount >= mintingThresholds[i].minThreshold)
    //                 && (s_mintCount < mintingThresholds[i].maxThreshold)
    //         ) {
    //             threshold = mintingThresholds[i];
    //             break;
    //         }
    //     }
    // }
}
