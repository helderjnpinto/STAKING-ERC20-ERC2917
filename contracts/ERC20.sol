//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './libraries/SafeMath.sol';
import './interface/IERC20.sol';

abstract contract ERC20 is IERC20 {
    using SafeMath for uint;

    string override public name;
    string override public symbol;
    uint8 override public decimals = 18;
    uint override public totalSupply;

    mapping(address => uint) override public balanceOf;
    // mapping(address => mapping(address => uint)) override public allowance;

    constructor() {
        name        = "USDP TOKEN";
        symbol      = "USDP";
    }

    // function _transfer(address from, address to, uint value) internal {
    //     require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
    //     balanceOf[from] = balanceOf[from].sub(value);
    //     balanceOf[to] = balanceOf[to].add(value);
    //     if (to == address(0)) { 
    //         // burn
    //         totalSupply = totalSupply.sub(value);
    //     }
    //     emit Transfer(from, to, value);
    // }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    // function approve(address spender, uint value) external override returns (bool) {
    //     allowance[msg.sender][spender] = value;
    //     emit Approval(msg.sender, spender, value);
    //     return true;
    // }

    // function transferFrom(address from, address to, uint value) external override returns (bool) {
    //     require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
    //     allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    //     _transfer(from, to, value);
    //     return true;
    // }

    // function transfer(address to, uint value) external override returns (bool) {
    //     _transfer(msg.sender, to, value);
    //     return true;
    // }

    function deposit(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] += amount;
        totalSupply = totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        return true;
    }

    function withdrawal(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        balanceOf[account] = accountBalance - amount;
        
        totalSupply = totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        return true;
    }
}
