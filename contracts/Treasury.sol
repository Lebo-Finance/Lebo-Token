// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ITreasuryWithdraw.sol";
import "./interfaces/ITokenWithdraw.sol";

contract Treasury is
    Initializable,
    OwnableUpgradeable,
    IERC20,
    PausableUpgradeable,
    ITreasury,
    ITreasuryWithdraw
{
    address internal token_;
    mapping(address => bool) internal liquidityAddress_;
    mapping(address => bool) internal foundationAddress_;
    mapping(address => bool) internal marketingAddress_;
    mapping(address => bool) internal tokenSaleAddress_;

    mapping(address => uint256) internal airdrop_;

    event TokenContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event LiquidityWithdraw(address indexed wallet, uint256 indexed amount);
    event FoundationWithdraw(address indexed wallet, uint256 indexed amount);
    event MarketingWithdraw(address indexed wallet, uint256 indexed amount);
    event TokenSaleWithdraw(address indexed wallet, uint256 indexed amount);

    event Donate(address indexed from, address indexed to, uint256 value);

    event ClaimAirdrop(address indexed account, uint256 indexed amount);

    event AirdropAdded(address indexed account, uint256 amount);

    event LiquidityAddressAdded(address indexed newAddress);
    event FoundationAddressAdded(address indexed newAddress);
    event MarketingAddressAdded(address indexed newAddress);
    event TokenSaleAddressAdded(address indexed newAddress);

    event LiquidityAddressActiveChanged(
        address indexed newAddress,
        bool indexed actived
    );
    event FoundationAddressActiveChanged(
        address indexed newAddress,
        bool indexed actived
    );
    event MarketingAddressActiveChanged(
        address indexed newAddress,
        bool indexed actived
    );
    event TokenSaleAddressActiveChanged(
        address indexed newAddress,
        bool indexed actived
    );

    /// Withdraw amount exceeds sender's balance of the locked token
    error ExceedsBalance();
    /// Could not transfer the designated ERC20 token
    error TransferFailed();
    /// ERC-20 function is not supported
    error NotSupported();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token) public initializer {
        __Pausable_init();
        __Ownable_init();
        token_ = _token;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() external view override returns (uint256) {
        return ERC20(token_).balanceOf(address(this));
    }

    /// @dev Returns the number of decimals of the locked token
    function decimals() public view returns (uint8) {
        return ERC20(token_).decimals();
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return ERC20(token_).balanceOf(account);
    }

    /**
     * Change address
     */
    function enableLiquidityAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        liquidityAddress_[_address] = active;
        emit LiquidityAddressActiveChanged(_address, active);
    }

    function enableFoundationAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        foundationAddress_[_address] = active;
        emit FoundationAddressActiveChanged(_address, active);
    }

    function enableMarketingAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        marketingAddress_[_address] = active;
        emit MarketingAddressActiveChanged(_address, active);
    }

    function enableTokenSaleAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        tokenSaleAddress_[_address] = active;
        emit TokenSaleAddressActiveChanged(_address, active);
    }

    /**
     * Add address
     */
    function addLiquidityAddress(address _address) public onlyOwner {
        require(_address != address(0), "ERC20: transfer to the zero address");
        liquidityAddress_[_address] = true;
        emit LiquidityAddressAdded(_address);
    }

    function addFoundationAddress(address _address) public onlyOwner {
        require(_address != address(0), "ERC20: transfer to the zero address");
        foundationAddress_[_address] = true;
        emit FoundationAddressAdded(_address);
    }

    function addMarketingAddress(address _address) public onlyOwner {
        require(_address != address(0), "ERC20: transfer to the zero address");
        marketingAddress_[_address] = true;
        emit MarketingAddressAdded(_address);
    }

    function addTokenSaleAddress(address _address) public onlyOwner {
        require(_address != address(0), "ERC20: transfer to the zero address");
        tokenSaleAddress_[_address] = true;
        emit TokenSaleAddressAdded(_address);
    }

    /**
     * Withdraw
     */

    function liquidityWithdraw(address to, uint256 amount)
        external
        override
        whenNotPaused
    {
        require(
            _msgSender() == owner() || liquidityAddress_[_msgSender()],
            "Permission denied"
        );
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!ITokenWithdraw(token_).liquidityWithdraw(to, amount)) {
            revert TransferFailed();
        }

        emit LiquidityWithdraw(to, amount);
    }

    function foundationWithdraw(address to, uint256 amount)
        external
        override
        whenNotPaused
    {
        require(
            _msgSender() == owner() || foundationAddress_[_msgSender()],
            "Permission denied"
        );
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!ITokenWithdraw(token_).foundationWithdraw(to, amount)) {
            revert TransferFailed();
        }

        emit FoundationWithdraw(to, amount);
    }

    function marketingWithdraw(address to, uint256 amount)
        external
        override
        whenNotPaused
    {
        require(
            _msgSender() == owner() || marketingAddress_[_msgSender()],
            "Permission denied"
        );
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!ITokenWithdraw(token_).marketingWithdraw(to, amount)) {
            revert TransferFailed();
        }

        emit MarketingWithdraw(to, amount);
    }

    function tokenSaleWithdraw(address to, uint256 amount)
        external
        override
        whenNotPaused
    {
        require(
            _msgSender() == owner() || tokenSaleAddress_[_msgSender()],
            "Permission denied"
        );
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!ITokenWithdraw(token_).tokenSaleWithdraw(to, amount)) {
            revert TransferFailed();
        }

        emit TokenSaleWithdraw(to, amount);
    }

    /**
     * Get amount
     */

    function getLiquidityTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return ITreasury(token_).getLiquidityTotalAmount();
    }

    function getFoundationTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return ITreasury(token_).getFoundationTotalAmount();
    }

    function getMarketingTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return ITreasury(token_).getMarketingTotalAmount();
    }

    function getTokenSaleTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return ITreasury(token_).getTokenSaleTotalAmount();
    }

    function airdropOf(address account) public view returns (uint256) {
        return airdrop_[account];
    }

    function addAirdrops(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "address cannot be 0");
        require(amount > 0, "Quantity must be greater than 0");
        airdrop_[account] += amount;
        emit AirdropAdded(account, amount);
    }

    function claimAirdrop() public {
        uint256 amount = airdrop_[_msgSender()];
        require(amount > 0, "Addres not receive airdrop!");

        airdrop_[_msgSender()] = 0;

        if (!ERC20(token_).transfer(_msgSender(), amount)) {
            revert TransferFailed();
        }

        emit ClaimAirdrop(_msgSender(), amount);
    }

    function tokenAddress() public view returns (address) {
        return token_;
    }

    function setToken(address _token) public onlyOwner returns (bool) {
        emit TokenContractChanged(token_, _token);
        token_ = _token;
        return true;
    }

    function donate(uint256 amount) public whenNotPaused {
        require(
            ERC20(token_).balanceOf(_msgSender()) > 0,
            "Not enough money in wallet"
        );
        require(
            ERC20(token_).balanceOf(_msgSender()) >= amount,
            "ERC20: insufficient allowance"
        );

        if (!ERC20(token_).transferFrom(_msgSender(), owner(), amount)) {
            revert TransferFailed();
        }

        emit Donate(_msgSender(), owner(), amount);
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transfer is not supported
    function transfer(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 allowance is not supported
    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 approve is not supported
    function approve(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transferFrom is not supported
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert NotSupported();
    }
}
