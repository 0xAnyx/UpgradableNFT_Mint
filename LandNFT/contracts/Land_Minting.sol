//SPDX-License-Identifier: None
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ERC721AUpgradable.sol";
import "./Land_Signer.sol";

///@author Anyx
contract LandNFT is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721AUpgradeable, LandSigner {

    string public baseURI;

    address public designatedSigner;
    address payable public treasure;

    uint16 public ownerCap;
    uint16 public whitelistCap;

    uint256 public ownerMinted;
    uint256 public whiteListMinted;
    uint256 public publicMinted;

    uint256 public maxSupply;
    uint256 public whitelistSpotPrice;
    uint256 public publicMintPrice;

    uint256 public whitelistStartTime;
    uint256 public whitelistEndTime;

    mapping(address => uint256) public userWhiteListSpotBought;
    mapping(address => uint256) public userPublicMintTokensBought;

    function initialize(string memory _name, string memory _symbol, uint256 _startTime,
        address payable _treasure, address _designatedSigner) public initializer {
        require(_treasure != address(0), "Invalid Treasure Address");
        require(_designatedSigner != address(0), "Invalid designated signer address");

        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        __LandSigner_init();

        maxSupply = 5555;
        ownerCap = 50;
        whitelistCap = 50;
        whitelistStartTime = _startTime;
        whitelistEndTime = 24 hours;
        whitelistEndTime += _startTime;
        treasure = _treasure;
        designatedSigner = _designatedSigner;
        publicMintPrice = 750 ether;
        whitelistSpotPrice = 562.5 ether;
    }


    /////////////////////////////////
    ///@notice Minting Functions ///
    ///////////////////////////////

    function ownerMint(uint256 _amount) external onlyOwner nonReentrant{
        require(_amount + ownerMinted <= ownerCap, "Owner Mint Limit Exceeded");
        require(_amount + totalSupply() <= maxSupply, "All Tokens Minted");
        ownerMinted += _amount;
        _mint(_msgSender(), _amount);
    }

    function whiteListMint(WhiteList memory whitelist, uint256 _amount) external payable nonReentrant{
        require(block.timestamp >= whitelistStartTime && block.timestamp <= whitelistEndTime, "Whitelist Period Over");
        require(_amount + whiteListMinted <= whitelistCap, "Whitelist Mint Limit Exceeded");
        require(getSigner(whitelist) == designatedSigner, "Designated Signer didn't match");
        require(whitelist.userAddress == _msgSender(), "Invalid Signature");
        require(msg.value == _amount * whitelistSpotPrice, "Pay Exact Amount");
        whiteListMinted += _amount;
        userWhiteListSpotBought[whitelist.userAddress] += _amount;
        _mint(whitelist.userAddress, _amount);
    }

    function publicMint(uint256 _amount) external payable nonReentrant{
        require(block.timestamp >= whitelistEndTime, "Whitelist Period Not Over");
        require(_amount + totalSupply() <= maxSupply, "All Tokens Minted");
        require(msg.value == _amount * publicMintPrice, "Pay Exact Amount");
        publicMinted += 1;
        userPublicMintTokensBought[_msgSender()] += _amount;
        _mint(_msgSender(), _amount);
    }

    //////////////////////////////
    ////@dev Admin Functions ////
    ////////////////////////////

    function withdrawONE() external onlyOwner{
        require(treasure != address(0), "Treasure address not set");
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

    function setOwnerCap(uint16 _amount) external onlyOwner {
        ownerCap = _amount;
    }

    function setWhiteListCap(uint16 _amount) external onlyOwner {
        whitelistCap = _amount;
    }

    function setMaxSupply(uint256 _amount) external onlyOwner {
        maxSupply = _amount;
    }

    function setWhitelistTokenPrice(uint256 _amount) external onlyOwner{
        whitelistSpotPrice = _amount;
    }

    function setPublicMintTokenPrice(uint256 _amount) external onlyOwner{
        publicMintPrice = _amount;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid base URI");
        baseURI = baseURI_;
    }

    ////////////////////////////////////
    ///@notice Overridden Functions ///
    //////////////////////////////////

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}
