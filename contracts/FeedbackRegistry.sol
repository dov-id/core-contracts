// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Paginator} from "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import {IFeedbackRegistry} from "./interfaces/IFeedbackRegistry.sol";
import {ICertIntegrator} from "./interfaces/ICertIntegrator.sol";
import {SMTVerifier} from "./libs/SMTVerifier.sol";
import {RingSignature} from "./libs/RingSignature.sol";

/**
 * @notice The Feedback registry contract
 *
 * 1. The FeedbackRegistry contract is the main contract in the Dov-Id system. It will provide the logic
 *    for adding and storing the course participants’ feedbacks, where the feedback is an IPFS hash that
 *    routes us to the user’s feedback payload on IPFS. Also, it is responsible for validating the ZKP
 *    of NFT owning.
 *
 * 2. The course identifier - is its address as every course is represented by NFT contract.
 *
 * 3. Requirements:
 *    - The contract must receive information about the courses and their participants from the
 *      CertIntegrator contract.
 *    - The ability to add feedback by a user for a specific course with a provided ZKP of NFT owning.
 *      The proof must be validated.
 *    - The ability to retrieve feedbacks with a pagination.
 *
 * 4. Note:
 *    Dev team faced with a zkSnark proof generation problems, so now contract checks that the
 *    addressesMTP root is stored in the CertIntegrator contract and that all MTPs are correct.
 *    The contract checks the ring signature as well, and if it is correct the contract adds feedback
 *    to storage.
 */
contract FeedbackRegistry is IFeedbackRegistry {
    using RingSignature for bytes;
    using SMTVerifier for bytes32;
    using Paginator for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // course address => feedbacks (ipfs)
    mapping(address => string[]) public contractFeedbacks;

    address private _certIntegrator;

    EnumerableSet.AddressSet private _courses;

    constructor(address certIntegrator_) {
        _certIntegrator = certIntegrator_;
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function addFeedback(
        address course_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_,
        bytes32[][] memory merkleTreeProofs_,
        bytes32[] memory keys_,
        bytes32[] memory values_,
        string memory ipfsHash_
    ) external {
        require(
            bytes(ipfsHash_).verify(i_, c_, r_, publicKeysX_, publicKeysY_) == true,
            "FeedbackRegistry: wrong signature"
        );

        ICertIntegrator.Data memory courseData_ = ICertIntegrator(_certIntegrator).getLastData(
            course_
        );

        for (uint k = 0; k < merkleTreeProofs_.length; k++) {
            require(
                courseData_.root.verifyProof(keys_[k], values_[k], merkleTreeProofs_[k]) == true,
                "FeedbackRegistry: wrong Merkle Tree verification"
            );
        }

        _courses.add(course_);
        contractFeedbacks[course_].push(ipfsHash_);
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getFeedbacks(
        address course_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (string[] memory list_) {
        uint256 to_ = Paginator.getTo(contractFeedbacks[course_].length, offset_, limit_);

        list_ = new string[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = contractFeedbacks[course_][i];
        }
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getCourses(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory courses_) {
        courses_ = _courses.part(offset_, limit_);
    }
}
