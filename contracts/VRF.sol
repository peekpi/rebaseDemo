// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library VRF {
    address constant VRF_NATIVE = address(255);
    // get current block's vrf
    function vrf() internal view returns(bytes32 _hash) {
        return _vrf("");
    }
    // get vrf by block
    function vrf(uint256 blockNo) internal view returns(bytes32 _hash) {
        return _vrf(abi.encodePacked(blockNo));
    }

    function _vrf(bytes memory blockNo) private view returns(bytes32 _hash) {
        (bool success, bytes memory returndata) = VRF_NATIVE.staticcall(blockNo);
        require(success && returndata.length == 32, "invalid vrf");
        assembly {
            _hash := mload(add(32, returndata))
        }
    }
}
