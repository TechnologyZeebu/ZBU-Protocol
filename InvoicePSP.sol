// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20MinterPauser.sol";
import "./ReentrancyGuard.sol";

//USD Rate contract interface
interface usdRate {
    function getZeebuToZusdRate() external view returns(uint amount);
}

//Wallet contract interface
interface walletContract {
    function parentAddress() external view returns(address);
}


contract Invoice is IERC20Receiver,ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public owner;
    address public quoteSigner;
    address public adminSigner;
    address[] public withdrawSigner;
    address public usdRateContract;
    address public walletAddress;
    uint public merchantFee;
    uint public customerFee;
    uint public burnRate;
    uint public operationDelay; //in seconds
    uint256 private lastOperationNonce;
    mapping(bytes32 => bool) public isPaid;
    mapping(address => bool) public signerExists;
    mapping(bytes4 => uint256) public functionExecutionTime;
    bool public validateAddressFlag;

    //function signatures
    bytes4 setSignerFun = bytes4(keccak256("setSigner(address,uint256,uint,bytes)"));
    bytes4 setAdminFun = bytes4(keccak256("setAdmin(address,uint256,uint,bytes)"));
    bytes4 updateWalletContractFun = bytes4(keccak256("updateWalletContract(address,uint256,uint,bytes)"));
    bytes4 updateMerchantCreditTokenFun = bytes4(keccak256("updateMerchantCreditToken(address,uint256,uint,bytes)"));
    bytes4 updateMerchantPaymentTokenFun = bytes4(keccak256("updateMerchantPaymentToken(address,uint256,uint,bytes)"));
    bytes4 updateUsdRateContractFun = bytes4(keccak256("updateUsdRateContract(address,uint256,uint,bytes)"));
    bytes4 updateStackerPoolFun = bytes4(keccak256("updateStackerPool(address,uint256,uint,bytes)"));
    bytes4 updateEarningPoolFun = bytes4(keccak256("updateEarningPool(address,uint256,uint,bytes)"));
    bytes4 updateBurningPoolFun = bytes4(keccak256("updateBurningPool(address,uint256,uint,bytes)"));
    bytes4 setMerchantFeeFun = bytes4(keccak256("setMerchantFee(uint256,uint256,uint,bytes)"));
    bytes4 setCustomerFeeFun = bytes4(keccak256("setCustomerFee(uint256,uint256,uint,bytes)"));
    bytes4 setBurnRateFun = bytes4(keccak256("setBurnRate(uint256,uint256,uint,bytes)"));
    bytes4 setMerchantCommissionFun = bytes4(keccak256("setMerchantCommission(address,uint256,bool,uint256,uint,bytes)"));
    bytes4 setCustomerCommissionFun = bytes4(keccak256("setCustomerCommission(address,uint256,bool,uint256,uint,bytes)"));
    bytes4 setStackCommissionFun = bytes4(keccak256("setStackCommission(address,uint256,bool,uint256,uint,bytes)"));
    bytes4 setEarnCommissionFun = bytes4(keccak256("setEarnCommission(address,uint256,bool,uint256,uint,bytes)"));
    bytes4 updateOperationDelayFun = bytes4(keccak256("updateOperationDelay(uint256,uint256,uint256,bytes)"));
    bytes4 setvalidateAddressFlagFun = bytes4(keccak256("setvalidateAddressFlag(bool,uint256,uint,bytes)"));
    bytes4 updateSystemPoolFun = bytes4(keccak256("updateSystemPool(address,bool,uint256,uint,bytes)"));
    
    //merchant payment token config
    address payable public merchantPaymentToken;

    //merchant credit token config
    address payable public merchantCreditToken;

    address public stackerPool;
    address public earningPool;
    address public burningPool;

    address public systemPool;
    bool public systemPoolStatus;

    //merchant reward token config
    address payable public merchantRewardToken;
    uint public merchantRewardPct;
    bool public merchantRewardStatus;

    //customer reward token config
    address payable public customerRewardToken;
    uint public customerRewardPct;
    bool public customerRewardStatus;

    //stack reward token config
    address payable public stackRewardToken;
    uint public stackRewardPct;
    bool public stackRewardStatus;

    //earn reward token config
    address payable public earnToken;
    uint public earnPct;
    bool public earnStatus;

    event ReceivedTokens(address from, address receiver, uint256 amount, address msgSender);
    event PaymentAccepted(bytes32 indexed hash,address customer,address merchant,uint256 tokenValue,uint256 amount,uint256 fee, bytes32 payload);
    event withdrawToAdmin(address msgSender,uint amount,address tokenAdd);

    event merchantCreditTokenUpdate(address msgSender,address creditToken);
    event merchantPaymentTokenUpdate(address msgSender,address creditToken);
    event merchantCommissionUpdate(address msgSender,address tokenAdd,uint pct,bool status);
    event customerCommissionUpdate(address msgSender,address tokenAdd,uint pct,bool status);
    event stackCommissionUpdate(address msgSender,address tokenAdd,uint pct,bool status);
    event earnCommissionUpdate(address msgSender,address tokenAdd,uint pct,bool status);
    event walletContractUpdate(address msgSender,address walletAdd);
    event merchantFeeUpdate(address msgSender,uint pct);
    event customerFeeUpdate(address msgSender,uint pct);
    event burnRateUpdate(address msgSender,uint pct);
    event newSignerIs(address msgSender,address newQuoteSigner);
    event newAdminIs(address msgSender,address newAdmin);
    event usdRateContractUpdate(address msgSender,address rateAddress);
    event stackerPoolUpdate(address msgSender,address stackAddress);
    event earningPoolUpdate(address msgSender,address earnAddress);
    event burningPoolUpdate(address msgSender,address burnAddress);
    event operationDelayUpdate(address msgSender,uint delay);
    event validateAddressFlagUpdate(address msgSender,bool flag);
    event functionExecIs(address msgSender,bytes4 selector,uint256 execTime);

    event MerchantPaid(address merchant,uint uAmount,uint ufee);

    event merchantrewarded(address merchant,uint invoicAmt,uint reward,uint rate,uint rewardPct);
    event customerrewarded(address customer,uint invoicAmt,uint reward,uint rate,uint rewardPct);
    event earnTransfer(address earningPool,uint invoicAmt,uint earnAmount,uint rate,uint rewardPct);
    event stackerrewarded(address stackerPool,uint invoicAmt,uint reward,uint rate,uint rewardPct);
    event burnTransfer(address burningPool,uint invoicAmt,uint burnAmount,uint rate,uint burnRate);

    event systemPoolUpdate(address msgSender,address systemPool);   


    /**
    * To deploy and process payment/reward on payment amount below params :
    * @param _valueSigner the address of payment transaction validate & authenticate with signature
    * @param _adminSigner authorize admin operation by signing
    * @param _usdRateContract the address of the rate contract which consumes to process calculation
    * @param _stackerPool the address of the stacker on that amount transfer on payment
    * @param _earningPool the address of the earning on that amount transfer on payment
    * @param _burningPool the address of the burning on that amount transfer on payment
    * @param _walletAddress the address of the wallet on which the users address during payment validated
    * @param _operationDelay delay to process admin operation execution
    * @param _validateAddressFlag check customer and merchant address belong to walletAddress or not
    * @param _withdrawSigner the address of signers who authenticate withdraw from payment processer
    */
    constructor(address _valueSigner,address _adminSigner,address _usdRateContract, address _stackerPool, address _earningPool, address _burningPool, address _systemPool,address _walletAddress,uint _operationDelay,bool _validateAddressFlag, address[] memory _withdrawSigner) {

      require(_valueSigner != address(0), 'Invalid valueSigner');
      require(_adminSigner != address(0), 'Invalid adminSigner');
      require(msg.sender != _adminSigner,'owner can not be same as adminSigner');
      require(_usdRateContract != address(0), 'Invalid usdRateContract');
      require(_stackerPool != address(0), 'Invalid stackerPool');
      require(_earningPool != address(0), 'Invalid earningPool');
      require(_burningPool != address(0), 'Invalid burningPool');
      require(_systemPool != address(0), 'Invalid systemPool');
      require(_walletAddress != address(0), 'Invalid walletAddress');
      require(_withdrawSigner.length == 2,'Invalid number of withdrawSigner');

      for (uint8 i = 0; i < _withdrawSigner.length; i++) {
        require(_withdrawSigner[i] != address(0), 'Invalid withdrawSigner');
        require(!signerExists[_withdrawSigner[i]],'Signer must uniq');
        signerExists[_withdrawSigner[i]] = true;
      }

      owner = msg.sender;
      quoteSigner = _valueSigner;
      adminSigner = _adminSigner;
      usdRateContract = _usdRateContract;
      stackerPool = _stackerPool;
      earningPool = _earningPool;
      burningPool = _burningPool;
      systemPool = _systemPool;
      withdrawSigner = _withdrawSigner;
      walletAddress = _walletAddress;
      operationDelay = _operationDelay;
      validateAddressFlag = _validateAddressFlag;
      systemPoolStatus = true;
    }

    //modifier to check owner
    modifier isAdmin() {
      require(msg.sender == owner, 'Must be the contract owner');
      _;
    }

    //modifier to check isPaymentToken
    modifier isPaymentToken() {
      require(msg.sender == merchantPaymentToken || msg.sender == merchantCreditToken, 'Hook can be invoke by paymentToken only');
      _;
    }

    /**
    * To validate payment before processing actual payment
    * @param customer the address of who paying payment
    * @param merchant the address of who receive payment
    * @param amount total amount of payment
    * @param fee charge on the total amount of payment
    * @param payload data hash of payment identify
    * @param hash operation hash of input params
    * @param signature input params sign to validate the authenticity
    */
    function isValidPayment(
      address customer,
      address merchant,
      uint amount,
      uint fee,
      bytes32 payload,
      bytes32 hash,
      bytes calldata signature
    ) public view returns(bool valid) {
      bool isValid = !isPaid[payload];
      isValid = isValid;

      bytes32 operationHash = keccak256(abi.encode(getChainId(),address(this),customer,merchant,amount,fee,payload));
      isValid = isValid && operationHash == hash;
      address mySigner = recoverAddressFromSignature(operationHash, signature);
      isValid = isValid && mySigner == quoteSigner;
      return isValid;
    }

    /**
    * Recover payment signer from signature
    */
    function recoverQuoteSigner(
      address customer,
      address merchant,
      uint amount,
      uint fee,
      bytes32 payload,
      bytes calldata signature
    ) public view returns(address myQuoteSigner, bytes32 hash1){
      bytes32 operationHash = keccak256(abi.encode(getChainId(),address(this),customer,merchant,amount,fee,payload));
      address mySigner = recoverAddressFromSignature(operationHash, signature);
      return (mySigner, operationHash);
    }


    /**
    * Gets signer's address using ecrecover
    * @param operationHash see Data Formats
    * @param signature see Data Formats
    * returns address recovered from the signature
    */
    function recoverAddressFromSignature(
    bytes32 operationHash,
    bytes memory signature
    ) private pure returns (address) {
      require(signature.length == 65, 'Invalid signature - wrong length');

      // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
      bytes32 r;
      bytes32 s;
      uint8 v;

      // solhint-disable-next-line
      assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := and(mload(add(signature, 65)), 255)
      }
      if (v < 27) {
        v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
      }

      // protect against signature malleability
      // S value must be in the lower half orader
      // reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/051d340171a93a3d401aaaea46b4b62fa81e5d7c/contracts/cryptography/ECDSA.sol#L53
      require(
        uint256(s) <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
        "ECDSA: invalid signature 's' value"
      );

      // note that this returns 0 if the signature is invalid
      // Since 0x0 can never be a signer, when the recovered signer address
      // is checked against our signer list, that 0x0 will cause an invalid signer failure
      return ecrecover(operationHash, v, r, s);
    }

    /**
    * To validate payment before processing pay process in actual payment,
    *  also validate users of payer and receiver
    */
    function validatePayment(
      address customer,
      address merchant,
      uint amount,
      uint fee,
      bytes32 payload,
      bytes32 hash,
      bytes memory signature
    ) public view returns(bool valid) {
      require(isPaid[payload] == false, 'Already been paid');
      bytes32 operationHash = keccak256(abi.encode(getChainId(),address(this),customer,merchant,amount,fee,payload));
      require(operationHash == hash, 'Hash mismatch');
      address mySigner = recoverAddressFromSignature(operationHash, signature);
      require(mySigner == quoteSigner, 'Signature mismatch for quote');
      require(validateAddress(customer),'Invalid customer');
      require(validateAddress(merchant),'Invalid merchant');
      return true;
    }

    /**
    * process payment and provide rewards based on the configuration available
    * @param customer the address of who paying payment
    * @param merchant the address of who receive payment
    * @param tokenValue is the amount of token paid by the customer
    * @param amount total amount of payment
    * @param fee charge on the total amount of payment
    * @param rate value to validate tokenValue provided by the customer
    * @param payload data hash of payment identify
    * @param hash operation hash of input params
    * @param signature input params sign to validate the authenticity
    */
    function pay(
      address customer,
      address merchant,
      uint tokenValue,
      uint amount,
      uint fee,
      uint rate,
      bytes32 payload,
      bytes32 hash,
      bytes calldata signature
    ) public nonReentrant {
      require(merchantPaymentToken != address(0),'Missing configuration for merchantPaymentToken');
      require(customer != address(0) && merchant != address(0),'Invalid address');
      require(rate >= 0,'Invalid rate');
      require(tokenValue > 0 && validateTokenAmount(tokenValue,amount,rate),'Invalid token amount');
      require(amount > 0,'Invalid amount');
      require(fee >= 0,'Invalid fee');

      IERC20 token = IERC20(merchantPaymentToken);
      require(token.allowance(msg.sender, address(this)) >= tokenValue, 'Must have enough tokens to pay');
      require(validatePayment(customer,merchant,amount, fee, payload, hash, signature), 'Only accept valid payments');
      processCommission(msg.sender,customer,merchant,tokenValue,amount,fee,rate);
      isPaid[payload] = true;
      emit PaymentAccepted(hash,customer,merchant,tokenValue,amount,fee,payload);
    }

    /**
    * calculation process based on payment inputs and perform internal transactions
    */
    function processCommission(address msgSender,address customer,address merchant,uint tAmount,uint uAmount,uint fee,uint rate) private {
        uint zUsdRate = getZeebuToZusdRate();
        require(rate == zUsdRate,"rate miss-match occured");
        uint burnAmount;

        uint originalAmount;
        uint feeInUsd;
        uint paymentInUsd;

        originalAmount = getOriginalAmount(uAmount,fee);
        feeInUsd = getMerchantFee(originalAmount);
        if(burnRate > 0)
        {
          burnAmount = getExtraReward(originalAmount,zUsdRate,5);
        }
        paymentInUsd = originalAmount - feeInUsd;

        //process customer payment
        IERC20 token = IERC20(merchantPaymentToken);
        token.safeTransferFrom(msgSender, address(this), tAmount);

        //stable coin to merchant
        transferToken(merchantCreditToken,merchant,paymentInUsd);
        emit MerchantPaid(merchant,paymentInUsd,feeInUsd);

        //reward to systemPool
        if(systemPoolStatus == true)
        {
            (uint extraRewardAmount) = getUSDReward(originalAmount,1);
            emit merchantrewarded(systemPool,originalAmount,extraRewardAmount,zUsdRate,merchantRewardPct);
            transferToken(merchantRewardToken,systemPool,extraRewardAmount);

            (uint rewardAmount) = getUSDReward(originalAmount,2);
            emit customerrewarded(systemPool,originalAmount,rewardAmount,zUsdRate,customerRewardPct);
            transferToken(customerRewardToken,systemPool,rewardAmount);
        }
        
        //reward to merchant
        if(merchantRewardStatus == true)
        {
            (uint extraRewardAmount) = getExtraReward(originalAmount,zUsdRate,1);
            emit merchantrewarded(merchant,originalAmount,extraRewardAmount,zUsdRate,merchantRewardPct);
            transferToken(merchantRewardToken,merchant,extraRewardAmount);
        }

        //reward to customer
        if(customerRewardStatus == true)
        {
            (uint rewardAmount) = getExtraReward(originalAmount,zUsdRate,2);
            emit customerrewarded(customer,originalAmount,rewardAmount,zUsdRate,customerRewardPct);
            transferToken(customerRewardToken,customer,rewardAmount);
        }

        //transfer to stacker pool
        if(stackRewardStatus == true)
        {
            (uint stackRewardAmount) = getExtraReward(originalAmount,zUsdRate,3);
            emit stackerrewarded(stackerPool,originalAmount,stackRewardAmount,zUsdRate,stackRewardPct);
            transferToken(stackRewardToken,stackerPool,stackRewardAmount);
        }

        //transfer to earning pool
        if(earnStatus == true)
        {
            (uint earnAmount) = getExtraReward(originalAmount,zUsdRate,4);
            emit earnTransfer(earningPool,originalAmount,earnAmount,zUsdRate,earnPct);
            transferToken(earnToken,earningPool,earnAmount);
        }

        //burn fund
        if(burnAmount > 0)
        { 
          emit burnTransfer(burningPool,originalAmount,burnAmount,zUsdRate,burnRate);
          transferToken(merchantPaymentToken,burningPool,burnAmount);
        }
    }

    /**
    * withdraw funds for payment processer which collected
    * @param amount withdraw value by admin
    * @param expiration duration of request to limit with some duration
    * @param operationNonce the nonce value to validate uniq transaction
    * @param tokenContract the address of the token for the case of native it will be a zero address
    * @param sign1 input params sign by withdraw signer to validate the authenticity
    * @param sign2 input params sign by withdraw signer to validate the authenticity
    * @param sign3 input params sign by withdraw signer to validate the authenticity
    */
    function withdraw(uint amount,uint expiration,uint256 operationNonce, address tokenContract,bytes calldata sign1,bytes calldata sign2,bytes calldata sign3) public nonReentrant isAdmin {

      require(isValidWithdrawSigner(expiration,operationNonce,amount,tokenContract,sign1,sign2,sign3),'Invalid signer');
      validateOperationNonce(operationNonce);
      if(tokenContract == address(0)) {
        require(address(this).balance >= amount,'insufficient balance');

        (bool success, ) = payable(owner).call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
      } else {
        IERC20 token = IERC20(tokenContract);
        uint balance = token.balanceOf(address(this));
        require(balance >= amount,'insufficient balance');
        token.safeTransfer(owner, amount);
      }

      emit withdrawToAdmin(msg.sender,amount,tokenContract);
    }

    /**
    * change the address of the payment transaction to validate & authenticate with signature
    */
    function setSigner(address newQuoteSigner,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
      require(newQuoteSigner != address(0),'Invalid newQuoteSigner');
      require(isValidAdminSigner(expiration,operationNonce,setSignerFun,sign));
      require(functionExecutionTime[setSignerFun] != 0 && functionExecutionTime[setSignerFun] <= block.timestamp,'Invalid operation access duration');
      validateOperationNonce(operationNonce);
      quoteSigner = newQuoteSigner;
      functionExecutionTime[setSignerFun] = 0;
      emit newSignerIs(msg.sender,newQuoteSigner);
    }

    /**
    * change the address of the owner of a payment processer
    */
    function setAdmin(address newAdmin,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
      require(newAdmin != address(0),'Invalid newAdmin');
      require(newAdmin != adminSigner,'owner can not be same as adminSigner');
      require(isValidAdminSigner(expiration,operationNonce,setAdminFun,sign));
      require(functionExecutionTime[setAdminFun] !=0 && functionExecutionTime[setAdminFun] <= block.timestamp,'Invalid operation access duration');
      validateOperationNonce(operationNonce);
      owner = newAdmin;
      functionExecutionTime[setAdminFun] = 0;
      emit newAdminIs(msg.sender,newAdmin);
    }

    /**
    * change the address of the wallet
    */
    function updateWalletContract(address walletAdd,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(walletAdd != address(0),'Invalid walletAdd');
        require(isValidAdminSigner(expiration,operationNonce,updateWalletContractFun,sign));
        require(functionExecutionTime[updateWalletContractFun] != 0 && functionExecutionTime[updateWalletContractFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        walletAddress = walletAdd;
        functionExecutionTime[updateWalletContractFun] = 0;
        emit walletContractUpdate(msg.sender,walletAdd);
    }

    /**
    * change the address of the merchant credit token
    */
    function updateMerchantCreditToken(address tokenAdd,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(tokenAdd != address(0),'Invalid tokenAdd');
        require(isValidAdminSigner(expiration,operationNonce,updateMerchantCreditTokenFun,sign));
        require(functionExecutionTime[updateMerchantCreditTokenFun] !=0 && functionExecutionTime[updateMerchantCreditTokenFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        merchantCreditToken = payable(tokenAdd);
        functionExecutionTime[updateMerchantCreditTokenFun] = 0;
        emit merchantCreditTokenUpdate(msg.sender,tokenAdd);
    }

    /**
    * change the address of the merchant payment token
    */
    function updateMerchantPaymentToken(address tokenAdd,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(tokenAdd != address(0),'Invalid tokenAdd');
        require(isValidAdminSigner(expiration,operationNonce,updateMerchantPaymentTokenFun,sign));
        require(functionExecutionTime[updateMerchantPaymentTokenFun] !=0 && functionExecutionTime[updateMerchantPaymentTokenFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        merchantPaymentToken = payable(tokenAdd);
        functionExecutionTime[updateMerchantPaymentTokenFun] = 0;
        emit merchantPaymentTokenUpdate(msg.sender,tokenAdd);
    }

    /**
    * change the address of the merchant rate contract
    */
    function updateUsdRateContract(address rateAddress,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(rateAddress != address(0),'Invalid rateAddress');
        require(isValidAdminSigner(expiration,operationNonce,updateUsdRateContractFun,sign));
        require(functionExecutionTime[updateUsdRateContractFun] !=0 && functionExecutionTime[updateUsdRateContractFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        usdRateContract = payable(rateAddress);
        functionExecutionTime[updateUsdRateContractFun] = 0;
        emit usdRateContractUpdate(msg.sender,rateAddress);
    }

    /**
    * change the address of the stacker
    */
    function updateStackerPool(address stackAddress,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(stackAddress != address(0),'Invalid stackAddress');
        require(isValidAdminSigner(expiration,operationNonce,updateStackerPoolFun,sign));
        require(functionExecutionTime[updateStackerPoolFun] !=0 && functionExecutionTime[updateStackerPoolFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        stackerPool = payable(stackAddress);
        functionExecutionTime[updateStackerPoolFun] = 0;
        emit stackerPoolUpdate(msg.sender,stackAddress);
    }

    /**
    * change the address of the earning
    */
    function updateEarningPool(address earnAddress,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(earnAddress != address(0),'Invalid earnAddress');
        require(isValidAdminSigner(expiration,operationNonce,updateEarningPoolFun,sign));
        require(functionExecutionTime[updateEarningPoolFun] != 0 && functionExecutionTime[updateEarningPoolFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        earningPool = payable(earnAddress);
        functionExecutionTime[updateEarningPoolFun] = 0;
        emit earningPoolUpdate(msg.sender,earnAddress);
    }

    /**
    * change the address of the burning
    */
    function updateBurningPool(address burnAddress,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(burnAddress != address(0),'Invalid burnAddress');
        require(isValidAdminSigner(expiration,operationNonce,updateBurningPoolFun,sign));
        require(functionExecutionTime[updateBurningPoolFun] != 0 && functionExecutionTime[updateBurningPoolFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        burningPool = payable(burnAddress);
        functionExecutionTime[updateBurningPoolFun] = 0;
        emit burningPoolUpdate(msg.sender,burnAddress);
    }

    /**
    * change the address of the systemPool
    */
    function updateSystemPool(address systemPoolAddres,bool sysPoolStatus,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(systemPool != address(0),'Invalid systemPool Address');
        require(isValidAdminSigner(expiration,operationNonce,updateSystemPoolFun,sign));
        require(functionExecutionTime[updateSystemPoolFun] != 0 && functionExecutionTime[updateSystemPoolFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        systemPool = payable(systemPoolAddres);
        systemPoolStatus = sysPoolStatus;
        functionExecutionTime[updateSystemPoolFun] = 0;
        emit systemPoolUpdate(msg.sender,systemPool);
    }
    
    /**
    * change the merchant fee
    */
    function setMerchantFee(uint pct,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(isValidAdminSigner(expiration,operationNonce,setMerchantFeeFun,sign));
        require(functionExecutionTime[setMerchantFeeFun] != 0 && functionExecutionTime[setMerchantFeeFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        merchantFee = pct;
        functionExecutionTime[setMerchantFeeFun] = 0;
        emit merchantFeeUpdate(msg.sender,pct);
    }

    /**
    * change the customer fee
    */
    function setCustomerFee(uint pct,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(isValidAdminSigner(expiration,operationNonce,setCustomerFeeFun,sign));
        require(functionExecutionTime[setCustomerFeeFun] != 0 && functionExecutionTime[setCustomerFeeFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        customerFee = pct;
        functionExecutionTime[setCustomerFeeFun] = 0;
        emit customerFeeUpdate(msg.sender,pct);
    }

    /**
    * change the burn rate
    */
    function setBurnRate(uint pct,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(isValidAdminSigner(expiration,operationNonce,setBurnRateFun,sign));
        require(functionExecutionTime[setBurnRateFun] != 0 && functionExecutionTime[setBurnRateFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        burnRate = pct;
        functionExecutionTime[setBurnRateFun] = 0;
        emit burnRateUpdate(msg.sender,pct);
    }

    /**
    * change the validateAddressFlag
    */
    function setvalidateAddressFlag(bool flag,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(isValidAdminSigner(expiration,operationNonce,setvalidateAddressFlagFun,sign));
        require(functionExecutionTime[setvalidateAddressFlagFun] != 0 && functionExecutionTime[setvalidateAddressFlagFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        validateAddressFlag = flag;
        functionExecutionTime[setvalidateAddressFlagFun] = 0;
        emit validateAddressFlagUpdate(msg.sender,flag);
    }

    /**
    * change the merchant commission parameters
    */
    function setMerchantCommission(address payable tokenAdd,uint pct,bool status,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(tokenAdd != address(0),'Invalid tokenAdd');
        require(isValidAdminSigner(expiration,operationNonce,setMerchantCommissionFun,sign));
        require(functionExecutionTime[setMerchantCommissionFun] != 0 && functionExecutionTime[setMerchantCommissionFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        merchantRewardToken = tokenAdd;
        merchantRewardPct = pct;
        merchantRewardStatus = status;
        functionExecutionTime[setMerchantCommissionFun] = 0;
        emit merchantCommissionUpdate(msg.sender,tokenAdd,pct,status);
    }

    /**
    * change the customer commission parameters
    */
    function setCustomerCommission(address payable tokenAdd,uint pct,bool status,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(tokenAdd != address(0),'Invalid tokenAdd');
        require(isValidAdminSigner(expiration,operationNonce,setCustomerCommissionFun,sign));
        require(functionExecutionTime[setCustomerCommissionFun] != 0 && functionExecutionTime[setCustomerCommissionFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        customerRewardToken = tokenAdd;
        customerRewardPct = pct;
        customerRewardStatus = status;
        functionExecutionTime[setCustomerCommissionFun] = 0;
        emit customerCommissionUpdate(msg.sender,tokenAdd,pct,status);
    }

    /**
    * change the stacker commission parameters
    */
    function setStackCommission(address payable tokenAdd,uint pct,bool status,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(tokenAdd != address(0),'Invalid tokenAdd');
        require(isValidAdminSigner(expiration,operationNonce,setStackCommissionFun,sign));
        require(functionExecutionTime[setStackCommissionFun] != 0 && functionExecutionTime[setStackCommissionFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        stackRewardToken = tokenAdd;
        stackRewardPct = pct;
        stackRewardStatus = status;
        functionExecutionTime[setStackCommissionFun] = 0;
        emit stackCommissionUpdate(msg.sender,tokenAdd,pct,status);
    }

    /**
    * change the earning commission parameters
    */
    function setEarnCommission(address payable tokenAdd,uint pct,bool status,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
        require(pct <= 100000000000000000000,'Invalid percentage');
        require(tokenAdd != address(0),'Invalid tokenAdd');
        require(isValidAdminSigner(expiration,operationNonce,setEarnCommissionFun,sign));
        require(functionExecutionTime[setEarnCommissionFun] !=0 && functionExecutionTime[setEarnCommissionFun] <= block.timestamp,'Invalid operation access duration');
        validateOperationNonce(operationNonce);
        earnToken = tokenAdd;
        earnPct = pct;
        earnStatus = status;
        functionExecutionTime[setEarnCommissionFun] = 0;
        emit earnCommissionUpdate(msg.sender,tokenAdd,pct,status);
    }

    /**
    * update admin operation delay in minutes
    */
    function updateOperationDelay(uint delay,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
      require(isValidAdminSigner(expiration,operationNonce,updateOperationDelayFun,sign));
      require(functionExecutionTime[updateOperationDelayFun] !=0 && functionExecutionTime[updateOperationDelayFun] <= block.timestamp,'Invalid operation access duration');
      validateOperationNonce(operationNonce);
      operationDelay = delay;
      emit operationDelayUpdate(msg.sender,delay);
    }

    /**
    * set execution time for admin operation
    */
    function setFunctionExecTime(bytes4 selector,uint256 operationNonce,uint expiration,bytes calldata sign) public isAdmin {
      require(isValidAdminSigner(expiration,operationNonce,selector,sign));
      require(functionExecutionTime[selector] <= block.timestamp, "function execution is pending");
      validateOperationNonce(operationNonce);
      uint256 execTime = block.timestamp + operationDelay;
      functionExecutionTime[selector] = execTime;
      emit functionExecIs(msg.sender,selector,execTime);
    }

    /**
    * get rate from contract
    */
    function getZeebuToZusdRate() public view returns(uint amount) {
        usdRate rate = usdRate(usdRateContract);
        return rate.getZeebuToZusdRate();
    }

    /**
    * execute token transfer process
    */
    function transferToken(address payable tokenContract,address user,uint amount) internal {
        IERC20 token = IERC20(tokenContract);
        uint balance = token.balanceOf(address(this));
        require(balance >= amount,'insufficient fund for transfer');
        token.safeTransfer(user, amount);
    }

    /**
    * reward calculations
    */
    function getExtraReward(uint amount,uint rate,uint cType) internal view returns(uint){
        uint extraReward;
        uint extraAmt;

        if(cType == 1)
        {
            extraAmt = amount * merchantRewardPct / 100;
        } else if(cType == 2) {
            extraAmt = amount * customerRewardPct / 100;
        } else if(cType == 3) {
            extraAmt = amount * stackRewardPct / 100;
        } else if(cType == 4) {
            extraAmt = amount * earnPct / 100;
        }  else if(cType == 5) {
            extraAmt = amount * burnRate / 100;
        }
        extraReward = extraAmt / rate;
        return(extraReward);
    }

    /**
    * reward calculations in USD
    */
    function getUSDReward(uint amount,uint cType) internal view returns(uint){
        uint extraAmt;
        uint oneToken = 10**18;

        if(cType == 1)
        {
            extraAmt = amount * merchantRewardPct / 100;
        } else if(cType == 2) {
            extraAmt = amount * customerRewardPct / 100;
        }
        return(extraAmt / oneToken);
    }

    /**
    * receive the amount excluding fee and validate the fee provided in a request
    */
    function getOriginalAmount(uint uAmount,uint fee) internal view returns (uint) {
      uint oneToken = 10**18;
      uint feeInUsd;
      uint originalAmount;

      originalAmount = uAmount - fee;
      if(fee > 0 && customerFee > 0)
      {
        feeInUsd = originalAmount * customerFee / 100;
        feeInUsd = feeInUsd / oneToken;
        require(feeInUsd == fee,'fee mismatch');
      }
      return(originalAmount);
    }

    /**
    * get merchant fee
    */
    function getMerchantFee(uint uAmount) internal view returns (uint) {
      uint oneToken = 10**18;
      uint feeInUsd;
      if(merchantFee > 0)
      {
        feeInUsd = uAmount * merchantFee / 100;
        feeInUsd = feeInUsd / oneToken;
      }
      return(feeInUsd);
    }

    /**
    * Hook function of ERC-20 token when transfer process this will invoke
    */
    function onERC20Receive(address from, uint256 amount,address msgSender) external isPaymentToken returns(bool) {
        emit ReceivedTokens(from, address(this), amount,msgSender);
        return true;
    }

    /**
    * validate signer belongs to configure signers
    */
    function validateWithdrawSigner(address signer) public view returns (bool) {
        for (uint i = 0; i < withdrawSigner.length; i++) {
            if (withdrawSigner[i] == signer) {
                return true;
            }
        }
        return false;
    }

    /**
    * validate address belongs to configure wallet
    */
    function validateAddress(address userIs) internal view returns (bool) {
      
      if(validateAddressFlag) {
        walletContract walletIs = walletContract(userIs);
        address userWalletIs =  walletIs.parentAddress();
        if(userWalletIs == walletAddress)
        {
          return true;
        } else {
          return false;
        }        
      } else {
          return true;
      }      
    }

    /**
    * validate token amount based on payment
    */
    function validateTokenAmount(uint tokenValue,uint amount,uint rate) internal pure returns (bool) {
        uint256 oneToken = 10**18;
        uint256 mangeDecimal = 10**16;
        uint256 amountInUsd = rate * tokenValue;

        uint256 amountInUsdFormated = amountInUsd / oneToken;

        amountInUsd = amountInUsd / mangeDecimal;
        amountInUsdFormated = amountInUsdFormated / mangeDecimal;

        amount = amount / mangeDecimal;

        if(amountInUsdFormated < amount){
            amount = amount - 1;
        }
        if(amount == amountInUsdFormated){
            return  true;
        } else {
            return false;
        }
    }

    /**
    * validate withdraw signature
    */
    function isValidWithdrawSigner(uint expiration,uint256 operationNonce,uint amount,address tokenContract,bytes calldata sign1,bytes calldata sign2,bytes calldata sign3) internal view returns (bool) {
      //Verify that the transaction has not expired
      require(expiration >= block.timestamp, 'Transaction expired');
      bytes32 operationHash = keccak256(abi.encode(getChainId(),address(this),amount,expiration,operationNonce,tokenContract));

      address signer1 = recoverAddressFromSignature(operationHash, sign1);
      require(owner == signer1, 'Invalid signer');
      address signer2 = recoverAddressFromSignature(operationHash, sign2);
      address signer3 =recoverAddressFromSignature(operationHash, sign3);
      require(validateWithdrawSigner(signer2) && validateWithdrawSigner(signer3),'Invalid signer');
      require(signer2 != signer3 || signer1 != signer2 || signer1 != signer3, 'Invalid signer');
      return true;
    }

    /**
    * validate admin signature
    */
    function isValidAdminSigner(uint expiration,uint256 operationNonce,bytes4 selector,bytes calldata sign) internal view returns (bool) {
      //Verify that the transaction has not expired
      require(expiration >= block.timestamp, 'Transaction expired');
      bytes32 operationHash = keccak256(abi.encode(getChainId(),address(this),expiration,operationNonce,selector));

      address signerIs = recoverAddressFromSignature(operationHash, sign);
      require(adminSigner == signerIs, 'Invalid signer');
      return true;
    }

    /**
    * @dev Gets the next available operation nonce for signing when using executeAndConfirm
    * @return the operation nonce one higher than the highest currently stored
    */
    function getOperationNonce() public view returns (uint) {
        return lastOperationNonce+1;
    }

    /**
    * @dev Verify that the operation nonce has not been used before and inserts it. Throws if the operation nonce was not accepted.
    * @param operationNonce to insert into array of stored ids
    */
    function validateOperationNonce(uint operationNonce) private {
        require(operationNonce > lastOperationNonce && operationNonce <= (lastOperationNonce+1000), 'Enter Valid operationNonce');
        lastOperationNonce=operationNonce;
    }

    /**
    * Get the network identifier that signers must sign over
    * This provides protection signatures being replayed on other chains
    * This must be a virtual function because chain-specific contracts will need
    *    to override with their own chain ids. It also can't be a field
    *    to allow this contract to be used by proxy with delegatecall, which will
    *    not pick up on state variables
    */
    function getChainId() internal virtual view returns (uint) {
      return block.chainid;
    }
}