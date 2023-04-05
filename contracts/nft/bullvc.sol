// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBULL {
    function mintToken(uint256 _tokenId, address to) external;
}

interface IRelation {
    function inviteNode(address addr) external view returns (uint256);
    function inviteDao(address addr) external view returns (uint256);
    function record(uint256 num, address token, uint256 amount,address addr,bool pid) external;
}

contract BullVC is AccessControl, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    IBULL bull;
    
    address public paymentToken=0x55d398326f99059fF775485246999027B3197955;                // Contract address of the payment token bsc usdt
    uint public commonUnitPrice;                      // Unit price(Wei)
    uint public minPurchase = 1;                // Minimum NFT to buy per purchase
    uint public maxPurchase = 50;                // Minimum NFT to buy per purchase
    bool public daoPaused = true;                  // dao status
    bool public nodeWhitePaused = true;           //node white Pause status
	bool public nodeCommonPaused = true;           //node common Pause status
     
    bytes32 public constant PRESALE_ROLE = keccak256("PRESALE_ROLE");    // Role that can mint bull item
    bytes32 public constant OFFICIAL_ROLE = keccak256("OFFICIAL_ROLE");    // Role that can mint bull item
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");    // Role that can mint bull item

    uint256 public amountForDao;
    uint256 public amountForNode;
    uint256 public daoStartNumber;
    uint256 public nodeStartNumber;

    address public operationAddress = 0x4B922a7A14e27e933CAd0974c089aeb8a932Ea1a;   //yun ying
    address public vaultAddress = 0xd856D338DD558b40EE879D2EA9855cf0549fA6b6;       //guo ku
    address public relation;



    struct WhiteInfo{
        uint mintNumber;
        uint mintPrice;    
    }

    mapping(address => WhiteInfo) public daoWhiteList;
    mapping(address => WhiteInfo) public nodeWhiteList;


    event UnitPriceSet(uint unitPrice);
   

    constructor(uint256 _amountForDao,uint256 _amountForNode){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OFFICIAL_ROLE, msg.sender);
        _setupRole(PRESALE_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        amountForDao = _amountForDao;
        amountForNode = _amountForNode;
        daoStartNumber=1;
        nodeStartNumber = _amountForDao+1;

    }
    modifier daoInPause() {
        require(daoPaused, "dao in progress");
        _;
    }
    modifier daoInProgress() {
        require(!daoPaused, "daoPaused");
        _;
    }
    modifier nodeWhiteInPause() {
        require(nodeWhitePaused, "node white in progress");
        _;
    }
    modifier nodeWhiteInProgress() {
        require(!nodeWhitePaused, "node white Paused");
        _;
    }


    modifier nodeCommonInPause() {
        require(nodeCommonPaused, "node common in progress");
        _;
    }
    modifier nodeCommonInProgress() {
        require(!nodeCommonPaused, "node common  Paused");
        _;
    }

    function setBull(address _bull) public onlyRole(MANAGER_ROLE)   {
        bull = IBULL(_bull);
    }

    function setCommonUnitPrice(uint _unitPrice) public onlyRole(MANAGER_ROLE)   {
        commonUnitPrice = _unitPrice;
        emit UnitPriceSet(_unitPrice);
    }

    function daoPause() public onlyRole(OFFICIAL_ROLE) daoInProgress() {
        daoPaused = true;
    }

    function daoUnpause() public onlyRole(OFFICIAL_ROLE) daoInPause() {
        daoPaused = false;
    }

    function nodeWhitePause() public onlyRole(OFFICIAL_ROLE) nodeWhiteInProgress() {
        nodeWhitePaused = true;
    }

    function nodeWhiteUnpause() public onlyRole(OFFICIAL_ROLE) nodeWhiteInPause() {
        
        nodeWhitePaused = false;
    }


    function nodeCommonPause() public onlyRole(OFFICIAL_ROLE) nodeCommonInProgress() {
        nodeCommonPaused = true;
    }

    function nodeCommonUnpause() public onlyRole(OFFICIAL_ROLE) nodeCommonInPause() {
        
        nodeCommonPaused = false;
    }

   

    function setDaoWhitelist(address _whitelisted, uint _mintNumber, uint _mintPrice ) public onlyRole(MANAGER_ROLE) {
        daoWhiteList[_whitelisted] = WhiteInfo(_mintNumber,_mintPrice);
    }


    function setNodeWhitelist(address _whitelisted, uint _mintNumber, uint _mintPrice ) public onlyRole(MANAGER_ROLE) {
        nodeWhiteList[_whitelisted] = WhiteInfo(_mintNumber,_mintPrice);
    }



    function setDaoWhitelistBatch(address[] calldata _whitelisted, uint[] calldata _mintNumbers,uint[] calldata _mintPrices) public onlyRole(MANAGER_ROLE)   {
        require(_whitelisted.length == _mintNumbers.length, "_whitelisted and _mintNumbers should have the same length");
        require(_whitelisted.length == _mintPrices.length, "_whitelisted and _mintPrices should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            daoWhiteList[_whitelisted[i]] = WhiteInfo(_mintNumbers[i],_mintPrices[i]);
        }
    }


    function setNodeWhitelistBatch(address[] calldata _whitelisted, uint[] calldata _mintNumbers,uint[] calldata _mintPrices) public onlyRole(MANAGER_ROLE)   {
        require(_whitelisted.length == _mintNumbers.length, "_whitelisted and _mintNumbers should have the same length");
        require(_whitelisted.length == _mintPrices.length, "_whitelisted and _mintPrices should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            nodeWhiteList[_whitelisted[i]] = WhiteInfo(_mintNumbers[i],_mintPrices[i]);
        }
    }

     



    function setPaymentToken(address _paymentToken) public onlyRole(MANAGER_ROLE)   {
        paymentToken = _paymentToken;
    }

   

    function setRelation(address _relation) public onlyRole(MANAGER_ROLE)  {
        relation = _relation;
    }

    function setOperationAddress(address _address) public onlyRole(MANAGER_ROLE)  {
        operationAddress = _address;
    }

    function setVaultAddress(address _address) public onlyRole(MANAGER_ROLE)  {
        vaultAddress = _address;
    }


  

    function setAmountForDao(uint256 _amountForDao) public onlyRole(MANAGER_ROLE)  {
        amountForDao = _amountForDao;
    }

    function setAmountForNode(uint256 _amountForNode) public onlyRole(MANAGER_ROLE)  {
        amountForNode = _amountForNode;
    }

    function setDaoStartNumber(uint256 _daoStartNumber) public onlyRole(MANAGER_ROLE)  {
        daoStartNumber = _daoStartNumber;
    }

    function setNodeStartNumber(uint256 _nodeStartNumber) public onlyRole(MANAGER_ROLE)  {
        nodeStartNumber = _nodeStartNumber;
    }

     






    function mintWhiteDao(uint256 quantity) public  daoInProgress nonReentrant {
        require( daoStartNumber + quantity <= amountForDao+1, "not enough remaining reserved for auction to support desired mint amount");

        require(quantity > 0,"can not mint 0 nft");

        WhiteInfo memory whiteInfo = daoWhiteList[msg.sender];
        require(quantity <= whiteInfo.mintNumber,"can not mint  nft number than allow");

        for(uint i=0;i<quantity;i++){
            bull.mintToken(daoStartNumber, msg.sender);
            daoStartNumber++;
        }

       
        
        uint256 amount =  quantity * whiteInfo.mintPrice;
        if(amount > 0){
            // require(msg.value == amount, "Pay error");
            IERC20(paymentToken).transferFrom(msg.sender,address(this),amount);   
            IERC20(paymentToken).transfer(vaultAddress,amount * 50/100); 
            IERC20(paymentToken).transfer(operationAddress,amount * 30/100);
            IERC20(paymentToken).transfer(relation,amount * 20/100);   
            uint256 daoNftId = IRelation(relation).inviteDao(msg.sender);
            uint256 nodeNftId = IRelation(relation).inviteNode(msg.sender);
            IRelation(relation).record(daoNftId,paymentToken,amount * 10/100,msg.sender,true);
            IRelation(relation).record(nodeNftId,paymentToken,amount * 10/100,msg.sender,true);
        }

        whiteInfo.mintNumber -= quantity;
        daoWhiteList[msg.sender] = whiteInfo;
        
        
    }


    function mintWhiteNode(uint256 quantity) public nodeWhiteInProgress nonReentrant  {
        uint256 daoNftId = IRelation(relation).inviteDao(msg.sender);
        require(daoNftId > 0 ,"not invited");

        require( nodeStartNumber + quantity <= amountForDao+amountForNode+1, "not enough remaining reserved for auction to support desired mint amount");
        require(quantity > 0,"can not mint 0 nft");
        WhiteInfo memory whiteInfo = nodeWhiteList[msg.sender];
        require(quantity <= whiteInfo.mintNumber,"can not mint  nft number than allow");

        for(uint i=0;i<quantity;i++){
            bull.mintToken(nodeStartNumber, msg.sender);
            nodeStartNumber++;
        }
        
        uint256 amount =  quantity * whiteInfo.mintPrice;
        if(amount > 0){
            // require(msg.value == amount, "Pay error");
            IERC20(paymentToken).transferFrom(msg.sender,address(this),amount);   
            IERC20(paymentToken).transfer(vaultAddress,amount * 50/100); 
            IERC20(paymentToken).transfer(operationAddress,amount * 30/100);
            IERC20(paymentToken).transfer(relation,amount * 20/100);   
 
            uint256 nodeNftId = IRelation(relation).inviteNode(msg.sender);
            IRelation(relation).record(daoNftId,paymentToken,amount * 10/100,msg.sender,true);
            IRelation(relation).record(nodeNftId,paymentToken,amount * 10/100,msg.sender,true);
        }

        whiteInfo.mintNumber -= quantity;
        nodeWhiteList[msg.sender] = whiteInfo;
          
    }


     function mintCommonNode(uint256 quantity) public nodeCommonInProgress  nonReentrant {

        uint256 daoNftId = IRelation(relation).inviteDao(msg.sender);
        require(daoNftId > 0 ,"not invited");

        require( nodeStartNumber + quantity <= amountForDao+amountForNode+1, "not enough remaining reserved for auction to support desired mint amount");
        require(quantity > 0,"can not mint 0 nft");
        require(quantity <= maxPurchase,"can not mint  nft number than allow");

        for(uint i=0;i<quantity;i++){
            bull.mintToken(nodeStartNumber, msg.sender);
            nodeStartNumber++;
        }
        
        uint256 amount =  quantity * commonUnitPrice;
        if(amount > 0){
            // require(msg.value == amount, "Pay error");
            IERC20(paymentToken).transferFrom(msg.sender,address(this),amount);   
            IERC20(paymentToken).transfer(vaultAddress,amount * 50/100); 
            IERC20(paymentToken).transfer(operationAddress,amount * 30/100);
            IERC20(paymentToken).transfer(relation,amount * 20/100);   
            
            uint256 nodeNftId = IRelation(relation).inviteNode(msg.sender);
            IRelation(relation).record(daoNftId,paymentToken,amount * 10/100,msg.sender,true);
            IRelation(relation).record(nodeNftId,paymentToken,amount * 10/100,msg.sender,true);
        }
          
    }




    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }


    function getWhiteNumber() public view returns(uint256) {

         WhiteInfo memory whiteInfo = daoWhiteList[msg.sender];
         return whiteInfo.mintNumber;
        
    }

    
}