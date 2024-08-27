//Smart Contract-based Exams: Automated grading and certification via smart contracts
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ExamSystem {
    address public admin;
    struct Exam {
        string question;
        bytes32 correctAnswerHash;
    }
    
    struct Student {
        uint score;
        bool hasTakenExam;
    }

    Exam[] public exams;
    mapping(address => Student) public students;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createExam(string memory _question, string memory _correctAnswer) public onlyAdmin {
        bytes32 answerHash = keccak256(abi.encodePacked(_correctAnswer));
        exams.push(Exam(_question, answerHash));
    }

    function takeExam(string[] memory _answers) public {
        require(!students[msg.sender].hasTakenExam, "Student has already taken the exam");

        uint score = 0;

        for (uint i = 0; i < exams.length; i++) {
            if (keccak256(abi.encodePacked(_answers[i])) == exams[i].correctAnswerHash) {
                score++;
            }
        }

        students[msg.sender] = Student(score, true);
    }

    function getScore() public view returns (uint) {
        require(students[msg.sender].hasTakenExam, "Student has not taken the exam yet");
        return students[msg.sender].score;
    }
}
