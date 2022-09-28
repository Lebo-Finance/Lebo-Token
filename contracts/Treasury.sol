// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/ITreasury.sol";

/// ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/// [Max Supply]             : 250.000.000 Token.
/// -----------------------------------------------------------------------------------------------------------
/// [Liquidity & Incentives] : 23%
/// [Foundation reserve]     : 21.2%
/// [Team & Advisors]        : 17.4% ➔ Unlock 1.45% more every 3 months.
/// [Marketing]              : 10%
/// -----------------------------------------------------------------------------------------------------------
/// [Token Sale]             : 28.4%
/// -----------------------------------------------------------------------------------------------------------
contract Treasury is
    Initializable,
    IERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ITreasury
{
    uint256 internal initializeTime_;
    // For storing all vesting stages with structure defined above.
    mapping(address => vesting[]) internal phases;

    uint256 public constant LIQUIDITY_MAX_RELEASE_AMOUNT = 57500000e18; // 23%
    uint256 public constant FOUNDATION_MAX_RELEASE_AMOUNT = 53000000e18; // 21.2%
    uint256 public constant MARKETING_MAX_RELEASE_AMOUNT = 25000000e18; // 10%
    uint256 public constant TOKEN_SALE_MAX_RELEASE_AMOUNT = 71000000e18; // 28.4%
    uint256 public constant TEAM_MAX_RELEASE_AMOUNT = 43500000e18; // 17.4%
    uint256 internal constant RELEASE_AMOUNT = 3625000e18;

    uint256 internal teamReleased_; // 23%
    uint256 internal liquidityReleased_; // 23%
    uint256 internal foundationReleased_; // 21.2%
    uint256 internal marketingReleased_; // 10%
    uint256 internal tokenSaleReleased_; // 28.4%

    mapping(address => bool) internal liquidityAddress_;
    mapping(address => bool) internal foundationAddress_;
    mapping(address => bool) internal marketingAddress_;
    mapping(address => bool) internal tokenSaleAddress_;

    mapping(address => uint256) internal airdrop_;

    struct vesting {
        uint256 date;
        bool vested;
    }

    event TeamWithdraw(address indexed wallet, uint256 indexed amount);
    event LiquidityWithdraw(address indexed wallet, uint256 indexed amount);
    event FoundationWithdraw(address indexed wallet, uint256 indexed amount);
    event MarketingWithdraw(address indexed wallet, uint256 indexed amount);
    event TokenSaleWithdraw(address indexed wallet, uint256 indexed amount);

    event LiquidityAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );
    event FoundationAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );
    event MarketingAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );
    event TokenSaleAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );

    event ClaimAirdrop(address indexed account, uint256 indexed amount);
    event AirdropAdded(address indexed account, uint256 amount);

    /// Withdraw amount exceeds sender's balance of the locked token
    error ExceedsBalance();
    /// Deposit is not possible anymore because the deposit period is over
    error DepositPeriodOver();
    /// Withdraw is not possible because the lock period is not over yet
    error LockPeriodOngoing();
    /// Could not transfer the designated ERC20 token
    error TransferFailed();
    /// ERC-20 function is not supported
    error NotSupported();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() external view returns (uint256) {
        return
            teamReleased_ +
            liquidityReleased_ +
            foundationReleased_ +
            marketingReleased_ +
            tokenSaleReleased_;
    }

    function balanceOf(address token) external view returns (uint256) {
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    /**
     * Change address
     */
    function setLiquidityAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        liquidityAddress_[_address] = active;
        emit LiquidityAddressUpdated(_address, active);
    }

    function setFoundationAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        foundationAddress_[_address] = active;
        emit FoundationAddressUpdated(_address, active);
    }

    function setMarketingAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        marketingAddress_[_address] = active;
        emit MarketingAddressUpdated(_address, active);
    }

    function setTokenSaleAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        tokenSaleAddress_[_address] = active;
        emit TokenSaleAddressUpdated(_address, active);
    }

    /**
     * Withdraw
     */

    function liquidityWithdraw(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || liquidityAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (liquidityReleased_ + amount) < LIQUIDITY_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        liquidityReleased_ += amount;
        emit LiquidityWithdraw(to, amount);

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    function foundationWithdraw(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || foundationAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (foundationReleased_ + amount) < FOUNDATION_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        foundationReleased_ += amount;
        emit FoundationWithdraw(to, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    function marketingWithdraw(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || marketingAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (marketingReleased_ + amount) < MARKETING_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        marketingReleased_ += amount;
        emit MarketingWithdraw(to, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    function tokenSaleWithdraw(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || tokenSaleAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (tokenSaleReleased_ + amount) < TOKEN_SALE_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        tokenSaleReleased_ += amount;
        emit TokenSaleWithdraw(to, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    /**
     * Get amount
     */

    function getTeamReleased() external view override returns (uint256) {
        return teamReleased_;
    }

    function getLiquidityReleased() external view override returns (uint256) {
        return liquidityReleased_;
    }

    function getFoundationReleased() external view override returns (uint256) {
        return foundationReleased_;
    }

    function getMarketingReleased() external view override returns (uint256) {
        return marketingReleased_;
    }

    function getTokenSaleReleased() external view override returns (uint256) {
        return tokenSaleReleased_;
    }

    /**
     * Airdrop
     */

    function airdropOf(address account) public view returns (uint256) {
        return airdrop_[account];
    }

    function addAirdrops(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "address cannot be 0");
        require(amount > 0, "Quantity must be greater than 0");
        airdrop_[account] += amount;
        emit AirdropAdded(account, amount);
    }

    function claimAirdrop(address token) public {
        require(airdrop_[_msgSender()] > 0, "Address not receive airdrop");
        uint256 amount = airdrop_[_msgSender()];
        airdrop_[_msgSender()] = 0;
        emit ClaimAirdrop(_msgSender(), amount);
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(token),
            _msgSender(),
            amount
        );
    }

    /**
     *  Team relased
     */

    function start() public onlyOwner {
        initializeTime_ = block.timestamp;
        uint256 _teamCliff = 30 days;
        _addPhase(owner(), initializeTime_ + (_teamCliff * 1), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 2), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 3), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 4), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 5), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 6), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 7), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 8), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 9), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 10), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 11), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 12), false);
    }

    function release(
        address token,
        address recever,
        uint8 phase
    ) public onlyOwner {
        if (block.timestamp < phases[recever][phase].date) {
            revert LockPeriodOngoing();
        }

        uint256 amount = _phaseRewardOf(recever, phase);
        if (amount == 0) {
            revert ExceedsBalance();
        }

        _release(token, recever, amount, phase);
    }

    function phasesLockedOf(address wallet)
        public
        view
        returns (vesting[] memory)
    {
        return phases[wallet];
    }

    function releasedOf(address wallet, uint8 phase)
        public
        view
        returns (uint256)
    {
        return _phaseRewardOf(wallet, phase);
    }

    function _release(
        address token,
        address recever,
        uint256 amount,
        uint8 phase
    ) internal {
        phases[recever][phase].vested = true;
        teamReleased_ += amount;
        emit TeamWithdraw(recever, amount);
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(token),
            _msgSender(),
            amount
        );
    }

    function _phaseRewardOf(address recever, uint8 phase)
        internal
        view
        returns (uint256)
    {
        if (phases[recever][phase].vested == true) {
            return 0;
        }
        return RELEASE_AMOUNT;
    }

    function _addPhase(
        address wallet,
        uint256 cliff,
        bool vested
    ) internal {
        vesting memory v = vesting(cliff, vested);
        phases[wallet].push(v);
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
