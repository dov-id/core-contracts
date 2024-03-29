// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {IVerifier} from "./interfaces/IVerifier.sol";
import {SMTVerifier} from "./libs/SMTVerifier.sol";
import {RingSignature} from "./libs/RingSignature.sol";

/**
 * @notice The Verifier contract
 *
 * 1. When we have some token in main chain, but at the same time interact with another chains,
 *    sometimes there is a need to operate data directly from one of these chains.
 *
 * 2. This contract solves such problem, by verifying that user definitely owns such token in
 *    main chain and minting token with the same uri.
 *
 * 3. Verification takes part according to such flow:
 *    a. Our contract verifies signature
 *    b. It makes call to integrator contract in order to get last root with block that was
 *       published there. Then using sparse Merkle Tree proof, key and value verifies proof
 *       with help of SMTVerifier lib
 *    c. If everything was processed without errors verifier contract will make a call to
 *       the contract address to mint new token in side-chain.
 *
 * 4. Note:
 *    a. As signature now we process ring signature
 *    b. As Merkle Tree proof contract waits Sparse Merkle Tree Proof. During testing was used
 *       proofs from such [realization](https://github.com/iden3/go-merkletree-sql)
 */
contract Verifier is IVerifier {
    using RingSignature for bytes;
    using SMTVerifier for bytes32;

    address internal _integrator;

    constructor(address integrator_) {
        _integrator = integrator_;
    }

    /**
     * @inheritdoc IVerifier
     */
    function verifyContract(
        address contract_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_,
        bytes32[][] memory merkleTreeProofs_,
        bytes32[] memory keys_,
        bytes32[] memory values_,
        string memory tokenUri_
    ) external returns (uint256) {
        require(
            bytes(tokenUri_).verify(i_, c_, r_, publicKeysX_, publicKeysY_) == true,
            "Verifier: wrong signature"
        );

        (bool success_, bytes memory data_) = _integrator.call(
            abi.encodeWithSignature("getLastData(address)", contract_)
        );

        require(success_, "Verifier: failed to get last data");

        Data memory courseData_ = abi.decode(data_, (Data));

        for (uint k = 0; k < merkleTreeProofs_.length; k++) {
            require(
                courseData_.root.verifyProof(keys_[k], values_[k], merkleTreeProofs_[k]) == true,
                "Verifier: wrong Merkle Tree verification"
            );
        }

        (success_, data_) = contract_.call(
            abi.encodeWithSignature("mintToken(address,string)", msg.sender, tokenUri_)
        );

        require(success_, "Verifier: failed to mint token");

        return uint256(bytes32(data_));
    }
}
