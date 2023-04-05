// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ALEONFT {
    function mintToken(uint256 _tokenId, address to) external;
    function lockedAmount(address _address) external view returns(uint256);
}

 

contract ALEOVC is AccessControl, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    ALEONFT aleoNft;
    
    address public paymentToken=0x26Ab47c4Ec4629413593950A56F2b70328A439eb;                // Contract address of the payment token ethereum  usdt
    uint public p1Price=200*(10**18);                      // Unit protectorPrice1
    uint public p2Price=350*(10**18);                      // Unit protectorPrice2
    uint public minPurchase = 1;                // Minimum NFT to buy per purchase
    uint public maxPurchase = 100;                // Minimum NFT to buy per purchase
    bool public p1Paused = false;                  // p1 status
    bool public p2Paused = false;           //p2 status

    bool public p1WhitePaused = false;                  // p1 white mint status
    bool public p2WhitePaused = false;           //p2 white mint status
 
     
    bytes32 public constant PRESALE_ROLE = keccak256("PRESALE_ROLE");    // Role that can mint bull item
    bytes32 public constant OFFICIAL_ROLE = keccak256("OFFICIAL_ROLE");    // Role that can mint bull item
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");    // Role that can mint bull item

    uint256 public amountForP1;
    uint256 public amountForP2;
    uint256 public p1StartNumber;
    uint256 public p2StartNumber;

    uint256 public starttime; // starttime mint
    uint256 public finishtime; // endtime mint


    uint256 public leftForP1=500;
    uint256 public leftForP2=500;



    uint256 public whiteDiscount =950;

    uint256 public ambassadorAmount =1;
    uint256 public ambassadorFeedRatio =100;

    uint256 public evangelistAmount =10;
    uint256 public evangelistFeedRatio =200;


    address public vaultAddress = 0x566EE50509e6C09678bB8f6B805FC081300C612B;       //guo ku

    mapping(address => bool) public isWhiteAddress;

    mapping(address => address) public inviteRelation;


     struct WhiteInfo{
        uint mintNumber;
        uint mintPrice;    
    }

    mapping(address => WhiteInfo) public p1WhiteList;
    mapping(address => WhiteInfo) public p2WhiteList;


 

    event P1PriceSet(uint unitPrice);
    event P2PriceSet(uint unitPrice);
   

    constructor(uint256 _amountForP1,uint256 _amountForP2){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OFFICIAL_ROLE, msg.sender);
        _setupRole(PRESALE_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        amountForP1 = _amountForP1;
        amountForP2= _amountForP2;
       
        p1StartNumber=1;
        p2StartNumber = _amountForP1+1;

    }
   
    modifier p1InProgress() {
        require(!p1Paused, "p1 Paused");
        _;
    }
    
    modifier p2InProgress() {
        require(!p2Paused, "p2 Paused");
        _;
    }

    modifier p1WhiteInProgress() {
        require(!p1WhitePaused, "p1 white Paused");
        _;
    }
    
    modifier p2WhiteInProgress() {
        require(!p2WhitePaused, "p2 white Paused");
        _;
    }


    modifier checkStart() {
        require(block.timestamp > starttime, "not start");
        _;
    }

    modifier checkFinish() {
        require(block.timestamp <= finishtime, "mint finish");
        _;
    }


   

    function setNft(address _nft) public onlyRole(MANAGER_ROLE)   {
        aleoNft =     ALEONFT(_nft);
    }

    function setP1Price(uint _unitPrice) public onlyRole(MANAGER_ROLE)   {
        p1Price = _unitPrice;
        emit P1PriceSet(_unitPrice);
    }


    function setP2Price(uint _unitPrice) public onlyRole(MANAGER_ROLE)   {
        p2Price = _unitPrice;
        emit P2PriceSet(_unitPrice);
    }


   


    function setStarttime(uint256 _value) public onlyRole(MANAGER_ROLE)  {
        starttime = _value;
    }

    function setFinishtime(uint256 _value) public onlyRole(MANAGER_ROLE)  {
        finishtime = _value;
    }

    function setLeftForP1(uint256 _value) public onlyRole(MANAGER_ROLE)  {
        leftForP1 = _value;
    }

    function setLeftForP2(uint256 _value) public onlyRole(MANAGER_ROLE)  {
        leftForP2 = _value;
    }








    function setP1Paused(bool status) public onlyRole(MANAGER_ROLE){
        p1Paused =status; 
    }

    function setP2Paused(bool status) public onlyRole(MANAGER_ROLE){
        p2Paused =status; 
    }

    function setP1WhitePaused(bool status) public onlyRole(MANAGER_ROLE){
        p1WhitePaused =status; 
    }

    function setP2WhitePaused(bool status) public onlyRole(MANAGER_ROLE){
        p2WhitePaused =status; 
    }
  

    




    function setWhitelist(address _whitelisted  ) public onlyRole(MANAGER_ROLE) {
        isWhiteAddress[_whitelisted] = true;
    }

    function removeWhitelist(address _whitelisted  ) public onlyRole(MANAGER_ROLE) {
        isWhiteAddress[_whitelisted] = false;
    }


    function setWhitelistBatch(address[] calldata _whitelisted  ) public onlyRole(MANAGER_ROLE) {

        for (uint i = 0; i < _whitelisted.length; i++) {
            isWhiteAddress[_whitelisted[i]] = true;
        }
    }


    function removeWhitelistBatch(address[] calldata _whitelisted  ) public onlyRole(MANAGER_ROLE) {

        for (uint i = 0; i < _whitelisted.length; i++) {
            isWhiteAddress[_whitelisted[i]] = false;
        }
    }


    function setPaymentToken(address _paymentToken) public onlyRole(MANAGER_ROLE)   {
        paymentToken = _paymentToken;
    }

    function setVaultAddress(address _address) public onlyRole(MANAGER_ROLE)  {
        vaultAddress = _address;
    }


    function setWhiteDiscount(uint256 _whiteDiscount) public onlyRole(MANAGER_ROLE)  {
        whiteDiscount = _whiteDiscount;
    }

 


    function setAmbassadorAmount(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        ambassadorAmount = amount;
    }

    function setAmbassadorFeedRatio(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        ambassadorFeedRatio = amount;
    }

    function setEvangelistAmount(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        evangelistAmount = amount;
    }

    function setEvangelistFeedRatio(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        evangelistFeedRatio = amount;
    }


     

    function setAmountForP1(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        amountForP1 = amount;
    }

    function setAmountForP2(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        amountForP2 = amount;
    }

    function setP1StartNumber(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        p1StartNumber = amount;
    }

    function setP2StartNumber(uint256 amount) public onlyRole(MANAGER_ROLE)  {
        p2StartNumber = amount;
    }



    function bind(address inviteAddress) public{

        require(inviteRelation[msg.sender] == address(0) ,"can not bind again");
        require(inviteAddress != msg.sender ,"can not bind self");
        inviteRelation[msg.sender] = inviteAddress;
        
    }

    function mintP1(uint256 quantity ,address inviteAddress ) public  checkStart checkFinish  p1InProgress nonReentrant {

        if((inviteRelation[msg.sender] == address(0)) && (inviteAddress != msg.sender) ){
            inviteRelation[msg.sender] = inviteAddress;
        }
        _mintP1(quantity);

    }

    function mintP2(uint256 quantity,address inviteAddress) public  checkStart checkFinish p2InProgress nonReentrant {

       
        if((inviteRelation[msg.sender] == address(0)) && (inviteAddress != msg.sender) ){
            inviteRelation[msg.sender] = inviteAddress;
        }
        _mintP2(quantity);
    
    }

    function mintP1(uint256 quantity   ) public  checkStart checkFinish p1InProgress nonReentrant {
        _mintP1(quantity);

    }

    function mintP2(uint256 quantity ) public checkStart checkFinish p2InProgress nonReentrant {
    
        _mintP2(quantity);
    
    }





    function _mintP1(uint256 quantity) private      {
        require( p1StartNumber + quantity <= amountForP1+1, "not enough remaining reserved for auction to support desired mint amount");

        require(quantity > 0,"can not mint 0 nft");
        require(quantity <= maxPurchase,"can not mint  nft number than allow");
        require(quantity <= leftForP1,"not enough nft1 left");
        leftForP1 =leftForP1-quantity;

        uint256 amount =  quantity * p1Price;
        if(isWhiteAddress[msg.sender]){
            amount = amount*whiteDiscount/1000;
        }
        if(amount > 0){
            _dispatchPayCoin(amount);
        }

        for(uint i=0;i<quantity;i++){
            aleoNft.mintToken(p1StartNumber, msg.sender);
            p1StartNumber++;
        }    
    }



     function _mintP2(uint256 quantity) private     {
        require( p2StartNumber + quantity <= amountForP1+amountForP2+1, "not enough remaining reserved for auction to support desired mint amount");

        require(quantity > 0,"can not mint 0 nft");
        require(quantity <= maxPurchase,"can not mint  nft number than allow");


        require(quantity <= leftForP2,"not enough nft2 left");
        leftForP2 =leftForP2-quantity;

       
        uint256 amount =  quantity * p2Price;
        if(isWhiteAddress[msg.sender]){
            amount = amount*whiteDiscount/1000;
        }
        if(amount > 0){
            _dispatchPayCoin(amount);
        }

        for(uint i=0;i<quantity;i++){
            aleoNft.mintToken(p2StartNumber, msg.sender);
            p2StartNumber++;
        }    
    }

    function _dispatchPayCoin(uint256 amount) private{


        // require(msg.value == amount, "Pay error");

            address inviteAddress = inviteRelation[msg.sender];

            uint256 feedAmount;

            if(inviteAddress != address(0)){

                uint256 lockedAmount =  aleoNft.lockedAmount(inviteAddress);
                uint256 feedRatio;
                if(lockedAmount >= evangelistAmount){
                    feedRatio = evangelistFeedRatio;
                }else if(lockedAmount >= ambassadorAmount){
                    feedRatio = ambassadorFeedRatio;
                }
                feedAmount = amount*feedRatio/1000;

            }

            uint256 vaultAmount = amount - feedAmount;

            IERC20(paymentToken).transferFrom(msg.sender,address(this),amount);   
            IERC20(paymentToken).transfer(vaultAddress,vaultAmount); 

            if(inviteAddress != address(0)  && feedAmount > 0){
                IERC20(paymentToken).transfer(inviteAddress,feedAmount);   
            }

    }


    function setP1Whitelist(address _whitelisted, uint _mintNumber, uint _mintPrice ) public onlyRole(MANAGER_ROLE) {
        p1WhiteList[_whitelisted] = WhiteInfo(_mintNumber,_mintPrice);
    }


    function setP2Whitelist(address _whitelisted, uint _mintNumber, uint _mintPrice ) public onlyRole(MANAGER_ROLE) {
        p2WhiteList[_whitelisted] = WhiteInfo(_mintNumber,_mintPrice);
    }



    function setP1WhitelistBatch(address[] calldata _whitelisted, uint[] calldata _mintNumbers,uint[] calldata _mintPrices) public onlyRole(MANAGER_ROLE)   {
        require(_whitelisted.length == _mintNumbers.length, "_whitelisted and _mintNumbers should have the same length");
        require(_whitelisted.length == _mintPrices.length, "_whitelisted and _mintPrices should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            p1WhiteList[_whitelisted[i]] = WhiteInfo(_mintNumbers[i],_mintPrices[i]);
        }
    }


    function setP2WhitelistBatch(address[] calldata _whitelisted, uint[] calldata _mintNumbers,uint[] calldata _mintPrices) public onlyRole(MANAGER_ROLE)   {
        require(_whitelisted.length == _mintNumbers.length, "_whitelisted and _mintNumbers should have the same length");
        require(_whitelisted.length == _mintPrices.length, "_whitelisted and _mintPrices should have the same length");
        for (uint i = 0; i < _whitelisted.length; i++) {
            p2WhiteList[_whitelisted[i]] = WhiteInfo(_mintNumbers[i],_mintPrices[i]);
        }
    }



    function mintP1White(uint256 quantity ,address inviteAddress ) public  p1WhiteInProgress nonReentrant {

        if((inviteRelation[msg.sender] == address(0)) && (inviteAddress != msg.sender) ){
            inviteRelation[msg.sender] = inviteAddress;
        }
        _mintP1White(quantity);

    }

    function mintP2White(uint256 quantity,address inviteAddress) public  p2WhiteInProgress nonReentrant {

        if((inviteRelation[msg.sender] == address(0)) && (inviteAddress != msg.sender) ){
            inviteRelation[msg.sender] = inviteAddress;
        }
        
        _mintP2White(quantity);
    
    }

    function mintP1White(uint256 quantity   ) public  p1WhiteInProgress nonReentrant {
        _mintP1White(quantity);

    }

    function mintP2White(uint256 quantity ) public  p2WhiteInProgress nonReentrant {
    
        _mintP2White(quantity);
    
    }





    function _mintP1White(uint256 quantity) private {
        require( p1StartNumber + quantity <= amountForP1+1, "not enough remaining reserved for auction to support desired mint amount");

        require(quantity > 0,"can not mint 0 nft");

        WhiteInfo memory whiteInfo = p1WhiteList[msg.sender];
        require(quantity <= whiteInfo.mintNumber,"can not mint  nft number than allow"); 
        uint256 amount =  quantity * whiteInfo.mintPrice;
        if(amount > 0){
            _dispatchPayCoin(amount);
        }

        whiteInfo.mintNumber -= quantity;
        p1WhiteList[msg.sender] = whiteInfo;

        for(uint i=0;i<quantity;i++){
            aleoNft.mintToken(p1StartNumber, msg.sender);
            p1StartNumber++;
        }
        
        
    }


    function _mintP2White(uint256 quantity) private {
        require( p2StartNumber + quantity <= amountForP1+amountForP2+1, "not enough remaining reserved for auction to support desired mint amount");

        require(quantity > 0,"can not mint 0 nft");

        WhiteInfo memory whiteInfo = p2WhiteList[msg.sender];
        require(quantity <= whiteInfo.mintNumber,"can not mint  nft number than allow"); 
        uint256 amount =  quantity * whiteInfo.mintPrice;
        if(amount > 0){
            _dispatchPayCoin(amount);
        }

        whiteInfo.mintNumber -= quantity;
        p2WhiteList[msg.sender] = whiteInfo;

        for(uint i=0;i<quantity;i++){
            aleoNft.mintToken(p2StartNumber, msg.sender);
            p2StartNumber++;
        }
        
        
    }


    


    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }


     

    
}