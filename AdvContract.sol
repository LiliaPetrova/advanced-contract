// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Advanced Token and Voting System
 * @dev Комбинира ERC20 токен с система за гласуване
 */
contract AdvContract {
    // Структури
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        uint256 endTime;
        bool executed;
    }
    
    struct Voter {
        uint256 weight;
        bool voted;
        uint256 vote;
    }
    
    // Събития
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 duration);
    event Voted(address indexed voter, uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);
    
    // Константи
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant MIN_PROPOSAL_DURATION = 1 days;
    uint256 public constant VOTE_THRESHOLD = 10 * 10**18; // 10 токена за гласуване
    
    // Променливи на състоянието
    string public name = "Advanced Token";
    string public symbol = "ADV";
    uint8 public decimals = 18;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    Proposal[] public proposals;
    mapping(address => Voter) public voters;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    address public owner;
    uint256 public totalProposals;
    
    // Модификатори
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal doesn't exist");
        _;
    }
    
    modifier activeProposal(uint256 proposalId) {
        require(proposals[proposalId].endTime > block.timestamp, "Proposal expired");
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }
    
    // Конструктор
    constructor() {
        owner = msg.sender;
        _balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }
    
    // ERC20 функции
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    // Voting функции
    function createProposal(string memory description, uint256 duration) public onlyOwner {
        require(duration >= MIN_PROPOSAL_DURATION, "Duration too short");
        
        uint256 proposalId = proposals.length;
        uint256 endTime = block.timestamp + duration;
        
        proposals.push(Proposal({
            id: proposalId,
            description: description,
            voteCount: 0,
            endTime: endTime,
            executed: false
        }));
        
        totalProposals++;
        emit ProposalCreated(proposalId, description, duration);
    }
    
    function vote(uint256 proposalId) public proposalExists(proposalId) activeProposal(proposalId) {
        require(_balances[msg.sender] >= VOTE_THRESHOLD, "Insufficient tokens to vote");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        proposals[proposalId].voteCount += _balances[msg.sender];
        hasVoted[proposalId][msg.sender] = true;
        
        emit Voted(msg.sender, proposalId);
    }
    
    function executeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting still ongoing");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > (TOTAL_SUPPLY * 20) / 100, "Not enough votes"); // 20% от total supply
        
        proposal.executed = true;
        
        // Тук може да се добави логика за изпълнение на proposal
        emit ProposalExecuted(proposalId);
    }
    
    // Вътрешни функции
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    // Допълнителни функции
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        
        _balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }
    
    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (
        uint256 id,
        string memory description,
        uint256 voteCount,
        uint256 endTime,
        bool executed
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.id, p.description, p.voteCount, p.endTime, p.executed);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        owner = newOwner;
    }
}