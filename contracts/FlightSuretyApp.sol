pragma solidity ^0.5.0;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    //mapping(bytes32 => Flight) private flights;
    
    uint256 min_num_registered = 4;  // min number of registered airlines before requiring multisg from registered airlines

    uint256 min_fee_airlines = 10;   // min fee of airlines to register 

    uint256 insurance_pay = 1;       // max insurance payment from the passenger

    //uint256 numVotesRequired = FlightSuretyData.registeredAirline()/2;

    struct Registration {
        address airline;
        uint256 feePaid;
        bool executed;
        uint256 regIndex;
        mapping(address => bool) isVoted;
        uint numVotes;
    }

    Registration[] public registrations;

    mapping(address => bool) public isVoted;

    /********************************************************************************************/
    /*                                       EVENTS                                */
    /********************************************************************************************/

    event airlineRegistered(address airline, uint256 regIndex);
    event airlinePaid(address airline, uint256 fee);
    event flightRegistered(string flightName, uint256 timestamp, bytes32 id);
    event passengerBuyInsurance(address passenger, bytes32 flightId);
    event submittedRegistration(address airline, uint256 regIndex, bool executed, uint256 numVotes);
    event votedRegistration(address airline, uint256 _regIndex);


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
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
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

    modifier requireRegisteredAirlines()
    {
        require(FlightSuretyData.checkAirlineRegistered(msg.sender), "Caller is not registered Airline");                                       //calling the registered airline from data contract
        _;
    }


    modifier requirePaidAirline()
    {
        require(FlightSuretyData.isAirlineFunded(msg.sender), "Caller has not yet paid the fee");                                       //calling if airline has paid from data contract
        _;
    }

    modifier indexRegExist(uint256 regIndex)
    {
        require(regIndex <= registrations.length, "there is no submission of this number");
        _;
    }

    modifier notExecuted(uint256 regIndex)
    {
        Registration storage registration = registrations[regIndex];
        require(Registration.executed == false, "The airline registration has alredy been executed");
        _;
    }

    modifier notVoted(uint256 regIndex)
    {   
        Registration storage registration = registrations[regIndex];
        require(Registration.isVoted(msg.sender) == false, "You have voted for this registration");
        _;
    }

    modifier flightRegistration(bytes32 keyFlight)
    {
        require(!FlightSuretyData.registeredFlight(keyFlight), 'Flight has been registered');
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor() public {
        contractOwner = msg.sender;
        registrations.push(Registration({
            airline: msg.sender,
            executed: true,
            regIndex: 0,
            numVotes: 0   
        }));

        Registration storage registration = registrations[0];
        //FlightSuretyData.registerAirlineData(registration.airline, true, 0, 0);

    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            pure 
                            returns(bool) 
    {
        return FlightSuretyData.isOperational();  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev Submit Airline registration for other airline to know. Only applicable if more than 4 airlines registered
    *
    */   
    function submitRegistration (address _airline) external requireContractOwner requireRegisteredAirlines requireIsOperational {
        
        uint256 _regIndex = registrations.length;

        registrations.push(Registration({
            airline: _airline,
            executed: false,
            regIndex: _regIndex,
            numVotes: 0   
        }));

        bool statusExecuted = false;
        uint256 numberOfVotes = 0;

        emit submittedRegistration(msg.sender, _regIndex, statusExecuted, numberOfVotes);
    }

    /**
    * @dev Vote Airline registration. Only applicable if more than 4 airlines registered
    *
    */  
    function voteRegistration (uint _regIndex) external requireRegisteredAirlines requireIsOperational indexRegExist(_regIndex) notExecuted(_regIndex) notVoted(_regIndex) {
        

        Registration storage registration = registrations[_regIndex];
        registration.numVotes += 1;
        isVoted[_regIndex][msg.sender] = true;

        emit votedRegistration(msg.sender, _regIndex);
    }


    /**
    * @dev Submit Airline registration for other airline to know. Only applicable if more than 4 airlines registered
    *
    */  
    function executeRegistration(uint _regIndex) public requireRegisteredAirlines requireIsOperational indexRegExist(_regIndex) notExecuted(_regIndex) {
        require(!FlightSuretyData.checkAirlineRegistered(registrations[_regIndex].airline), "Airline is registered and cannot be registered again");
        
        uint256 registeredAirlines = FlightSuretyData.registeredAirlines();
        uint256 numVotesRequired = registeredAirlines/2;

        Registration storage registration = registrations[_regIndex];

        address _airline = registration.airline;

        if(registeredAirlines <= min_num_registered) {
            
            registration.executed = true;
            
            FlightSuretyData.registerAirline(registration.airline, true, _regIndex, 0);
            //return (success, 0);

            emit airlineRegistered(_regIndex, _airline);

        } else if(registeredAirlines > min_num_registered) {
            
            require(Registration.numConfirmations >= numVotesRequired, "cannot execute registration");

            registration.executed = true;

            FlightSuretyData.registerAirline(registration.airline, true, _regIndex, registration.numVotes);


            emit airlineRegistered(_regIndex, _airline);
        } else {
            
        }
    }
  

   /**
    * @dev pay for registering after being registered
    *
    */  
    function payAirline() external payable requireIsOperational requireRegisteredAirlines {
        require(msg.value > min_fee_airlines, "The fee provided is lower than minimum requested");
        
        FlightSuretyData.payFeeAirline(msg.sender, msg.value);
        emit airlinePaid(msg.sender, msg.value);
    }
    

    /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight (string calldata flightName, uint256 timestamp) external requireIsOperational {
        bytes32 key = createFlightkey(msg.sender, flightName, timestamp);
        require(!FlightSuretyData.registeredFlight(key), 'Flight has been registered');
        
        bool status = true;

        FlightSuretyData.registerFlight(key, msg.sender, status, flightName, timestamp, STATUS_CODE_UNKNOWN);

        emit flightRegistered(flightName, timestamp, key);
    }

    /**
    * @dev create an ID by hashing the 3 variables here.
    *
    */  
    function createFlightkey (address airline, string memory flightName, uint256 timestamp) public requireIsOperational returns (bytes32) {   
        return keccak256(abi.encodePacked(airline, flightName, timestamp));
    }



   /**
    * @dev process the flight status and give out the status on wether the flight is late or not
    *
    */  
    function processFlightStatus (address airline, string memory flight, uint256 timestamp, uint8 statusCode) public requireIsOperational {
        bytes32 key = createFlightkey(airline,flight, timestamp);
        (, , , uint8 _status) = FlightSuretyData.getFlightData(key);
        require(_status == 0, "This has been looked into");
        FlightSuretyData.setFlightStatus(key, statusCode);

        if (statusCode == STATUS_CODE_LATE_AIRLINE){
            FlightSuretyData.processFlightStatus(key,true);
        } else {
            FlightSuretyData.processFlightStatus(key,false);
        }

    }


    /**
    * @dev for passengers buy insurance
    *
    */  
    function buyInsurance (bytes32 flightId) internal pure requireIsOperational {
        require(msg.value <= insurance_pay, 'The cost of insurance is 1 ether or below');
        FlightSuretyData.fund(msg.sender, msg.value, flightId);
        
        emit passengerBuyInsurance(msg.sender, flightId);
    }


    /**
    * @dev to allow passenger to take out the funds due to late flight
    *
    */  
    function withdrawalFunds () public payable requireIsOperational {
        //(bool paid, uint256 amount, bytes32 flightId , bool eligiblepayout) = flightSuretyData.passengerInsuranceInfo(msg.sender);
        FlightSuretyData.payout(msg.sender);

    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus (bytes32 flightkey) external {
        uint8 index = getRandomIndex(msg.sender);

        //(string memory flightName, address airline, uint256 timestamp) = flightSuretyData(flightKey); 
    
        // Generate a unique key for storing the request
        (string memory flightName, address airline, uint256 timestamp) = FlightSuretyData.getFlightData(flightkey);

        bytes32 key = keccak256(abi.encodePacked(index, airline, flightName, timestamp));
        
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flightName, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string calldata flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   
