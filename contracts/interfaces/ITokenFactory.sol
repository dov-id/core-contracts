// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {ProxyBeacon} from "@dlsl/dev-modules/contracts-registry/pools/proxy/ProxyBeacon.sol";

interface ITokenFactory {
    /**
     * @notice The structure that stores information about deploy token contract params
     *
     * @param tokenContractId the deployed token contract ID
     * @param tokenName the token name of the deployed contract
     * @param tokenSymbol the token symbol of the deployed contract
     */
    struct DeployTokenContractParams {
        uint256 tokenContractId;
        string tokenName;
        string tokenSymbol;
    }

    /**
     * @notice The structure that stores base information about the TokenContract
     *
     * @param tokenContractAddr the address of the TokenContract
     */
    struct BaseTokenContractInfo {
        address tokenContractAddr;
    }

    /**
     * @notice The structure that stores information about user's NFTs
     *
     * @param tokenContractAddr the address of the TokenContract
     * @param tokenIDs the array of the user token IDs
     */
    struct UserNFTsInfo {
        address tokenContractAddr;
        uint256[] tokenIDs;
    }

    /**
     * @notice This event is emitted when the URI of the base token contracts has been updated
     *
     * @param newBaseTokenContractsURI the new base URI of token contracts
     */
    event BaseTokenContractsURIUpdated(string newBaseTokenContractsURI);

    /**
     * @notice This event is emitted during the creation of a new TokenContract
     *
     * @param newTokenContractAddr the address of the created token contract
     * @param tokenContractParams structure with the deploy token contract params
     */
    event TokenContractDeployed(
        address newTokenContractAddr,
        DeployTokenContractParams tokenContractParams
    );

    /**
     * @notice The function that updates the base TokenContracts URI parameter
     *
     * @dev Only OWNER can call this function
     *
     * @param baseTokenContractsURI_ the new base token contracts URI value
     */
    function setBaseTokenContractsURI(string memory baseTokenContractsURI_) external;

    /**
     * @notice The function that updates the TokenContract implementation
     *
     * @dev Only OWNER can call this function
     *
     * @param newImplementation_ the new TokenContract implementation
     */
    function setNewImplementation(address newImplementation_) external;

    /**
     * @notice The function for deploying new instances of TokenContract
     *
     * @param params_ structure with the deploy token contract params
     */
    function deployTokenContract(DeployTokenContractParams calldata params_) external;

    /**
     * @notice The function that returns the address of the token contracts beacon
     *
     * @return address of token contracts beacon
     */
    function tokenContractsBeacon() external view returns (ProxyBeacon);

    /**
     * @notice The function that returns the base token contracts URI string
     *
     * @return base token contracts URI string
     */
    function baseTokenContractsURI() external view returns (string memory);

    /**
     * @notice The function that returns the address of the token contract by index
     *
     * @param tokenContractId_ the required token contracts ID
     * @return address of the token contract
     */
    function tokenContractByIndex(uint256 tokenContractId_) external view returns (address);

    /**
     * @notice The function that returns the address of the TokenContracts implementation
     *
     * @return address of the TokenContract implementation
     */
    function getTokenContractsImpl() external view returns (address);

    /**
     * @notice The function that returns the total TokenContracts count
     *
     * @return total TokenContracts count
     */
    function getTokenContractsCount() external view returns (uint256);

    /**
     * @notice The function for getting addresses of token contracts with pagination
     *
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for pagination
     * @return array with the addresses of the token contracts
     */
    function getTokenContractsPart(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory);
}
