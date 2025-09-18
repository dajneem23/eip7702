// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Fund Holding Contract
 * @dev This contract serves as a simple vault to hold Ether and ERC20 tokens.
 * A designated owner can withdraw the entire balance of these assets.
 * The owner's address is hardcoded into the contract.
 */
contract FundHolder {

    // The address of the owner who is authorized to withdraw all funds.
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // A sentinel address used in the sweepTokens function to signify a withdrawal of Ether
    // instead of an ERC20 token.
    address private constant ETH_ADDRESS_SENTINEL = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    constructor(address payable _owner) {
        require(_owner != address(0), "Owner address cannot be zero");
        owner = _owner;
    }

    /**
     * @dev The receive function is triggered when the contract receives Ether without any
     * calldata. It immediately forwards the received Ether to the owner.
     */
    receive() external payable {
        // Check if there's any balance to send.
        if (address(this).balance > 0) {
            _sendETH(owner, address(this).balance);
        }
    }

    // --- Public Functions ---

    /**
     * @notice Withdraws the contract's entire Ether balance to the owner.
     * @dev This corresponds to the function selector `0xe086e5ec`.
     */
    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            _sendETH(owner, balance);
        }
    }

    /**
     * @notice Withdraws the contract's entire balance of a specific ERC20 token to the owner.
     * @dev This corresponds to the function selector `0xf4f3b200`.
     * @param _tokenAddress The address of the ERC20 token contract.
     */
    function withdrawERC20(address _tokenAddress) public onlyOwner {
        // Query the balance of the specified token held by this contract.
        uint256 balance = _getERC20Balance(_tokenAddress, address(this));

        // If the balance is greater than zero, transfer it to the owner.
        if (balance > 0) {
            _sendERC20(_tokenAddress, owner, balance);
        }
    }

    /**
     * @notice Sweeps (withdraws) the full balance of multiple assets (ERC20 tokens or Ether) to the owner.
     * @dev This corresponds to the function selector `0x909b19d9`.
     * To withdraw Ether, include the sentinel address 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee in the array.
     * @param _tokenAddresses An array of ERC20 token addresses to withdraw.
     */
    function sweepTokens(address[] memory _tokenAddresses) public onlyOwner {
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            address currentAddress = _tokenAddresses[i];

            // Check if the address is the sentinel for ETH.
            if (currentAddress == ETH_ADDRESS_SENTINEL) {
                // Withdraw the contract's entire Ether balance.
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    _sendETH(owner, ethBalance);
                }
            } else {
                // For a regular address, treat it as an ERC20 token.
                // Withdraw the contract's entire balance for that token.
                uint256 erc20Balance = _getERC20Balance(currentAddress, address(this));
                if (erc20Balance > 0) {
                    _sendERC20(currentAddress, owner, erc20Balance);
                }
            }
        }
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to send Ether.
     * @param _to The recipient's address.
     * @param _amount The amount of Ether to send.
     */
    function _sendETH(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Internal function to transfer a specified amount of an ERC20 token.
     * @param _token The token's contract address.
     * @param _to The recipient's address.
     * @param _amount The amount of the token to send.
     */
    function _sendERC20(address _token, address _to, uint256 _amount) internal {
        // Executes a low-level call equivalent to IERC20(_token).transfer(_to, _amount)
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20 transfer failed");
    }

    /**
     * @dev Internal function to get the ERC20 balance of an account.
     * @param _token The token's contract address.
     * @param _account The account address to query.
     * @return The balance of the account.
     */
    function _getERC20Balance(address _token, address _account) internal view returns (uint256) {
        // Executes a low-level call equivalent to IERC20(_token).balanceOf(_account)
        (bool success, bytes memory data) = _token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", _account)
        );
        require(success, "balanceOf call failed");
        return abi.decode(data, (uint256));
    }
}