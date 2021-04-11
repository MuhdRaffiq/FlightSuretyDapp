
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [

        "0xe4B6fBF79cDd959c1f4cb2a9548e3cEb44d8bA1b",
        "0x6E409cC79f71998d8E074741C7ed9C9f3f823A78",
        "0x27323aAd9e20954a6CD5601fA8e76B1de10b24Df",
        "0xCC6E319327343713e5e8e1DE3b1Ab414001d315e",
        "0xE8174e812c439921d474983A89184EdFa57151Ed",
        "0xeDd5C55E79b0c7C3d519238FD822E5E626992314",
        "0xC258a1c9b4F4b7F8720F6DBe82Be1Dd3ACaD1D6d",
        "0x53cc4c60889D563dd82B45012a613E28215D4880",
        "0xc417f5345Ed51cE7f03953a9bb62E470373CBAfC",
        "0x25BE2bFdb94dC5deDbE6bD62aB7407580d961314",

        "0x69e1CB5cFcA8A311586e3406ed0301C06fb839a2",
        "0xF014343BDFFbED8660A9d8721deC985126f189F3",
        "0x0E79EDbD6A727CfeE09A2b1d0A59F7752d5bf7C9",
        "0x9bC1169Ca09555bf2721A5C9eC6D69c8073bfeB4",
        "0xa23eAEf02F9E0338EEcDa8Fdd0A73aDD781b2A86",
        "0x6b85cc8f612d5457d49775439335f83e12b8cfde",
        "0xcbd22ff1ded1423fbc24a7af2148745878800024",
        "0xc257274276a4e539741ca11b590b9447b26a8051",
        "0x2f2899d6d35b1a48a4fbdc93a37a72f264a9fca7"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];
    let airline2 = accounts[2];
    let airline3 = accounts[3];

    let flightSuretyData = await FlightSuretyData.new(firstAirline);
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};