// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { VRF } from "./VRF.sol";

library BinarySearch {
    struct SearchTicket { // used to binary search
        address user;
        uint256 accumulateTicktes;
    }

    function search(SearchTicket[] storage searches, uint256 tickets) internal view returns (uint256) {
        if (searches.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = searches.length;

        while (low < high) {
            // (a + b) / 2 can overflow.
            uint256 mid =  (low & high) + (low ^ high) / 2;

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (searches[mid].accumulateTicktes > tickets) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return low;
    }
}

contract Bucket {
    using BinarySearch for BinarySearch.SearchTicket[];

    mapping(address=>uint256) public tickets; // total tickets a user deposit
    BinarySearch.SearchTicket[] public searchList; // used to generate whiltelist
    uint256 public rnd; // vrf random number. 0 means not init.
    uint256 public winnerNum; // number of winner

    event AddTickets(address user, uint256 amount);
    event Raffle(address operator, uint256 rnd);

    constructor(uint256 _winnerNum) {
        winnerNum = _winnerNum;
    }

    // get current block's vrf
    function vrf(uint256 blockNo) public view returns(bytes32 _hash) {
        return blockNo == 0 ? VRF.vrf() : VRF.vrf(blockNo);
    }
    // get random number
    function random(bool useVRF) public view returns(uint256) {
        return useVRF ? uint256(VRF.vrf()) : uint256(keccak256(abi.encodePacked(block.timestamp)));
    }

    function randomI(uint256 _rnd, uint256 i) private pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_rnd,i)));
    }

    // get whiltelist at the index
    function winnerAt(uint256 i) public view returns(address) {
        uint256 totalTickets = searchList[searchList.length - 1].accumulateTicktes;
        uint256 _rnd = randomI(rnd, i);
        uint256 ticketPosition = _rnd % totalTickets;
        uint256 findIndex = searchList.search(ticketPosition);
        return searchList[findIndex].user;
    }
    // get whiltelist of a round
    function winners() external view returns(address[] memory results) {
        require(rnd != 0, "not raffled");
        results = new address[](winnerNum);
        for(uint256 i = 0; i < winnerNum; i++){
            results[i] = winnerAt(i);
        }
    }

    // user add their tickets
    function addTickets(uint256 amount) external {
        require(rnd == 0, "bucket already closed");

        if(searchList.length > 0 &&  searchList[searchList.length-1].user == msg.sender) {
            searchList[searchList.length-1].accumulateTicktes += amount;
        } else {
            uint256 accumulateTicktes = searchList.length > 0
                ? searchList[searchList.length-1].accumulateTicktes + amount
                : amount;
            searchList.push(BinarySearch.SearchTicket({
                user: msg.sender,
                accumulateTicktes: accumulateTicktes
            }));
        }
        tickets[msg.sender] += amount;
        emit AddTickets(msg.sender, amount);
    }

    // do raffle
    function raffle() external {
        require(rnd == 0, "already raffled");
        rnd = random(true);
        emit Raffle(msg.sender, rnd);
    }
}
