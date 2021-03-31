
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

/*

  it(`Has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, {from: config.testAddresses[2]});
      }
      catch(error) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });


  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  
  it(`Can block access to functions using requireIsOperational when operating status is false`, async function () {

    let reverted = false;
    try {
        await config.flightSuretyApp.registerAirline(0x0000);
    } catch (error) {
        reverted = true;
    }
    assert.equal(reverted, true, "Access not blocked for requireIsOperational");

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);

});
 

  it('Airline registered to flightsurety data contract', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    //let result = true;

    // ACT
    try {
        await config.flightSuretyApp.submitRegistration(newAirline, {from: config.firstAirline});
        let regIndex = await config.flightSuretyApp.getRegIndex.call(newAirline, {from: config.firstAirline});
        await config.flightSuretyApp.executeRegistration(regIndex, {from: config.firstAirline});
    }
    catch(e) {
        //result = false;
    }
    let result = await config.flightSuretyData.checkAirlineRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should be able to register into data contract");

  });

  

  it('(airline) is regitrrd but not yet funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.submitRegistration(newAirline, {from: config.firstAirline});
        let regIndex = await config.flightSuretyApp.getRegIndex.call(newAirline);
        await config.flightSuretyApp.executeRegistration(regIndex, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirlineFunded.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  */

  it('(airline) is able to vote', async () => {
    
    // ARRANGE
    let newAirline3 = accounts[3];
    let newAirline2 = accounts[2];
    let regIndex2 = 0;
    //let result = true;

    // ACT
    try {
        await config.flightSuretyApp.submitRegistration(newAirline3, {from: config.firstAirline});
        let regIndex3 = await config.flightSuretyApp.getRegIndex.call(newAirline3);
        await config.flightSuretyApp.executeRegistration(regIndex3, {from: config.firstAirline});

        await config.flightSuretyApp.submitRegistration(newAirline2, {from: config.firstAirline});
        regIndex2 = await config.flightSuretyApp.getRegIndex.call(newAirline2);

        await config.flightSuretyApp.voteRegistration(regIndex2, {from: config.firstAirline});
        //result = await config.flightSuretyApp.getAirlineVote.call(regIndex2, {from: config.firstAirline});
    }
    catch(e) {
        //result = false;
    }
    let result = await config.flightSuretyApp.getAirlineVote.call(regIndex2, {from: config.firstAirline});

    // ASSERT
    assert.equal(result, true, "Airline should be able to vote for registration");

  });


/*
  it('airlines can vote for new registration of airline and ', async () => {

    // ARRANGE
    let newAirline1 = accounts[1];
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];

    // ACT
    try {
        await config.flightSuretyApp.submitRegistration(newAirline1, {from: config.firstAirline});
        let regIndex1 = await config.flightSuretyApp.getRegIndex.call(newAirline1);
        await config.flightSuretyApp.executeRegistration(regIndex1, {from: config.firstAirline});

        await config.flightSuretyApp.submitRegistration(newAirline2, {from: config.firstAirline});
        let regIndex2 = await config.flightSuretyApp.getRegIndex.call(newAirline2);
        await config.flightSuretyApp.executeRegistration(regIndex2, {from: config.firstAirline});

        await config.flightSuretyApp.submitRegistration(newAirline3, {from: config.firstAirline});
        let regIndex3 = await config.flightSuretyApp.getRegIndex.call(newAirline3);
        await config.flightSuretyApp.executeRegistration(regIndex3, {from: config.firstAirline});

        await config.flightSuretyApp.submitRegistration(newAirline4, {from: config.firstAirline});
        let regIndex4 = await config.flightSuretyApp.getRegIndex.call(newAirline4);

        await config.flightSuretyApp.voteRegistration(regIndex1, {from: config.firstAirline});
        await config.flightSuretyApp.voteRegistration(regIndex2, {from: config.firstAirline});
        await config.flightSuretyApp.voteRegistration(regIndex3, {from: config.firstAirline});

        await config.flightSuretyApp.executeRegistration(regIndex4, {from: config.firstAirline});


    }
    catch(e) {

    }

    let result = await config.flightSuretyData.checkAirlineRegistered.call(newAirline4);
     // ASSERT
     assert.equal(result, true, "Airline is not registered");

  });

*/

});
