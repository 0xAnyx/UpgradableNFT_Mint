//SPDX-License-Identifier: None
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./Land_Signer.sol";

///@author Anyx
contract LandNFT is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, LandSigner {

    string public baseURI;

    address public designatedSigner;
    address payable public treasure;

    uint public currentTokenId;
    uint public ownerCap;
    uint public whitelistCap;
    uint public maxWhitelistSpotForEach;

    uint public ownerMinted;
    uint public whiteListMinted;
    uint public publicMinted;

    uint public maxSupply;
    uint public whitelistSpotPrice;
    uint public publicMintPrice;

    uint public whitelistStartTime;
    uint public whitelistEndTime;

    mapping(address => uint) public userWhiteListSpotBought;

    function initialize(string memory _name, string memory _symbol, uint _startTime,
        address payable _treasure, address _designatedSigner) public initializer {
        require(_treasure != address(0), "Invalid Treasure Address");
        require(_designatedSigner != address(0), "Invalid designated signer address");

        __ERC721Enumerable_init();
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        __LandSigner_init();

        currentTokenId = 1;
        maxSupply = 5555;
        ownerCap = 50;
        whitelistCap = 50;
        maxWhitelistSpotForEach = 5;
        whitelistStartTime = _startTime;
        whitelistEndTime = 24 hours;
        whitelistEndTime += _startTime;
        treasure = _treasure;
        designatedSigner = _designatedSigner;
        publicMintPrice = 750 ether;
        whitelistSpotPrice = 187.5 ether;
    }


    /////////////////////////////////
    ///@notice Minting Functions ///
    ///////////////////////////////

    function ownerMint(uint _amount, address _to) external onlyOwner nonReentrant{
        require(_amount + ownerMinted <= ownerCap, "Owner Mint Limit Exceeded");
        require(_amount + totalSupply() <= maxSupply, "All Tokens Minted");
        ownerMinted += _amount;
        for(uint i = 0; i < _amount; i++){
            _mint(_to, currentTokenId);
            currentTokenId++;
        }
    }

    function whiteListMint(WhiteList memory whitelist, uint _amount) external payable nonReentrant{
        require(block.timestamp >= whitelistStartTime && block.timestamp <= whitelistEndTime, "Whitelist Period Over");
        require(_amount + whiteListMinted <= whitelistCap, "Whitelist Mint Limit Exceeded");
        require(_amount + userWhiteListSpotBought[whitelist.userAddress] <= maxWhitelistSpotForEach,
            "Max Limit Reached");
        require(getSigner(whitelist) == designatedSigner, "Designated Signer didn't match");
        require(msg.value == _amount * whitelistSpotPrice, "Pay Exact Amount");
        whiteListMinted += _amount;
        userWhiteListSpotBought[whitelist.userAddress] += _amount;
        for(uint i = 0; i < _amount; i++){
            _mint(whitelist.userAddress, currentTokenId);
            currentTokenId++;
        }
    }

    function publicMint(uint _amount) external payable nonReentrant{
        require(block.timestamp >= whitelistEndTime, "Whitelist Period Not Over");
        require(_amount + totalSupply() <= maxSupply, "All Tokens Minted");
        require(msg.value == _amount * publicMintPrice, "Pay Exact Amount");
        publicMinted += _amount;
        for(uint i = 0; i < _amount; i++){
            _mint(_msgSender(), currentTokenId);
            currentTokenId++;
        }
    }

    //////////////////////////////
    ////@dev Admin Functions ////
    ////////////////////////////

    function withdrawONE() external onlyOwner{
        require(address(this).balance != 0, "No Funds To Withdraw");
        treasure.transfer(address(this).balance);
    }

    function setWhitelistStartTime(uint _epochTime) external onlyOwner{
        require(_epochTime >= block.timestamp, "StartTime is already over");
        whitelistStartTime = _epochTime;
    }

    function setWhitelistEndTime(uint _epochTime) external onlyOwner{
        require(block.timestamp < _epochTime, "Timestamp is already over");
        whitelistStartTime = _epochTime;
    }

    function setTreasure(address _treasure) external onlyOwner {
        require(_treasure != address(0), "Invalid address for signer");
        treasure = payable(_treasure);
    }

    function setDesignatedSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address for signer");
        designatedSigner = _signer;
    }

    function setOwnerCap(uint _amount) external onlyOwner {
        ownerCap = _amount;
    }

    function setWhiteListCap(uint _amount) external onlyOwner {
        whitelistCap = _amount;
    }

    function setMaxSupply(uint _amount) external onlyOwner {
        maxSupply = _amount;
    }

    function setWhitelistTokenPrice(uint _amount) external onlyOwner{
        whitelistSpotPrice = _amount;
    }

    function setPublicMintTokenPrice(uint _amount) external onlyOwner{
        publicMintPrice = _amount;
    }

    function setMaxWhitelistSpotForEach(uint _amount) external onlyOwner{
        maxWhitelistSpotForEach = _amount;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid base URI");
        baseURI = baseURI_;
    }

    ////////////////////////////////////
    ///@notice Overridden Functions ///
    //////////////////////////////////

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
