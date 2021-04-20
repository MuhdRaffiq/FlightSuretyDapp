import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network) {

        this.config = Config[network];
        //this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        //this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        //this.initialize(callback);
        this.owner = null;
        this.flights = [];
        this.airlines = [];
        this.passengers = [];
        this.gasLimit = 50000000;
    }


    async initWeb3 (logCallback) {
        if (window.ethereum) {
            this.web3 = new Web3(window.ethereum);
            try {
                // Request account access
                await window.ethereum.enable();
            } catch (error) {
                // User denied account access...
                console.error("User denied account access")
            }
        }
        // Legacy dapp browsers...
        else if (window.web3) {
            this.web3 = new Web3(window.web3.currentProvider);
        }
        // If no injected web3 instance is detected, fall back to Ganache
        else {
            this.web3 = new Web3(new Web3.providers.WebsocketProvider('http://localhost:8545'));
        }

        const accounts = await this.web3.eth.getAccounts();
        this.account = accounts[0];

        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, this.config.appAddress, this.config.dataAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, this.config.dataAddress);
        this.flightSuretyApp.events.allEvents({fromBlock: 'latest', toBlock: 'latest'}, logCallback);
        this.flightSuretyData.events.allEvents({fromBlock: 'latest', toBlock: 'latest'}, logCallback);
    }

    async registerFlight( flightName, flightDateTime) {
        await this.flightSuretyApp.methods.registerFlight(flightName, flightDateTime).send({from: this.account, gas: this.gasLimit});
    }

    async submitAirline(_address) {
        let self = this;
        try {
           await self.flightSuretyApp.methods.submitRegistration(_address).send({from: self.account, gas: self.gasLimit});
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    async voteAirline(_address) {
        let self = this;
        try {
            let index = await this.flightSuretyApp.methods.getRegIndex(_address).call();
           await self.flightSuretyApp.methods.voteRegistration(index).send({from: self.account, gas: self.gasLimit});
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    async executeAirline(_address) {
        let self = this;
        try {
            let index = await this.flightSuretyApp.methods.getRegIndex(_address).call();
           await self.flightSuretyApp.methods.executeRegistration(index).send({from: self.account, gas: self.gasLimit});
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    async getCurrentFlights() {
        return await this.flightSuretyApp.methods.getCurrentFlights().call();
    }

    async getFlightInformation(key) {
        return await this.flightSuretyApp.methods.getFlightInformation(key).call();
    }

    async fundAirline() {
        await this.flightSuretyApp.methods.payAirline().send({from: this.account, value: 10000000000000000000});
    }

    async setOperationalStatus(enabled) {
        await this.flightSuretyData.methods.setOperatingStatus(enabled).send({from: this.account});
    }

    async setOperationalStatusFalseApp(enabled) {
        await this.flightSuretyApp.methods.setOperatingStatus(enabled).send({from: this.account});
    }

    /*
    async authorizeContract(contractAddress) {
        await this.flightSuretyData.methods.authorizeCaller(contractAddress).send({from: this.account});
    }

    async deauthorizeContract(contractAddress) {
        await this.flightSuretyData.methods.deauthorizeCaller(contractAddress).send({from: this.account});
    }
*/
    async isOperational() {
        return await this.flightSuretyData.methods.isOperational().call();
    }

    async getNumberOfRegisteredAirlines() {
        return await this.flightSuretyAdata.methods.checkNumberAirlines().call();
    }

    async getNumberOfFundedAirlines() {
        return await this.flightSuretyApp.methods.getNumberOfFundedAirlines().call();
    }

    async getContractBalance() {
        const contractBalance =  await this.flightSuretydata.methods.getBalance().call();
        return `${this.web3.utils.fromWei(contractBalance, 'finney')} finney`;
    }

    async getCurrentSubmission() {
        return await this.flightSuretydata.methods.getCurrentSubmitted().call();
    }

    async getSubmittedAirline(numberIndex) {
        return await this.flightSuretyApp.methods.getCurrentAirlineSubmitted(numberIndex).call();
    }


/*
    async getInsuranceBalance() {
        const insuranceBalance =  await this.flightSuretyApp.methods.getInsuranceBalance().call();
        return `${this.web3.utils.fromWei(insuranceBalance, 'finney')} finney`;
    }
    */

    async purchaseInsurance(flightKey) {
        await this.flightSuretyApp.methods.purchaseInsurance(flightKey).send({from: this.account, value: 1000000000000000000});
    }

    async payoutFunds() {
        await this.flightSuretyApp.methods.withdrawalFunds().send({from: this.account});
    }

    async fetchFlightStatus(flightKey) {
        await this.flightSuretyApp.methods.fetchFlightStatus(flightKey).send({from: this.account})
    }

    
    /*
    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
    */
}