
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
//import BigNum from "bignumber";

const contract = new Contract('localhost');
let blockNumbersSeen = [];

(async() => {
    await contract.initWeb3(eventHandler);
    await getOperationalStatus();


    DOM.elid('update-status').addEventListener('click', refreshStatus);
    DOM.elid('set-contractApp-false').addEventListener('click', setOperationalStatusFalseApp);
    DOM.elid('set-statusData-false').addEventListener('click', setOperationalStatusFalse);
    DOM.elid('set-statusData-true').addEventListener('click', setOperationalStatusTrue);
    //DOM.elid('register-contract-address').addEventListener('click', authorizeContract);
    //DOM.elid('unregister-contract-address').addEventListener('click', deauthorizeContract);
    DOM.elid('submit-airline').addEventListener('click', submitAirline);
    DOM.elid('vote-airline').addEventListener('click', voteAirline);
    DOM.elid('execute-airline').addEventListener('click', executeAirline);
    DOM.elid('fund-airline').addEventListener('click', fundAirline);
    DOM.elid('register-flight').addEventListener('click', registerFlight);
    DOM.elid('purchase-flight-insurance').addEventListener('click', purchaseInsurance);
    DOM.elid('send-to-oracles').addEventListener('click', sendToOracles);
    DOM.elid('collect-funds').addEventListener('click', collectFunds);


    /*
    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })
    
    });
    */

})();

const collectFunds = async () => {
    await contract.payoutFunds();
}

const sendToOracles = async () => {
    const flightSelect = DOM.elid('select-flight');
    await contract.getFlightStatus(flightSelect.value);
    await refreshStatus();
}

const purchaseInsurance = async () => {
    const flightSelect = DOM.elid('select-flight');
    //const insudranceFunds = DOM.elid('purchase-insurance');
    await contract.purchaseInsurance(flightSelect.value);
    await refreshStatus();
}

const registerFlight = async () => {
    const registerFlightName = DOM.elid('register-flight-name');
    const registerFlightDate = DOM.elid('register-flight-date');
    const registerFlightTime = DOM.elid('register-flight-time');
    const stringDate = `${registerFlightDate.value}T${registerFlightTime.value}Z`;
    const flightDateTime = new Date(stringDate).getTime();
    await contract.registerFlight(registerFlightName.value, flightDateTime);
    await refreshStatus();
};

const fundAirline = async () => {
    await contract.fundAirline();
    await refreshStatus();
};

const submitAirline = async () => {
    const element = DOM.elid('submit-airline-address');
    await contract.submitAirline(element.value);
    await refreshStatus();
    element.value = '';
};

const voteAirline = async () => {
    const element = DOM.elid('voting-airline-address');
    await contract.voteAirline(element.value);
    await refreshStatus();
    element.value = '';
};

const executeAirline = async () => {
    const element = DOM.elid('executing-airline-address');
    await contract.executeAirline(element.value);
    await refreshStatus();
    element.value = '';
};

/*
const authorizeContract = async () => {
    let contractAddress = DOM.elid('contract-address');
    await contract.authorizeContract(contractAddress.value);
    contractAddress.value = '';
}

const deauthorizeContract = async () => {
    const contractAddress = DOM.elid('contract-address');
    await contract.deauthorizeContract(contractAddress.value);
    contractAddress.value = '';
}
*/

const setOperationalStatus = async (enabled) => {
    await contract.setOperationalStatus(enabled);
    await refreshStatus();
}

const setOperationalStatusFalse = async () => {
    await setOperationalStatus(false);
}

const setOperationalStatusTrue = async () => {
    await setOperationalStatus(true);
}

const setOperationalStatusFalseApp = async () => {
    await contract.setOperationalStatusApp(false);
    await refreshStatus();
}

async function getOperationalStatus() {
    let contractIsOperational;
    let numberOfRegisteredAirlines;
    //let numberOfFundedAirlines;
    let contractBalance;
    let insuranceBalance;

    try {
        contractIsOperational = await contract.isOperational();
    } catch (error) {
        contractIsOperational = "Error - Check console for details";
        console.log(error);
    }

    try {
        numberOfRegisteredAirlines = await contract.getNumberOfRegisteredAirlines();
    } catch (error) {
        numberOfRegisteredAirlines = "Error - Check console for details";
        console.log(error);
    }
/*
    try {
        numberOfFundedAirlines = await contract.getNumberOfFundedAirlines();
    } catch (error) {
        numberOfFundedAirlines = "Error - Check console for details";
        console.log(error);
    }
*/
    try {
        contractBalance = await contract.getContractBalance();
    } catch (error) {
        contractBalance = "Error - Check console for details";
        console.log(error);
    }

    /*
    try {
        insuranceBalance = await contract.getInsuranceBalance();
    } catch (error) {
        insuranceBalance = "Error - Check console for details";
        console.log(error);
    }
    */

    await removeAllChildren('operational-status');

    await display('operational-status', 'Operational Status', 'Status of contract', [
        {label: 'Operational Status:', value: contractIsOperational},
        {label: 'Number of registered airlines:', value: numberOfRegisteredAirlines},
        //{label: 'Number of funded airlines:', value: numberOfFundedAirlines},
        {label: 'Contract Balance:', value: contractBalance},
        //{label: 'Funds held for insurance:', value: insuranceBalance},
        {label: 'Last updated:', value: new Date()}
    ]);

    // make sure we have all the current flights
    try {
        await removeAllChildren('select-flight');
        let currentFlights = await contract.getCurrentFlights();
        const currentFlightSelect = DOM.elid('select-flight');
        for (let index = 0; index < currentFlights.length; index++) {
            let currentFlight = await contract.getFlightInformation(currentFlights[index]);
            let option = document.createElement('option');
            option.append(`${new Date(new BigNumber(currentFlight[1]).toNumber()).toISOString()} ${currentFlight[0]}`)
            option.value = currentFlights[index];

            currentFlightSelect.append(option);
        }
    } catch (error) {
        console.log(error);
    }
}

const refreshStatus = async () => {
    await getOperationalStatus();
}

const removeAllChildren = async (parent) => {
    let displayDiv = DOM.elid(parent);
    while (displayDiv.firstChild) {
        displayDiv.removeChild(displayDiv.firstChild);
    }
}

const display = async (divid, title, description, results) => {
    let displayDiv = DOM.elid(divid);
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className: 'row text-white'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);
}

function eventHandler(error, event) {
    if (blockNumbersSeen.indexOf(event.transactionHash) > -1) {
        blockNumbersSeen.splice(blockNumbersSeen.indexOf(event.transactionHash), 1);
        return;
    }
    blockNumbersSeen.push(event.transactionHash);
    console.log(event.address);

    const log = DOM.elid('log-ul');
    let newLi1 = document.createElement('li');
    newLi1.append(`${event.event} - ${event.transactionHash}`);
    log.appendChild(newLi1);
}


/*
function EnableDisable(customerAddress, ether) {
    //Reference the Button.
    var btnSubmit = document.getElementById("submitCustomerDetails");

    //Verify the TextBox value.
    if (customerAddress.value.trim() != "") {
        //Disable the TextBox when TextBox has value.
        submitCustomerDetails.disabled = false;
    } else if (ether == 0 || ether > 1) {
        //Disable the Enable the TextBox when TextBox has value.
        submitCustomerDetails.disabled = false;
    } else {
        //Enable both the TextBox when TextBox is empty.
        btnSubmit.disabled = true;
    }
}; 
*/








