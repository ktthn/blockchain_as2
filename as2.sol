// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    address public zeynep = 0x94276E0c160CE7170a92Ac451cb04779baf0dbdf;
    address public aygerim = 0xa5235F5E75E5Ba54Df7fA5d849FB005Ac0d79D77;
    uint256 public betAmount;
    uint256 public revealDeadline;

    bytes32 public hashedMove1;
    bytes32 public hashedMove2;
    string public clearMove1;
    string public clearMove2;

    enum Move {None, Rock, Paper, Scissors}
    mapping(address => Move) public moves;

    modifier onlyRegisteredPlayers() {
        require(msg.sender == zeynep || msg.sender == aygerim, "You are not a registered player");
        _;
    }

    modifier onlyBeforeRevealDeadline() {
        require(block.timestamp < revealDeadline, "Reveal deadline has passed");
        _;
    }

    modifier onlyAfterRevealDeadline() {
        require(block.timestamp >= revealDeadline, "Reveal deadline has not passed yet");
        _;
    }

    modifier onlyIfBothPlayersPlayed() {
        require(bothPlayed(), "Both players haven't played yet");
        _;
    }

    modifier onlyIfBothPlayersRevealed() {
        require(bothRevealed(), "Both players haven't revealed yet");
        _;
    }

    modifier onlyIfDraw() {
        require(moves[zeynep] == moves[aygerim], "It's not a draw");
        _;
    }

    modifier onlyIfWinner() {
        require(
            (moves[zeynep] == Move.Rock && moves[aygerim] == Move.Scissors) ||
            (moves[zeynep] == Move.Paper && moves[aygerim] == Move.Rock) ||
            (moves[zeynep] == Move.Scissors && moves[aygerim] == Move.Paper),
            "No winner found"
        );
        _;
    }

    event GameResult(address winner, uint256 reward);

    constructor() {
        betAmount = 0.0001 ether;
    }

    function register() external {
        require(zeynep == address(0) || aygerim == address(0), "Both players are already registered");
        if (zeynep == address(0)) {
            zeynep = msg.sender;
        } else {
            aygerim = msg.sender;
        }
    }

    function play(bytes32 encrMove) external onlyRegisteredPlayers {
        require(moves[msg.sender] == Move.None, "You've already played");

        moves[msg.sender] = Move.None; // Default value
        hashedMove1 = encrMove;

        if (msg.sender == zeynep) {
            revealDeadline = block.timestamp + 1 minutes; // Set the reveal deadline
        }
    }

    function reveal(string memory clearMove) external onlyRegisteredPlayers onlyBeforeRevealDeadline {
        require(keccak256(abi.encodePacked(clearMove)) == hashedMove1 || keccak256(abi.encodePacked(clearMove)) == hashedMove2, "Invalid clear move");

        if (msg.sender == zeynep) {
            moves[zeynep] = parseMove(clearMove);
            clearMove1 = clearMove;
        } else {
            moves[aygerim] = parseMove(clearMove);
            clearMove2 = clearMove;
        }
    }

    function getOutcome() external onlyRegisteredPlayers onlyIfBothPlayersPlayed onlyAfterRevealDeadline {
        if (bothRevealed()) {
            if (moves[zeynep] == moves[aygerim]) {
                // It's a draw
                payable(zeynep).transfer(betAmount);
                payable(aygerim).transfer(betAmount);
                emit GameResult(address(0), betAmount * 2);
            } else if ((moves[zeynep] == Move.Rock && moves[aygerim] == Move.Scissors) ||
                       (moves[zeynep] == Move.Paper && moves[aygerim] == Move.Rock) ||
                       (moves[zeynep] == Move.Scissors && moves[aygerim] == Move.Paper)) {
                // Player 1 wins
                payable(zeynep).transfer(betAmount * 2);
                emit GameResult(zeynep, betAmount * 2);
            } else {
                // Player 2 wins
                payable(aygerim).transfer(betAmount * 2);
                emit GameResult(aygerim, betAmount * 2);
            }
            resetGame();
        }
    }

    function parseMove(string memory move) internal pure returns (Move) {
        if (keccak256(abi.encodePacked(move)) == keccak256(abi.encodePacked("Rock"))) {
            return Move.Rock;
        } else if (keccak256(abi.encodePacked(move)) == keccak256(abi.encodePacked("Paper"))) {
            return Move.Paper;
        } else if (keccak256(abi.encodePacked(move)) == keccak256(abi.encodePacked("Scissors"))) {
            return Move.Scissors;
        } else {
            revert("Invalid move");
        }
    }

    function resetGame() internal {
        zeynep = address(0);
        aygerim = address(0);
        moves[zeynep] = Move.None;
        moves[aygerim] = Move.None;
        revealDeadline = 0;
        hashedMove1 = 0;
        hashedMove2 = 0;
        clearMove1 = "";
        clearMove2 = "";
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function whoAmI() external view returns (uint256) {
        if (msg.sender == zeynep) {
            return 1;
        } else if (msg.sender == aygerim) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothPlayed() public view returns (bool) {
        return (moves[zeynep] != Move.None && moves[aygerim] != Move.None);
    }

    function bothRevealed() public view returns (bool) {
        return (bytes(clearMove1).length > 0 && bytes(clearMove2).length > 0);
    }

    function revealTimeLeft() external view returns (uint256) {
        if (block.timestamp < revealDeadline) {
            return revealDeadline - block.timestamp;
        } else {
            return 0;
        }
    }
}
