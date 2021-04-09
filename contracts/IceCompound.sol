// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface ISorbettiere {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address user)
        external
        view
        returns (uint256);

    function pendingIce(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

interface IRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

contract IceCompound is Initializable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PID = 1;

    IERC20Upgradeable public constant ice =
        IERC20Upgradeable(0xf16e81dce15B08F326220742020379B855B87DF9);

    IERC20Upgradeable public constant lp =
        IERC20Upgradeable(0x84311ECC54D7553378c067282940b0fdfb913675);

    IRouter public constant router =
        IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    ISorbettiere public constant sorbettiere =
        ISorbettiere(0x05200cB2Cee4B6144B2B2984E246B52bB1afcBD0);

    IERC20Upgradeable public constant wftm =
        IERC20Upgradeable(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    address[] public ice_to_ftm;

    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Owner required");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        ice.safeApprove(address(router), uint256(-1));
        wftm.safeApprove(address(router), uint256(-1));
        lp.safeApprove(address(sorbettiere), uint256(-1));
        ice_to_ftm = [
            0xf16e81dce15B08F326220742020379B855B87DF9,
            0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83
        ];
    }

    function deposit(uint256 amount) public onlyOwner {
        lp.safeTransferFrom(msg.sender, address(this), amount);
        sorbettiere.deposit(PID, amount);
    }

    function depositAll() public onlyOwner {
        uint256 lp_wallet_balance = lp.balanceOf(msg.sender);
        uint256 lp_contract_balance = lp.balanceOf(address(this));

        uint256 total_balance = lp_wallet_balance.add(lp_contract_balance);

        lp.safeTransferFrom(msg.sender, address(this), lp_wallet_balance);
        sorbettiere.deposit(PID, total_balance);
    }

    function withdraw(uint256 amount) public onlyOwner {
        sorbettiere.withdraw(PID, amount);
    }

    function withdrawAll() public onlyOwner {
        uint256 staked_lp_balance = sorbettiere.userInfo(PID, address(this));
        withdraw(staked_lp_balance);

        uint256 lp_balance = lp.balanceOf(address(this));
        uint256 ice_balance = ice.balanceOf(address(this));
        uint256 wftm_balance = wftm.balanceOf(address(this));

        lp.safeTransfer(msg.sender, lp_balance);
        ice.safeTransfer(msg.sender, ice_balance);
        wftm.safeTransfer(msg.sender, wftm_balance);
    }

    function harvest() public onlyOwner {
        uint256 staked_lp_balance = sorbettiere.userInfo(PID, address(this));
        withdraw(staked_lp_balance);
        uint256 ice_balance = ice.balanceOf(address(this));
        uint256 to_ftm = ice_balance.mul(50).div(100);

        router.swapExactTokensForTokens(
            to_ftm,
            0,
            ice_to_ftm,
            address(this),
            now + 1800
        );

        uint256 wftm_balance = wftm.balanceOf(address(this));

        router.addLiquidity(
            address(ice),
            address(wftm),
            to_ftm,
            wftm_balance,
            0,
            0,
            address(this),
            now + 1800
        );

        uint256 lp_balance = lp.balanceOf(address(this));
        sorbettiere.deposit(PID, lp_balance);
    }

    function pending() public view returns (uint256) {
        return sorbettiere.pendingIce(PID, address(this));
    }

    function staked() public view returns (uint256) {
        return sorbettiere.userInfo(PID, address(this));
    }

    function tokenOut(address token) public onlyOwner {
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(msg.sender, balance);
    }

    function nativeOut() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool result, ) = msg.sender.call{value: balance}("");
        require(result, "Transfer of FTM failed");
    }

    function reApprove() public {
        ice.safeApprove(address(router), uint256(-1));
        wftm.safeApprove(address(router), uint256(-1));
        lp.safeApprove(address(sorbettiere), uint256(-1));
    }

    function setNewOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}
