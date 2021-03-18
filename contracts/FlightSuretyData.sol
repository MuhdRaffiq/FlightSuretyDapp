pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint256 private airlineFunds = 0 ether;                             // balance for funds from airlines registration
    uint256 private insuranceFunds = 0 ether;                           // balance for insurance
    mapping(address => bool) private authorizedCallers;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */

    struct Airline {
        address airline;
        bool isRegistered;
        uint256 feePaid;
        uint256 regIndex;
        bool isFunded;
        //mapping(address => bool) isVoted;
        uint numVotes;
    }

    mapping(address => Airline) public registeredAirlines;

    //Flight struct
    struct Flight {
        string flightName;
        bool isRegistered;
        uint256 flightDateTime;
        uint256 regIndex;
        address airline;
        uint256 statusCode;
        uint256 updatedTimestamp;
        address[] insuredPassengers;
        mapping(address => uint256) insuredPassengerAddress;
    }

    struct Passenger {
        bool isPaid;
        uint256 paidAmount;
        bytes32 flightId;
        bool eligiblePayout;
        uint256 insuranceAmount;
    }

    uint256 index;
    uint256[] private airlines;                                     //used to know how many have registered to know how many should the multi sig logic is done for app smart contracts        //used for storing registering Airlines data
    mapping(address => bool) private _airlineFunded;                // used for storing if the airlines have paid the fee after registering

    //string mapping flight
    mapping(bytes32 => Flight) private flightsMapping;
    bytes32[] private flightsArray;

    //mapping of passenger
    mapping(address => Passenger) private passengers;

    event AirlineDetails();
    event PaidFee(address airline, uint256 amount, uint256 balance);
    event ContractAuthorized(address _contractId);

    /*
    mapping(address => votedAirline) private votedAirlines;
    mapping (bytes32 => Flight) private flights; */

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public payable {
        contractOwner = msg.sender;
        _registerAirline(msg.sender, true, 0, 0);
        index = 0;
    }


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier isAirlineRegistered()
    {
        require(registeredAirlines[msg.sender].isRegistered == true, "Caller is not contract owner");
        _;
    }
    

    modifier isPassengerPaid()
    {
        require(passengers[msg.sender].isPaid == false, "Caller has paid");
        _;
    }

    modifier isFlightregistered(bytes32 flight)
    {
        require(flightsMapping[flight].isRegistered == true, "flight has not been registere");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function authorizeCaller(address contractAddress) external requireContractOwner{
        require(authorizedCallers[contractAddress] == false, "Address has already be registered");
        authorizedCallers[contractAddress] = true;
        emit ContractAuthorized(contractAddress);
    }
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus (bool mode) external isAirlineRegistered {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address airline, bool isRegistered, uint256 regIndex, uint256 numVotes) external requireIsOperational isAirlineRegistered {
        _registerAirline(airline, isRegistered, regIndex, numVotes);
    }


    /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function _registerAirline(address _airline, bool _isregistered, uint256 _regIndex, uint256 _numVotes) private {
        
        airlines.push(index);
        index = index + 1;
        
        registeredAirlines[_airline].airline = _airline;
        registeredAirlines[_airline].isRegistered = _isregistered;
        registeredAirlines[_airline].feePaid = 0;
        registeredAirlines[_airline].regIndex = _regIndex;
        registeredAirlines[_airline].isFunded = false;
        registeredAirlines[_airline].numVotes = _numVotes;

    }

    /**
    * @dev check if airline is registered
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function checkAirlineRegistered(address checkAirline) external view returns(bool success) {
        return registeredAirlines[checkAirline].isRegistered;
    }

    /**
    * @dev airline is paid by the airline address
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function payFeeAirline(address airline, uint256 fee) external payable requireIsOperational isAirlineRegistered{
        _payFeeAirline(airline, fee);
    }

    /**
    * @dev airline is paid by the airline address
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function _payFeeAirline (address _airline, uint256 _fee) public payable {
        registeredAirlines[_airline].isFunded = true;
        registeredAirlines[_airline].feePaid = _fee;

        //contributions[msg.sender] += msg.value;
        airlineFunds = airlineFunds.add(_fee);


        emit PaidFee(msg.sender, msg.value, airlineFunds);
    }
    
    /**
    * @dev getting balance of funds held in this contract address
    *
    */   
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
    * @dev check if the airline is funded
    *
    *
    */   
    function isAirlineFunded (address _airline) public requireIsOperational returns (bool) {
        return registeredAirlines[_airline].isFunded;
    }

    /**
    * @dev check number of airline registered
    *
    *
    */   
    function checkNumberAirlines () public requireIsOperational returns (uint256) {
        return airlines.length;
    }



    /**
    * @dev Add an flight to the the data
    *
    */   
    function registerFlight(bytes32 key, address airline, bool status, string calldata flightName, uint256 timestamp, uint8 statusCode) external requireIsOperational {
        _registerFlight(key, airline, status, flightName, timestamp, statusCode);
    }

    /**
    * @dev Add an flight to the the data
    *
    */   
    function _registerFlight(bytes32 _key, address _airline, bool _status, string memory _flightName, uint256 _timestamp, uint8 _statusCode) private {
        
        flightsMapping[_key].flightName = _flightName;
        flightsMapping[_key].flightDateTime = _timestamp;
        flightsMapping[_key].airline = _airline;
        flightsMapping[_key].statusCode = _statusCode;
        flightsMapping[_key].isRegistered = _status;
        flightsArray.push(_key);
    }

    /**
    * @dev get the flight registration status
    *
    */   
    function registeredFlight (bytes32 keyFlight) external requireIsOperational returns (bool status) {
        return (flightsMapping[keyFlight].isRegistered);
    }

    
    /**
    * @dev getting the flight data
    *
    */
    /*
    function fetchFlightData (bytes32 key) external view requireIsOperational returns (string memory, uint256, address, uint8) {
        require(flightsMapping[key].airline != address(0));



        return (flightsMapping[key].flightName, flightsMapping[key].flightDateTime, flightsMapping[key].airline, flightsMapping[key].statusCode);
    }
    */

    /**
    * @dev set flight the status 
    *
    */
    function setFlightStatus (bytes32 key, uint8 status) external requireIsOperational {
        require(status != flightsMapping[key].statusCode, "Status code already set");
        flightsMapping[key].statusCode = status;
    }

    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    *
    */   
    function fund (address payable passengerAddress, uint pay, bytes32 flightId) public requireIsOperational isPassengerPaid isFlightregistered(flightId) returns (bool success) {
        
        passengers[passengerAddress].isPaid = true;
        passengers[passengerAddress].paidAmount = pay;
        passengers[passengerAddress].flightId = flightId;
        passengers[passengerAddress].eligiblePayout = false;
        flightsMapping[flightId].insuredPassengers.push(passengerAddress);
        flightsMapping[flightId].insuredPassengerAddress[passengerAddress] = pay;
        passengers[passengerAddress].insuranceAmount = pay.div(2) + pay;

        insuranceFunds = insuranceFunds.add(passengers[passengerAddress].insuranceAmount);

        emit PaidFee(msg.sender, pay, address(this).balance);

        return true;
        
    }

    function passengerInsuranceInfo (address _passengerAddress) public view requireIsOperational returns (bool paid, uint256 amount, bytes32 flightId, bool payoutStatus) {
        paid = passengers[_passengerAddress].isPaid;
        amount = passengers[_passengerAddress].paidAmount;
        flightId = passengers[_passengerAddress].flightId;
        payoutStatus = passengers[_passengerAddress].eligiblePayout;

        return (paid, amount, flightId, payoutStatus);
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function payout (address payable passengerAddress, bytes32 flightkey) external payable requireIsOperational {
        require(passengers[passengerAddress].eligiblePayout, "not eligible for payout");

        Passenger storage passenger = passengers[passengerAddress];

        //passenger.PaidAmount = 0;
        passenger.flightId = "";
        flightsMapping[flightkey].insuredPassengerAddress[passengerAddress] = 0;
        uint256 pay = passengers[passengerAddress].insuranceAmount;
        insuranceFunds = insuranceFunds.sub(pay);

        passengerAddress.transfer(pay);

    }

     /**
     *  @dev processing the flight 
     *
    */
    function processFlightStatus (bytes32 flightkey, bool isLate) external requireIsOperational {
        uint256 passenger;
        //uint256 payAmount;

        if (isLate) {
            for (passenger = 0; passenger < flightsMapping[flightkey].insuredPassengers.length; passenger++) {
                if(passengers[flightsMapping[flightkey].insuredPassengers[passenger]].isPaid) {

                    //payAmount = passengers[flightsMapping[flightkey].insuredPassengers[passenger]].paidAmount;
                    
                    passengers[flightsMapping[flightkey].insuredPassengers[passenger]].eligiblePayout = true;

                    //passengers[flightsMapping[flightkey].insuredPassengers[passenger]].paidAmount= 0;

                    //passengers[flightsMapping[flightkey].insuredPassengers[passenger]].insuranceAmount = payout*1.5;

                    //insuranceFunds = insuranceFunds.sub(insuranceAmount*1.5);
                    flightsMapping[flightkey].insuredPassengers.length = 0;
                }
            }
        } else{
            

            //need to understasd what to do if it is not late
        }
    }


    function getFlightData (bytes32 key) external view requireIsOperational returns(string memory, uint256, address, uint256) {
        return (flightsMapping[key].flightName, flightsMapping[key].flightDateTime, flightsMapping[key].airline, flightsMapping[key].statusCode);
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {

    }
    

}

/********************************************************************************************/
/*                                     MY SMART CONTRACT FUNCTIONS                             */
/********************************************************************************************/


// Modifier
// require registered airlines to perform
/* modifier requireRegisteredAirlines()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

*/
// SMART CONTRACTS
/*
function getAirlinesRegisterionStatus (address airline) internal requireIsOperational return(bool) {
    return Airlines[airline].isRegistered;
    }


function registerFlight (bytes25 key, address airline, bool status, string flightName, uint256 timestamp, uint256 statusCode) pure internal requireIsOperational {
    flights[key].airline = airline;
    flights[key].isRegistered = status;
    flights[key].flightName = flightName;
    flights[key].timestamp = timestamp;
    flights[key].statusCode = statusCode;
    currentFlights.push(key);   
    }

/**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
     
    function registerAirlineData (address airline, bool  ) external pure {
    }




function removeVotedData (bytes32 key) pure internal requireIsOperational {
    delete(VotedAirlines[key]);
    }

    */