// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address user)
        external
        view
        returns (uint256);

    function pendingSpirit(uint256 _pid, address _user)
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

contract SpiritCompound is Initializable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PID = 1;

    IERC20Upgradeable public constant spirity =
        IERC20Upgradeable(0x5Cc61A78F164885776AA610fb0FE1257df78E59B);

    IERC20Upgradeable public constant lp =
        IERC20Upgradeable(0x30748322B6E34545DBe0788C421886AEB5297789);

    IRouter public constant router =
        IRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);

    IMasterChef public constant masterChef =
        IMasterChef(0x9083EA3756BDE6Ee6f27a6e996806FBD37F6F093);

    IERC20Upgradeable public constant wftm =
        IERC20Upgradeable(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    address[] public spirity_to_ftm;

    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Owner required");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        spirity.safeApprove(address(router), uint256(-1));
        wftm.safeApprove(address(router), uint256(-1));
        lp.safeApprove(address(masterChef), uint256(-1));
        spirity_to_ftm = [
            0x5Cc61A78F164885776AA610fb0FE1257df78E59B,
            0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83
        ];
    }

    function deposit(uint256 amount) public onlyOwner {
        lp.safeTransferFrom(msg.sender, address(this), amount);
        masterChef.deposit(PID, amount);
    }

    function depositAll() public onlyOwner {
        uint256 lp_wallet_balance = lp.balanceOf(msg.sender);
        uint256 lp_contract_balance = lp.balanceOf(address(this));

        uint256 total_balance = lp_wallet_balance.add(lp_contract_balance);

        lp.safeTransferFrom(msg.sender, address(this), lp_wallet_balance);
        masterChef.deposit(PID, total_balance);
    }

    function withdraw(uint256 amount) public onlyOwner {
        masterChef.withdraw(PID, amount);
    }

    function withdrawAll() public onlyOwner {
        uint256 staked_lp_balance = masterChef.userInfo(PID, address(this));
        withdraw(staked_lp_balance);

        uint256 lp_balance = lp.balanceOf(address(this));
        uint256 spirity_balance = spirity.balanceOf(address(this));
        uint256 wftm_balance = wftm.balanceOf(address(this));

        lp.safeTransfer(msg.sender, lp_balance);
        spirity.safeTransfer(msg.sender, spirity_balance);
        wftm.safeTransfer(msg.sender, wftm_balance);
    }

    function harvest() public onlyOwner {
        uint256 staked_lp_balance = masterChef.userInfo(PID, address(this));
        withdraw(staked_lp_balance);
        uint256 spirity_balance = spirity.balanceOf(address(this));
        uint256 to_ftm = spirity_balance.mul(50).div(100);

        router.swapExactTokensForTokens(
            to_ftm,
            0,
            spirity_to_ftm,
            address(this),
            now + 1800
        );

        uint256 wftm_balance = wftm.balanceOf(address(this));

        router.addLiquidity(
            address(spirity),
            address(wftm),
            to_ftm,
            wftm_balance,
            0,
            0,
            address(this),
            now + 1800
        );

        uint256 lp_balance = lp.balanceOf(address(this));
        masterChef.deposit(PID, lp_balance);
    }

    function pending() public view returns (uint256) {
        return masterChef.pendingSpirit(PID, address(this));
    }

    function staked() public view returns (uint256) {
        return masterChef.userInfo(PID, address(this));
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
        spirity.safeApprove(address(router), uint256(-1));
        wftm.safeApprove(address(router), uint256(-1));
        lp.safeApprove(address(masterChef), uint256(-1));
    }

    function setNewOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}
