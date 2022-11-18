// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IEIP1271Implementer} from "../interfaces/IEIP1271Implementer.sol";
import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";

import "./Constants.sol";

/**
 * @title MetaTxHelpers
 * @author Lens Protocol
 * @notice A library containing helper functions for meta-transactions.
 */
library MetaTxHelpers {
    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = expectedAddress;
        // If the expected address is a contract, check the signature there.
        if (recoveredAddress.code.length != 0) {
            bytes memory concatenatedSig = abi.encodePacked(sig.r, sig.s, sig.v);
            if (IEIP1271Implementer(expectedAddress).isValidSignature(digest, concatenatedSig) != EIP1271_MAGIC_VALUE) {
                revert Errors.SignatureInvalid();
            }
        } else {
            recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
            if (recoveredAddress == address(0) || recoveredAddress != expectedAddress) {
                revert Errors.SignatureInvalid();
            }
        }
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     * @param domainSeparator The domain separator to use in creating the digest.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage, bytes32 domainSeparator) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashedMessage));
        }
        return digest;
    }
}