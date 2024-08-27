//Smart Contract-based Exams: Automated grading and certification via smart contracts
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ExamSystem {
    address public admin;
    uint public passingScore = 50;

    // Structure representing an exam
    struct Exam {
        uint examId;
        string title;
        string[] questions;
        bytes32[] correctAnswerHashes;
        uint timeLimit; 
        bool isActive;
    }

    // Structure representing a student
    struct Student {
        uint score;
        bool hasTakenExam;
        uint[] examIdsTaken;
        mapping(uint => bool) examsTaken;
    }

    struct Teacher {
        bool isApproved;
    }

    Exam[] public exams;
    mapping(address => Student) public students;
    mapping(address => Teacher) public teachers;

    event ExamCreated(uint examId, string title, uint timeLimit);
    event ExamSubmitted(address student, uint examId, uint score);
    event CertificateIssued(address student, uint examId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyTeacher() {
        require(teachers[msg.sender].isApproved, "Only approved teacher can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Admin functions
    function approveTeacher(address _teacher) public onlyAdmin {
        teachers[_teacher].isApproved = true;
    }

    function setPassingScore(uint _passingScore) public onlyAdmin {
        passingScore = _passingScore;
    }

    // Teacher functions
    function createExam(
        string memory _title,
        string[] memory _questions,
        string[] memory _correctAnswers,
        uint _timeLimit
    ) public onlyTeacher {
        require(_questions.length == _correctAnswers.length, "Questions and answers count mismatch");
        
        bytes32[] memory answerHashes = new bytes32[](_correctAnswers.length);
        for (uint i = 0; i < _correctAnswers.length; i++) {
            answerHashes[i] = keccak256(abi.encodePacked(_correctAnswers[i]));
        }

        uint examId = exams.length;
        exams.push(Exam({
            examId: examId,
            title: _title,
            questions: _questions,
            correctAnswerHashes: answerHashes,
            timeLimit: _timeLimit,
            isActive: true
        }));

        emit ExamCreated(examId, _title, _timeLimit);
    }

    function activateExam(uint _examId, bool _isActive) public onlyTeacher {
        require(_examId < exams.length, "Exam does not exist");
        exams[_examId].isActive = _isActive;
    }

    // Student functions
    function takeExam(uint _examId, string[] memory _answers) public {
        require(_examId < exams.length, "Exam does not exist");
        Exam memory exam = exams[_examId];
        require(exam.isActive, "Exam is not active");
        require(_answers.length == exam.questions.length, "Answer count does not match question count");
        require(!students[msg.sender].examsTaken[_examId], "Student has already taken this exam");

        uint score = 0;
        for (uint i = 0; i < _answers.length; i++) {
            if (keccak256(abi.encodePacked(_answers[i])) == exam.correctAnswerHashes[i]) {
                score++;
            }
        }

        uint percentageScore = (score * 100) / exam.questions.length;
        students[msg.sender].score += percentageScore;
        students[msg.sender].hasTakenExam = true;
        students[msg.sender].examIdsTaken.push(_examId);
        students[msg.sender].examsTaken[_examId] = true;

        emit ExamSubmitted(msg.sender, _examId, percentageScore);

        if (percentageScore >= passingScore) {
            emit CertificateIssued(msg.sender, _examId);
        }
    }

    function getExamDetails(uint _examId) public view returns (string memory title, string[] memory questions, uint timeLimit, bool isActive) {
        require(_examId < exams.length, "Exam does not exist");
        Exam memory exam = exams[_examId];
        return (exam.title, exam.questions, exam.timeLimit, exam.isActive);
    }

    function getStudentScore(address _student) public view returns (uint) {
        return students[_student].score;
    }

    function hasStudentTakenExam(address _student, uint _examId) public view returns (bool) {
        return students[_student].examsTaken[_examId];
    }

    function getStudentExamIds(address _student) public view returns (uint[] memory) {
        return students[_student].examIdsTaken;
    }
}
