// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ITokenWithdraw.sol";

/// ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/// [Total Supply]           : 250.000.000 Token.
/// -----------------------------------------------------------------------------------------------------------
/// [Liquidity & Incentives] : 23%
/// [Foundation reserve]     : 21.2%
/// [Team & Advisors]        : 17.4% ➔ Unlock 1.45% more every 3 months.
/// [Marketing]              : 10%
/// -----------------------------------------------------------------------------------------------------------
/// [Token Sale]             : 28.4%
/// ●------------[Seed]      : 10.6% ➔ Unlock 2.65% every 6 months.
/// ●------------[IDO]       : 12.8% ➔ One wallet address can only buy upto 1000 tokens.
/// ●------------[Public]    : 5%
/// -----------------------------------------------------------------------------------------------------------
contract LeboToken is
    Initializable,
    ERC20,
    ERC20Burnable,
    Ownable,
    ITreasury,
    ITokenWithdraw
{
    /// Time of the contract creation
    uint256 internal initializeTime_;

    uint256 internal constant TREASURY_MAX_TOTAL_AMOUNT = 206500000e18; // 82.6%
    uint256 public constant LIQUIDITY_MAX_TOTAL_AMOUNT = 57500000e18; // 23%
    uint256 public constant FOUNDATION_MAX_TOTAL_AMOUNT = 53000000e18; // 21.2%
    uint256 public constant MARKETING_MAX_TOTAL_AMOUNT = 25000000e18; // 10%
    uint256 public constant TOKEN_SALE_MAX_TOTAL_AMOUNT = 71000000e18; // 28.4%
    uint256 public constant VESTION_MAX_TOTAL_AMOUNT = 43500000e18; // 17.4%
    uint256 internal constant VESTION_AMOUNT = 3625000e18;

    uint256 internal liquidityTotalUnlocked_ = 0; // 23%
    uint256 internal foundationTotalUnlocked_ = 0; // 21.2%
    uint256 internal marketingTotalUnlocked_ = 0; // 10%
    uint256 internal tokenSaleTotalUnlocked_ = 0; // 28.4%

    struct vesting {
        uint256 date;
        bool vested;
    }

    /**
     * @dev Throws if called by any account other than the treasury.
     */
    modifier onlyTreasury() {
        _msgSender() == treasury_;
        _;
    }

    /// Marketing + Foundation reserve + Liquidity & Incentives + Token Sale
    address internal treasury_;
    /// locked 2 year
    address internal team_;
    // For storing all vesting stages with structure defined above.
    mapping(address => vesting[]) internal phases;

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

    event TreasuryContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event TeamContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event UnlockToken(
        address indexed wallet,
        uint256 indexed amount,
        uint256 indexed timeUnLocked
    );
    event UnlockLiquidityTreasury(
        address indexed wallet,
        uint256 indexed amount,
        uint256 indexed timeUnLocked
    );
    event UnlockFoundationTreasury(
        address indexed wallet,
        uint256 indexed amount,
        uint256 indexed timeUnLocked
    );
    event UnlockMarketingTreasury(
        address indexed wallet,
        uint256 indexed amount,
        uint256 indexed timeUnLocked
    );
    event UnlockTokenSaleTreasury(
        address indexed wallet,
        uint256 indexed amount,
        uint256 indexed timeUnLocked
    );

    constructor() ERC20("Lebo", "LEBO") {
        team_ = _msgSender();
    }

    function initialize() public initializer onlyOwner {
        initializeTime_ = block.timestamp;
        uint256 _teamCliff = 5 minutes;
        _addPhase(team_, initializeTime_ + (_teamCliff * 1), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 2), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 3), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 4), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 5), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 6), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 7), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 8), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 9), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 10), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 11), false);
        _addPhase(team_, initializeTime_ + (_teamCliff * 12), false);
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury_ = _treasury;
        emit TreasuryContractChanged(treasury_, _treasury);
    }

    function treasuryAddress() public view returns (address) {
        return treasury_;
    }

    function teamAdress() public view returns (address){
        return team_;
    }

    function tranferTeam(address _team) public onlyOwner {
        emit TeamContractChanged(team_, _team);
        phases[_team] = phases[team_];
        team_ = _team;
    }

    function initializeTime() public view returns (uint256) {
        return initializeTime_;
    }

    /**
     * unlock token for treasury
     */

    function unLockLiquidity(uint256 amount) public onlyOwner {
        require(amount > 0, "Not enough money in wallet");
        require(treasury_ != address(0), "Treasury is zero address");
        uint256 totalAmount = liquidityTotalUnlocked_ + amount;
        require(
            totalAmount <= LIQUIDITY_MAX_TOTAL_AMOUNT,
            "The total unlock amount cannot be more than LIQUIDITY_MAX_TOTAL_AMOUNT"
        );

        liquidityTotalUnlocked_ += amount;
        _mint(treasury_, amount);

        emit UnlockLiquidityTreasury(treasury_, amount, block.timestamp);
    }

    function unLockFoundation(uint256 amount) public onlyOwner {
        require(amount > 0, "Not enough money in wallet");
        require(treasury_ != address(0), "Treasury is zero address");
        uint256 totalAmount = foundationTotalUnlocked_ + amount;
        require(
            totalAmount <= FOUNDATION_MAX_TOTAL_AMOUNT,
            "The total unlock amount cannot be more than FOUNDATION_MAX_TOTAL_AMOUNT"
        );

        foundationTotalUnlocked_ += amount;
        _mint(treasury_, amount);

        emit UnlockFoundationTreasury(treasury_, amount, block.timestamp);
    }

    function unLockMarketing(uint256 amount) public onlyOwner {
        require(amount > 0, "Not enough money in wallet");
        require(treasury_ != address(0), "Treasury is zero address");
        uint256 totalAmount = marketingTotalUnlocked_ + amount;
        require(
            totalAmount <= MARKETING_MAX_TOTAL_AMOUNT,
            "The total unlock amount cannot be more than MARKETING_MAX_TOTAL_AMOUNT"
        );

        marketingTotalUnlocked_ += amount;
        _mint(treasury_, amount);

        emit UnlockMarketingTreasury(treasury_, amount, block.timestamp);
    }

    function unLockTokenSale(uint256 amount) public onlyOwner {
        require(amount > 0, "Not enough money in wallet");
        require(treasury_ != address(0), "Treasury is zero address");

        uint256 totalAmount = tokenSaleTotalUnlocked_ + amount;
        require(
            totalAmount <= TOKEN_SALE_MAX_TOTAL_AMOUNT,
            "The total unlock amount cannot be more than TOKEN_SALE_MAX_TOTAL_AMOUNT"
        );

        tokenSaleTotalUnlocked_ += amount;
        _mint(treasury_, amount);

        emit UnlockTokenSaleTreasury(treasury_, amount, block.timestamp);
    }

    /**
     * Withdraw
     */

    function liquidityWithdraw(address to, uint256 amount)
        external
        override
        onlyTreasury
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Not enough money in wallet");
        require(
            amount <= liquidityTotalUnlocked_,
            "Not enough money in wallet"
        );

        liquidityTotalUnlocked_ -= amount;

        return transfer(to, amount);
    }

    function foundationWithdraw(address to, uint256 amount)
        external
        override
        onlyTreasury
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Not enough money in wallet");
        require(
            amount <= foundationTotalUnlocked_,
            "Not enough money in wallet"
        );

        foundationTotalUnlocked_ -= amount;

        return transfer(to, amount);
    }

    function marketingWithdraw(address to, uint256 amount)
        external
        override
        onlyTreasury
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Not enough money in wallet");
        require(
            amount <= marketingTotalUnlocked_,
            "Not enough money in wallet"
        );

        marketingTotalUnlocked_ -= amount;

        return transfer(to, amount);
    }

    function tokenSaleWithdraw(address to, uint256 amount)
        external
        override
        onlyTreasury
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Not enough money in wallet");
        require(
            amount <= tokenSaleTotalUnlocked_,
            "Not enough money in wallet"
        );

        tokenSaleTotalUnlocked_ -= amount;

        return transfer(to, amount);
    }

    function getLiquidityTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return liquidityTotalUnlocked_;
    }

    function getFoundationTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return foundationTotalUnlocked_;
    }

    function getMarketingTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return marketingTotalUnlocked_;
    }

    function getTokenSaleTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return tokenSaleTotalUnlocked_;
    }

    /// withdraw token to team address
    function unLockTeam(address recever, uint8 phase) public onlyOwner {
        if (block.timestamp < phases[recever][phase].date) {
            revert LockPeriodOngoing();
        }

        uint256 amount = _phaseRewardOf(recever, phase);
        if (amount == 0) {
            revert ExceedsBalance();
        }

        _unlockTeam(recever, amount, phase);
    }

    function phasesLockedOf(address wallet)
        public
        view
        returns (vesting[] memory)
    {
        return phases[wallet];
    }

    function timeLockedOf(address wallet, uint8 phase)
        public
        view
        returns (uint256)
    {
        return phases[wallet][phase].date;
    }

    function phaseRewardOf(address wallet, uint8 phase)
        public
        view
        returns (uint256)
    {
        return _phaseRewardOf(wallet, phase);
    }

    function _unlockTeam(
        address recever,
        uint256 amount,
        uint8 phase
    ) internal {
        _mint(recever, amount);
        phases[recever][phase].vested = true;
        emit UnlockToken(recever, amount, block.timestamp);
    }

    function _phaseRewardOf(address recever, uint8 phase)
        internal
        view
        returns (uint256)
    {
        if (phases[recever][phase].vested == true) {
            return 0;
        }
        return VESTION_AMOUNT;
    }

    function _addPhase(
        address wallet,
        uint256 cliff,
        bool vested
    ) internal {
        vesting memory v = vesting(cliff, vested);
        phases[wallet].push(v);
    }
}
