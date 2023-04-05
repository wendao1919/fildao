// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';


interface IUniswapV2Pair {
     
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
     
}

interface IRelation {
    function inviteNode(address addr) external view returns (uint256);
    function inviteDao(address addr) external view returns (uint256);
    function record(uint256 num, address token, uint256 amount,address addr,bool pid) external;
}

 

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}



contract MINT is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;



    uint256 public starttime; // starttime TBD

    
    address public constant USDTToken = 0x55d398326f99059fF775485246999027B3197955;//BSC USDT
    address public W3B = 0x6EdAD34A4b18A5C2C2abb9e00dFeF4C6d3205a20;
    address public W3C = 0x2fa6ee42BacF983F050210A1ca42f88686327FC9;
    address public uniswapV2W3CPair = 0x5585dda2A7b0d0E4301a4C0e9514dDD9fEd29059;
    address public wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint256 public vaultFee = 500;
    uint256 public lpFee = 300;
    uint256 public burnFee = 50;
    uint256 public opFee = 150;
    uint256 public daosFee = 50;
    uint256 public nodesFee = 50;
    address public relation =         0xe9894034d2fC5C5A2A9A0f7504B2a702D52D7626;
    address public operationAddress =   0x4B922a7A14e27e933CAd0974c089aeb8a932Ea1a;   //yun ying
    address public vaultAddress =       0xd856D338DD558b40EE879D2EA9855cf0549fA6b6;       //guoku
    address public lpAddress =       0x3a5631CC14B298C9ff0B1253004505e27D8759BC;           //shizhi
    address public burnAddress =      0x711b94951fEE2bf0a9B028453E3A3eB322cEDe7d;
    uint256 public dailyLimit = 1000000000 * 10** 18;
    uint256 public dailyTime;
    uint256 public maxPid;
    
    uint256 public constant DURATION = 7 days; //days
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public periodFinish;
    mapping(address => uint256) public rewardRate;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewardPerTokenStored;
    mapping(address => uint256) public vesttime;
    mapping(address => uint256) public totalReward;
    mapping(uint256 => bool) public openPid;



    mapping(uint256 => address) public vcpool;
    mapping(uint256 => address) public bond;
    mapping(uint256 => uint256) public vcAmount;
    mapping(uint256 => uint256) public bondAmount;
    mapping(uint256 => address) public uniswapV2VCPair;
    mapping(uint256 => address) public uniswapV2BondPair;


    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    uint256 public minMintPrice =3*10**14;




    constructor(
        uint256 starttime_
    ) {
        starttime = starttime_;
        dailyTime = starttime_;
    

        
    }

    modifier checkDaily() {
        if(block.timestamp > dailyTime){
         dailyTime = dailyTime + 86400;
         dailyLimit = 10 ** 27; 
        }
        _;
    }

    modifier checkStart() {
        require(block.timestamp > starttime, "NOT START");
        _;
    }

    receive() external payable {
        require(msg.sender == wBNB, "CERES: invalid sender");
    }  


    
    function setRelation(address _relation) public onlyOwner {
        relation = _relation;
    }

    function setOperationAddress(address _address) public onlyOwner  {
        operationAddress = _address;
    }

    function setVaultAddress(address _address) public onlyOwner  {
        vaultAddress = _address;
    }


    function setW3B(address _address) public onlyOwner  {
        W3B = _address;
    }

    function setW3C(address _address) public onlyOwner  {
        W3C = _address;
    }

    function setuniswapV2W3CPair(address _address) public onlyOwner  {
        uniswapV2W3CPair = _address;
    }


     
    function setLpAddress(address _address) public onlyOwner  {
        lpAddress = _address;
    }

    function setBurnAddress(address _address) public onlyOwner  {
        burnAddress = _address;
    }


    function setStartTime(uint256 _startTime) public onlyOwner{
        starttime = _startTime;
    }

     function setMinMintPrice(uint256 _price) public onlyOwner{
        minMintPrice = _price;
    }

    function setDailyLimit(uint256 _dailyLimit) public onlyOwner{
        dailyLimit = _dailyLimit;
    }
  




    function getW3CPrice() public view returns(uint256) {
        address token0 = IUniswapV2Pair(uniswapV2W3CPair).token0();
        //address token1 = IUniswapV2Pair(uniswapV2W3CPair).token1();
        (uint112 token0Amount,uint112 token1Amount,)=IUniswapV2Pair(uniswapV2W3CPair).getReserves();
        uint256 price0 = uint256(token0Amount) * 10**18 / uint256(token1Amount);
        uint256 price1 = uint256(token1Amount) * 10**18 / uint256(token0Amount);

        uint256 price =0;
        if(token0 == USDTToken){
            price = price0;
        }else{
            price= price1;
        }

    
        return price;
    }

    function getTokenPrice(uint256 pid) public view returns(uint256) {
        address token0 = IUniswapV2Pair(uniswapV2VCPair[pid]).token0();
        //address token1 = IUniswapV2Pair(uniswapV2VCPair[pid]).token1();
        (uint112 token0Amount,uint112 token1Amount,)=IUniswapV2Pair(uniswapV2VCPair[pid]).getReserves();
        uint256 price0 = uint256(token0Amount) * 10**18 / uint256(token1Amount);
        uint256 price1 = uint256(token1Amount) * 10**18 / uint256(token0Amount);
        if(token0 == USDTToken){
            return price0;
        }
            return price1;
    }


    function MintVCPool(uint256 amount ,uint256 pid) public checkDaily checkStart returns(bool) {
        require( pid < maxPid,"Error: Not exist" );
        require(openPid[pid],"POOL NOT OPEN");
        require( getW3CPrice() >= minMintPrice,"Error:  W3C price is low" );

     


        IERC20(vcpool[pid]).transferFrom(msg.sender,address(this),amount);
        vcAmount[pid] += amount;
        uint256 w3bAmount = amount * getTokenPrice(pid) / getW3CPrice();
        require(w3bAmount*11/10<= dailyLimit,"EXCEED DAILYLIMIT");
        dailyLimit -= w3bAmount*11/10;
        addReward(w3bAmount);
        uint256 vaultAmount = amount * vaultFee / 1000;
        uint256 lpAmount = amount * lpFee  / 1000;
        uint256 opAmount = amount * opFee / 1000;
        uint256 burnAmount = amount * burnFee  / 1000;
        uint256 daosBAmount = w3bAmount * daosFee / 1000;
        uint256 nodesBAmount = w3bAmount * nodesFee / 1000;
       
        address token = vcpool[pid];
        IERC20(token).transfer(vaultAddress,vaultAmount); 
        IERC20(token).transfer(lpAddress,lpAmount); 
        IERC20(token).transfer(burnAddress,burnAmount); 
        IERC20(token).transfer(operationAddress,opAmount); 
       
        uint256 daosNum = IRelation(relation).inviteDao(msg.sender);
        uint256 nodesNum = IRelation(relation).inviteNode(msg.sender);
        IRelation(relation).record(daosNum,W3B,daosBAmount,msg.sender,true);
        IRelation(relation).record(nodesNum,W3B,nodesBAmount,msg.sender,true);
        return true;
    }


     



    function MintVCPoolBNB(uint256 amount ,uint256 pid) public payable checkDaily checkStart returns(bool) {
        require( pid < maxPid,"Error: Not exist" );
        require(openPid[pid],"POOL NOT OPEN");
        require(vcpool[pid] == wBNB,"POOL NOT OPEN");
        require(amount>0, "Param error");
        require(msg.value == amount, "Pay error");
        require( getW3CPrice() >= minMintPrice,"Error:  W3C price is low" );

        IWBNB(wBNB).deposit{value : amount}();
        vcAmount[pid] += amount;
        uint256 w3bAmount = amount * getTokenPrice(pid) / getW3CPrice();
        require(w3bAmount*11/10<= dailyLimit,"EXCEED DAILYLIMIT");
        dailyLimit -= w3bAmount*11/10;
        addReward(w3bAmount);
         uint256 vaultAmount = amount * vaultFee / 1000;
        uint256 lpAmount = amount * lpFee  / 1000;
        uint256 opAmount = amount * opFee / 1000;
        uint256 burnAmount = amount * burnFee  / 1000;
        uint256 daosBAmount = w3bAmount * daosFee / 1000;
        uint256 nodesBAmount = w3bAmount * nodesFee / 1000;
       
        address token = wBNB;
        IERC20(token).transfer(vaultAddress,vaultAmount); 
        IERC20(token).transfer(lpAddress,lpAmount); 
        IERC20(token).transfer(burnAddress,burnAmount); 
        IERC20(token).transfer(operationAddress,opAmount); 
         
        uint256 daosNum = IRelation(relation).inviteDao(msg.sender);
        uint256 nodesNum = IRelation(relation).inviteNode(msg.sender);
        IRelation(relation).record(daosNum,W3B,daosBAmount,msg.sender,true);
        IRelation(relation).record(nodesNum,W3B,nodesBAmount,msg.sender,true);
        return true;
    }


    function MintBondPool(uint256 amount ,uint256 pid) public checkDaily checkStart {
        require( pid < maxPid,"Error: Not exist" );
        require(openPid[pid],"POOL NOT OPEN");
        require( getW3CPrice() >= minMintPrice,"Error:  W3C price is low" );
        address token = bond[pid];
        IERC20(token).transferFrom(msg.sender,address(this),amount);
        bondAmount[pid] += amount;
        uint256 w3bAmount = amount * 10 ** 18 / getW3CPrice();
        require(w3bAmount*11/10<= dailyLimit,"EXCEED DAILYLIMIT");
        dailyLimit -= w3bAmount*11/10;
        addReward(w3bAmount);
         uint256 vaultAmount = amount * vaultFee / 1000;
        uint256 lpAmount = amount * lpFee  / 1000;
        uint256 opAmount = amount * opFee / 1000;
        uint256 burnAmount = amount * burnFee  / 1000;
        uint256 daosBAmount = w3bAmount * daosFee / 1000;
        uint256 nodesBAmount = w3bAmount * nodesFee / 1000;
        
        IERC20(token).transfer(vaultAddress,vaultAmount); 
        IERC20(token).transfer(lpAddress,lpAmount); 
        IERC20(token).transfer(burnAddress,burnAmount); 
        IERC20(token).transfer(operationAddress,opAmount); 
        
        uint256 daosNum = IRelation(relation).inviteDao(msg.sender);
        uint256 nodesNum = IRelation(relation).inviteNode(msg.sender);
        IRelation(relation).record(daosNum,W3B,daosBAmount,msg.sender,true);
        IRelation(relation).record(nodesNum,W3B,nodesBAmount,msg.sender,true);
    }



      


    function addReward(uint256 reward)
        internal
        updateReward(msg.sender) 
    {
        totalReward[msg.sender] += reward;
        if (block.timestamp > vesttime[msg.sender]) {
            if (block.timestamp >= periodFinish[msg.sender]) {
                rewardRate[msg.sender] = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish[msg.sender].sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate[msg.sender]);
                rewardRate[msg.sender] = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime[msg.sender] = block.timestamp;
            periodFinish[msg.sender] = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate[msg.sender] = reward.div(DURATION);
            lastUpdateTime[msg.sender] = vesttime[msg.sender];
            periodFinish[msg.sender] = vesttime[msg.sender].add(DURATION);
            emit RewardAdded(reward);
        }
    }


    modifier updateReward(address account) {
        rewardPerTokenStored[account] = rewardPerToken(account);
        lastUpdateTime[account] = lastTimeRewardApplicable(account);
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored[account];
        }
        _;
    }

    function lastTimeRewardApplicable(address account) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[account]);
    }


    function rewardPerToken(address account) public view returns (uint256) {

        return
            rewardPerTokenStored[account].add(
                lastTimeRewardApplicable(account)
                    .sub(lastUpdateTime[account])
                    .mul(rewardRate[account])
            );
    }

    function earned(address account) public view returns (uint256) {
        return
                rewardPerToken(account).sub(userRewardPerTokenPaid[account])
                .add(rewards[account]);
    }




    function claim() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(W3B).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

   

    function addVCPid(address token_, address pair_) external onlyOwner{
        uint256 pid = maxPid;
        maxPid++;
        vcpool[pid] = token_;
        uniswapV2VCPair[pid] = pair_;
    }

    function SetOpenPid(uint256 pid_, bool value_) external onlyOwner{
        openPid[pid_] = value_;
    }



    function addBondPid (address token_, address pair_) external onlyOwner{
        uint256 pid = maxPid;
        maxPid++;
        bond[pid] = token_;
        uniswapV2BondPair[pid] = pair_;
     }

    function setBondPid (address token_, address pair_, uint256 pid_) external onlyOwner{
        bond[pid_] = token_;
        uniswapV2VCPair[pid_] = pair_;
     }

    function setVCPid (address token_, address pair_, uint256 pid_) external onlyOwner{
        vcpool[pid_] = token_;
        uniswapV2BondPair[pid_] = pair_;
     }



     


    function withdraw(address _token,uint256 amount) public onlyOwner {
        IERC20(_token).safeTransfer(owner(), amount);
    }


     // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }


    }


