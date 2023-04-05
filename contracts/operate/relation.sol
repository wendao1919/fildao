//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
interface ICERESNFT {
    function ownerOf(uint256 _nftNo) external view returns (address);

}

interface ISTAKE {
    function stakeBalances(address _address) external view returns (uint256);

}

contract Relation is Ownable,AccessControl {
    using SafeERC20 for IERC20;

    address public ceresnft=0xeA76CA309fA140B5f4d469B1462d55e164062D64;
    address public stakeContract;
    mapping(address => address) public inviter;
    mapping(address => uint256) public inviteDao;
    mapping(address => uint256) public inviteNode;
    
    mapping(uint256 => address[]) public daoInvList;
    mapping(uint256 => address[]) public nodeInvList;

    mapping(uint256 =>mapping(address => uint256)) public bonus;
    mapping(uint256 =>mapping(address => uint256)) public claimedBonus;
    mapping(address =>mapping(uint256 =>mapping(address => uint256))) public recordBonus;

    uint256 public maxDaoNum = 500;

    bytes32 public constant OFFICIAL_ROLE = keccak256("OFFICIAL_ROLE");    // Role  
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");    // Role that can record bonus

    constructor(){
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OFFICIAL_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function bind(uint256 _nftId) public  
    {
        require(inviteNode[msg.sender] == 0,"BIND ERROR: ONCE BIND");
        address inv = ICERESNFT(ceresnft).ownerOf(_nftId);
        require(inv != msg.sender,"BIND ERROR: BIND SELF");
        require(ISTAKE(stakeContract).stakeBalances(msg.sender) ==0,"BIND ERROR: must be no stake");

        if(_nftId > maxDaoNum){
            require(inviteDao[inv] != 0,"BIND ERROR: INVITE not Dao and not BIND");
        }
        
        
        inviter[msg.sender] = inv;
         
        if(_nftId <= maxDaoNum){
            inviteDao[msg.sender] = _nftId;
            inviteNode[msg.sender] = _nftId;
            daoInvList[_nftId].push(msg.sender);
            nodeInvList[_nftId].push(msg.sender);
        }
        else {
            uint256 daoNftId = inviteDao[inv];
            inviteNode[msg.sender] = _nftId;
            inviteDao[msg.sender] = daoNftId;
            daoInvList[daoNftId].push(msg.sender);
            nodeInvList[_nftId].push(msg.sender);

        }

    }


     


    function setNFT(address nft_) external onlyOwner{
        require(nft_ != address(0),"Zero Address");
        ceresnft = nft_;
    }

    function setStakeContract(address _address) external onlyOwner{
        stakeContract = _address;
    }

     

    function getInviteNodeAddress(address addr_) external view returns(address) {
        if(inviteNode[addr_] ==0){
            return address(0);
        }
        return ICERESNFT(ceresnft).ownerOf(inviteNode[addr_]);
    }

    function getInviteDaoAddress(address addr_) external view returns(address) {
        if(inviteNode[addr_] ==0){
            return address(0);
        }
        return ICERESNFT(ceresnft).ownerOf(inviteDao[addr_]);
    }

    function bindBatch(address[] memory _addresses,uint256[] memory _nftIds) external onlyOwner{
        for (uint256 i = 0; i < _addresses.length; i++) { 
            address _address = _addresses[i];
            require(inviteNode[_address] == 0,"BIND ERROR: ONCE BIND");
            uint256 nftNo = _nftIds[i];
            address inv = ICERESNFT(ceresnft).ownerOf(nftNo);
            require(inv !=_address,"BIND ERROR: BIND SELF");

            require(ISTAKE(stakeContract).stakeBalances(_address) ==0,"BIND ERROR: must be no stake");
            
            address inviteAddress = ICERESNFT(ceresnft).ownerOf(nftNo);
            if(nftNo > maxDaoNum){
                require(inviteDao[inviteAddress] != 0,"BIND ERROR: INVITE not Dao and not BIND");
            }
            inviter[_address] = inviteAddress;
            if(nftNo <= maxDaoNum){
                inviteDao[_address] = nftNo;
                inviteNode[_address] = nftNo;
                daoInvList[nftNo].push(_address);
                nodeInvList[nftNo].push(_address);
            }
            else {
                inviteNode[_address] = nftNo;
                inviteDao[_address] = inviteDao[inviteAddress];

                daoInvList[inviteDao[inviteAddress]].push(_address);
                nodeInvList[nftNo].push(_address);

            }
        }   
    }



    function bindBatchUnCheck(address[] memory _addresses,uint256[] memory _nftIds) external onlyOwner{
        for (uint256 i = 0; i < _addresses.length; i++) { 
            address _address = _addresses[i];
            require(ISTAKE(stakeContract).stakeBalances(_address) ==0,"BIND ERROR: must be no stake");
            uint256 nftNo = _nftIds[i];
            address inviteAddress = ICERESNFT(ceresnft).ownerOf(nftNo);
            if(nftNo > maxDaoNum){
                require(inviteDao[inviteAddress] != 0,"BIND ERROR: INVITE not Dao and not BIND");
            }
            inviter[_address] = inviteAddress;
            if(nftNo <= maxDaoNum){
                inviteDao[_address] = nftNo;
                inviteNode[_address] = nftNo;
                daoInvList[nftNo].push(_address);
                nodeInvList[nftNo].push(_address);
            }
            else {
                inviteNode[_address] = nftNo;
                inviteDao[_address] = inviteDao[inviteAddress];

                daoInvList[inviteDao[inviteAddress]].push(_address);
                nodeInvList[nftNo].push(_address);

            }
        }   
    }



    function daoInvListLength(uint256 nftId) public view returns(uint256)
    {
        return daoInvList[nftId].length;
    }


    function nodeInvListLength(uint256 nftId) public view returns(uint256)
    {
        return nodeInvList[nftId].length;
    }


     function getDaoInvList(uint256 nftId)
        public view
        returns(address[] memory _addrsList)
    {
        _addrsList = new address[](daoInvList[nftId].length);
        for(uint256 i=0;i<daoInvList[nftId].length;i++){
            _addrsList[i] = daoInvList[nftId][i];
        }
    }

     function getNodeInvList(uint256 nftId)
        public view
        returns(address[] memory _addrsList)
    {
        _addrsList = new address[](nodeInvList[nftId].length);
        for(uint256 i=0;i<nodeInvList[nftId].length;i++){
            _addrsList[i] = nodeInvList[nftId][i];
        }
    }


    

    function record(uint256 _nftNo, address _token, uint256 _amount,address _account,bool _type) external onlyRole(MANAGER_ROLE){
        recordBonus[_account][_nftNo][_token] += _amount;
        if(_type){
            bonus[_nftNo][_token] += _amount;
        }
    }

    function claimed(uint256 nftNo_, address token_, uint256 amount_) external onlyRole(MANAGER_ROLE){
        claimedBonus[nftNo_][token_] += amount_;
    }

    function claim(uint256 _nftNo,address token_) external {
        require(ICERESNFT(ceresnft).ownerOf(_nftNo) == msg.sender,"Not the owner");
        require(bonus[_nftNo][token_] > 0,"Claim Zero Amount");
        uint256 amount = bonus[_nftNo][token_];
        IERC20(token_).safeTransfer(msg.sender,amount);
        claimedBonus[_nftNo][token_] += amount;
        bonus[_nftNo][token_] = 0;
    }

    function migrate(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    function setMaxDaoNum(uint256 _maxDaoNum) public onlyOwner(){
        maxDaoNum = _maxDaoNum;
    }

}