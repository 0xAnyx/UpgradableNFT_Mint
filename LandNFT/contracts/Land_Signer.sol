//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract LandSigner is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "LAND";
    string private constant SIGNATURE_VERSION = "1";

    struct WhiteList {
        address userAddress;
        bytes signature;
    }

    function __LandSigner_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    function getSigner(WhiteList memory land) internal view returns (address) {
        return _verify(land);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(WhiteList memory land) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "WhiteList(address userAddress)"
                    ),
                    land.userAddress
                )
            )
        );
    }

    function _verify(WhiteList memory land) internal view returns (address) {
        bytes32 digest = _hash(land);
        return ECDSAUpgradeable.recover(digest, land.signature);
    }
}