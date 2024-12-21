// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RegionBasedEducationalDAO {

    address public owner;
    uint public proposalCount;
    uint public voterCount;
    uint public treasuryBalance;

    mapping(address => bool) public isMember;
    mapping(address => bool) public hasVoted;
    mapping(uint => Proposal) public proposals;
    mapping(address => uint) public votes;

    struct Proposal {
        uint id;
        address proposer;
        string description;
        uint voteCount;
        bool executed;
        uint fundingAmount;
        bool isActive;
    }

    event ProposalCreated(uint proposalId, string description, uint fundingAmount);
    event Voted(address voter, uint proposalId, bool vote);
    event ProposalExecuted(uint proposalId, bool successful);
    event FundsDeposited(uint amount);
    event MemberRegistered(address member);

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member of the DAO");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    constructor() {
        owner = msg.sender;
        proposalCount = 0;
        treasuryBalance = 0;
    }

    // Register new members (students, teachers, etc.)
    function registerMember(address _member) external onlyOwner {
        require(!isMember[_member], "Member already registered");
        isMember[_member] = true;
        voterCount++;
        emit MemberRegistered(_member);
    }

    // Create a new proposal for funding or curriculum changes
    function createProposal(string memory _description, uint _fundingAmount) external onlyMember {
        require(_fundingAmount <= treasuryBalance, "Insufficient funds in the treasury");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            voteCount: 0,
            executed: false,
            fundingAmount: _fundingAmount,
            isActive: true
        });

        emit ProposalCreated(proposalCount, _description, _fundingAmount);
    }

    // Vote on a proposal (yes/no)
    function voteOnProposal(uint _proposalId, bool _vote) external onlyMember {
        require(!hasVoted[msg.sender], "You have already voted on this proposal");
        require(proposals[_proposalId].isActive, "This proposal is no longer active");

        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.voteCount++;
        }
        hasVoted[msg.sender] = true;
        votes[msg.sender] = _proposalId;

        emit Voted(msg.sender, _proposalId, _vote);
    }

    // Execute a proposal if it has enough votes
    function executeProposal(uint _proposalId) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "Proposal is inactive");
        require(proposal.voteCount > voterCount / 2, "Proposal does not have enough votes");
        require(!proposal.executed, "Proposal has already been executed");

        proposal.executed = true;

        // Deduct the amount from treasury and allocate funds (this can be customized for educational projects)
        treasuryBalance -= proposal.fundingAmount;

        emit ProposalExecuted(_proposalId, true);
    }

    // Deposit funds into the DAO treasury
    function depositFunds() external payable onlyOwner {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.value);
    }

    // Get proposal details
    function getProposalDetails(uint _proposalId) external view returns (string memory description, uint voteCount, bool executed, uint fundingAmount, bool isActive) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.description, proposal.voteCount, proposal.executed, proposal.fundingAmount, proposal.isActive);
    }

    // Get the current treasury balance
    function getTreasuryBalance() external view returns (uint) {
        return treasuryBalance;
    }
}
