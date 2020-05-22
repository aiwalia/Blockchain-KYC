pragma solidity ^0.5.9;


contract KYC {
    //to maintain a count of number of banks
    uint256 bankCount;

    //to store address of the user who deployed this smart contract
    address adminAddress;

    constructor() public {
        adminAddress = msg.sender;
        bankCount = 10;
    }

    // Struct customer
    // uname - username of the customer
    // dataHash - customer data
    // rating - rating given to customer given based on regularity
    // upvotes - number of upvotes recieved from banks
    // bank - address of bank that validated the customer account
    struct Customer {
        string uname;
        string dataHash;
        uint256 rating;
        uint256 upvotes;
        address bank;
        string password;
    }

    // Struct Organisation
    // name - name of the bank/organisation
    // ethAddress - ethereum address of the bank/organisation
    // rating - rating based on number of valid/invalid verified accounts
    // KYC_count - number of KYCs verified by the bank/organisation
    //upvotes - to keep track of upvotes to a bank
    struct Organisation {
        string name;
        address ethAddress;
        uint256 KYC_count;
        string regNumber;
        uint256 rating;
        uint256 upvotes;
    }

    // Struct Organisation
    // uname - username of the customer
    // bankAddress - ethereum address of the bank/organisation
    // Flag determining if a bank is allowed to do the KYC
    struct Request {
        string uname;
        address bankAddress;
        string customerDataHash;
        bool isAllowed;
    }

    //Sruct CustomerVotes is used to store votes made for a customer by a Banks
    //senderBank - address bank that has upvoted
    //receiverCustomer - uname of customer for whom upvote is done
    struct CustomerVotes {
        address senderBank;
        string receiverCustomer;
    }

    //Struct BankVotes is used to store votes for a bank made by other Banks
    //senderBank - address of bank that has upvoted
    //receiverBank - address of bank that has received upvoted
    struct BankVotes {
        address senderBank;
        address receiverBank;
    }

    // list of all customers
    Customer[] public allCustomers;

    // list of all Banks/Organisations
    mapping(address => Organisation) public allBanks;

    // list of all requests
    Request[] public allRequests;

    // list of all valid KYCs
    Request[] public validKYCs;

    //list of all customer votes
    CustomerVotes[] public allCustomerVotes;

    //list of all bank votes
    BankVotes[] public allBankVotes;

    //modifier to check if the user performing the action is admin
    modifier onlyAdmin {
        require(
            adminAddress == msg.sender,
            "Only admin can perform this action"
        );
        _;
    }

    //modifier to check if the user performing the action is among the list of banks
    modifier onlyBank {
        require(
            stringsEqual(allBanks[msg.sender].name, "") == false,
            "Only a bank can perform this action, sender not among existing banks"
        );
        _;
    }

    /*
    function to add a bank to the blockchain
    onlyAdmin modifier to check if user is admin
    @param - name of bank,address of bank, registeration number of the bank
    @returns - "true" if bank was added successfully and "false" if bank could not be added as it is already present
    */
    function addBank(
        string memory name,
        address bankAddress,
        string memory bankRegNum
    ) public payable onlyAdmin returns (bool) {
        if (bankAddress == allBanks[bankAddress].ethAddress) {
            return false;
        } else {
            allBanks[bankAddress].ethAddress = bankAddress;
            allBanks[bankAddress].name = name;
            allBanks[bankAddress].ethAddress = bankAddress;
            allBanks[bankAddress].regNumber = bankRegNum;
            allBanks[bankAddress].KYC_count = 0;
            allBanks[bankAddress].upvotes = 0;
            allBanks[bankAddress].rating = 0;
            return true;
        }
    }

    /*
    function to remove a bank from the list of banks
    modifier onlyAdmin to check if user calling the function is admin
    @param - storage address of the bank to be deleted from the list of banks
    @returns - "true" if bank is removed from the list and "false" if bank is not present in the list already
    */
    function removeBank(address bankAddress)
        public
        payable
        onlyAdmin
        returns (bool)
    {
        if (
            allBanks[bankAddress].ethAddress !=
            0x0000000000000000000000000000000000000000
        ) {
            delete allBanks[bankAddress];
            return true;
        } else {
            return false;
        }
    }

    // function to add request for KYC
    // @Params - Username for the customer, bankAddress and customerDataHash
    // Function is made payable as banks need to provide some currency to start of the KYC
    //process
    //returns 0 when customer cannot be added and 1 when cusromet is added successfully
    function addRequest(string memory Uname, string memory customerDataHash)
        public
        payable
        onlyBank
        returns (uint256)
    {
        address senderAddress = allBanks[msg.sender].ethAddress;
        /*if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allRequests.length; ++i) {
                if (
                    stringsEqual(allRequests[i].uname, Uname) &&
                    stringsEqual(
                        allRequests[i].customerDataHash,
                        customerDataHash
                    )
                ) {
                    return 0;
                }
            }
            bool isAllowed = false;
            if (allBanks[msg.sender].rating > 50) {
                isAllowed = true;
                allRequests.length++;
                allRequests[allRequests.length - 1] = Request(
                    Uname,
                    senderAddress,
                    customerDataHash,
                    isAllowed
                );
                return 1;
            }
        /*}*/
        return 0;
    }

    // function to remove request for KYC
    // @Params - Username for the customer
    // @return - This function returns 1 if removal is successful else this return 0 if the Username
    //for the customer is not found
    function removeRequest(string memory Uname, string memory customerDataHash)
        public
        payable
        onlyBank
        returns (int256)
    {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allRequests.length; ++i) {
                if (
                    stringsEqual(allRequests[i].uname, Uname) &&
                    stringsEqual(
                        allRequests[i].customerDataHash,
                        customerDataHash
                    )
                ) {
                    for (uint256 j = i + 1; j < allRequests.length; ++j) {
                        allRequests[i - 1] = allRequests[i];
                    }
                    allRequests.length--;
                    return 1;
                }
            }
       /* }*/
        // throw error if uname not found
        return 0;
    }

    // function to add request for KYC
    // @Params - Username for the customer and bankAddress
    // Function is made payable as banks need to provide some currency to start of the KYC
    //process
    function addKYC(
        string memory Uname,
        address bankAddress,
        string memory customerDataHash
    ) public payable onlyBank {
        for (uint256 i = 0; i < validKYCs.length; ++i) {
            if (
                stringsEqual(validKYCs[i].uname, Uname) &&
                validKYCs[i].bankAddress == bankAddress
            ) {
                return;
            }
        }
        validKYCs.length++;
        validKYCs[validKYCs.length - 1] = Request(
            Uname,
            bankAddress,
            customerDataHash,
            false
        );
        allBanks[bankAddress].KYC_count++;
    }

    // function to remove from valid KYC
    // @Params - Username for the customer
    // @return - This function returns 0 if removal is successful else this return 1 if the Username
    //for the customer is not found
    function removeKYC(string memory Uname)
        public
        payable
        onlyBank
        returns (int256)
    {
        for (uint256 i = 0; i < validKYCs.length; ++i) {
            if (stringsEqual(validKYCs[i].uname, Uname)) {
                for (uint256 j = i + 1; j < validKYCs.length; ++j) {
                    validKYCs[i - 1] = validKYCs[i];
                }
                validKYCs.length--;
                return 0;
            }
        }
        // throw error if uname not found
        return 1;
    }

    // function to compare two string value
    // This is an internal fucntion to compare string values
    // @Params - String a and String b are passed as Parameters
    // @return - This function returns true if strings are matched and false if the strings are not
    //matching
    function stringsEqual(string storage _a, string memory _b)
        internal
        view
        returns (bool)
    {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length) return false;
        // @todo unroll this loop
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    // function to add a customer profile to the database
    // @params - Username and the hash of data for the customer are passed as
    //parameters
    // returns 1 if successful
    // returns 0 if unsuccessful
    function addCustomer(string memory Uname, string memory DataHash)
        public
        payable
        onlyBank
        returns (int256)
    {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        f (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            // throw error if username already in use
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (
                    stringsEqual(allCustomers[i].uname, Uname) &&
                    stringsEqual(allRequests[i].customerDataHash, DataHash)
                ) return 0;
            }
            for (uint256 j = allRequests.length - 1; j >= 0; --j) {
                if (
                    allRequests[j].bankAddress ==
                    allBanks[msg.sender].ethAddress &&
                    allRequests[j].isAllowed == true
                ) {
                    allCustomers.length++;
                    allCustomers[allCustomers.length - 1] = Customer(
                        Uname,
                        DataHash,
                        0,
                        0,
                        msg.sender,
                        "0"
                    );
                    return 1;
                }
            }
       /* }*/
        // throw error if there is overflow in uint
        return 0;
    }

    // function to remove fraudulent customer profile from the database
    // @params - customer's username is passed as parameter
    // returns 1 if successful
    // returns 0 if customer profile not in database
    function removeCustomer(string memory Uname)
        public
        payable
        onlyBank
        returns (int256)
    {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (stringsEqual(allCustomers[i].uname, Uname)) {
                    for (uint256 j = i + 1; j < allCustomers.length; ++j) {
                        allCustomers[i - 1] = allCustomers[i];
                    }
                    allCustomers.length--;
                    return 1;
                }
            }
       /* }
        // throw error if uname not found*/
        return 0;
    }

    // function to modify a customer profile in database
    // @params - Customer username and datahash are passed as Parameters
    // returns 1 if successful
    // returns 0 if customer profile not in database
    function modifyCustomer(
        string memory Uname,
        string memory password,
        string memory DataHash
    ) public payable onlyBank returns (uint256) {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (stringsEqual(allCustomers[i].uname, Uname)) {
                    allCustomers[i].dataHash = DataHash;
                    allCustomers[i].bank = msg.sender;
                    allCustomers[i].password = password;
                    allCustomers[i].rating = 0;
                    allCustomers[i].upvotes = 0;
                    return 1;
                }
                removeKYC(Uname);
            }
            return 0;
        //}
    }

    // function to return customer profile data
    // @params - Customer username is passed as the Parameters
    // @return - This function return the cutomer datahash if found, else this function returns an error
    //string.
    function viewCustomer(string memory Uname, string memory password)
        public
        payable
        onlyBank
        returns (string memory)
    {
       /* address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (
                    stringsEqual(allCustomers[i].uname, Uname) &&
                    (stringsEqual(allCustomers[i].password, password))
                ) {
                     allCustomers[i].dataHash;
                }
            }
    // }
        return "Customer not found in database!";
    }


    /*function to upvote a customer and update its rating
    Uname- its the customer name for whom upvote is done
    @return- it returns 1 if successfull and 0 if failure
    */
    function upvoteCustomer(string memory Uname)
        public
        payable
        onlyBank
        returns (uint256)
    {
        uint256 rating;
        /*address senderBank = allBanks[msg.sender].ethAddress;
        if (senderBank != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomerVotes.length; ++i) {
                if (
                    (allCustomerVotes[i].senderBank == msg.sender) &&
                    (stringsEqual(allCustomerVotes[i].receiverCustomer, Uname))
                ) return 0;
            }
            for (uint256 j = 0; j < allCustomers.length; ++j) {
                if (stringsEqual(allCustomers[j].uname, Uname)) {
                    allCustomers[j].upvotes++;
                    allCustomerVotes.length++;
                    allCustomerVotes[allCustomerVotes.length -
                        1] = CustomerVotes(msg.sender, Uname);
                    rating = (allCustomers[j].upvotes * 100) / bankCount;
                    allCustomers[j].rating = rating;
                    if (allCustomers[j].rating > 50) {
                        addKYC(
                            Uname,
                            allCustomers[j].bank,
                            allCustomers[j].dataHash
                        );
                    }
                    return 1;
                }
            }
        /*}*/
        return 0;
    }

    /*
    Event to return all the KYC requests raised by a bank
    */
    event printKYCRequests(
        string uname,
        address bankAddress,
        string customerDataHash,
        bool flag
    );

    /*
    function to return all the KYC requests made by a Bank
    @param- address of the bank to return KYC requests
    @return- all the requests raised by the Bank
    */
    function getBankRequests(address bankAddress) public payable onlyBank {
        /*address bank = allBanks[msg.sender].ethAddress;
        if (bank != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allRequests.length; ++i) {
                if (allRequests[i].bankAddress == bankAddress) {
                    emit printKYCRequests(
                        allRequests[i].uname,
                        allRequests[i].bankAddress,
                        allRequests[i].customerDataHash,
                        allRequests[i].isAllowed
                    );
                }
            }
        //}
    }

    /*
        function to upvote a bank by another bank
        @param- bankAddress, address of the bank to upvoteBank
        @return- "0" when upvote is successful and "1" when upvote is not possible if the bank has already voted or does not exist in the blockchain
    */
    function upvoteBank(address bankAddress)
        public
        payable
        onlyBank
        returns (uint256)
    {
        address bank = allBanks[msg.sender].ethAddress;
        address receiverBank = allBanks[bankAddress].ethAddress;
        if (receiverBank == 0x0000000000000000000000000000000000000000 || receiverBank == bank) {
            return 1;
        }
        if (bank != 0x0000000000000000000000000000000000000000) {
            for (uint256 i = 0; i < allBankVotes.length; ++i) {
                if (
                    (allBankVotes[i].senderBank == msg.sender) &&
                    (allBankVotes[i].receiverBank == bankAddress)
                ) {
                    return 1;
                }
            }
            allBanks[receiverBank].upvotes++;
            allBankVotes.length++;
            allBankVotes[allBankVotes.length - 1] = BankVotes(
                msg.sender,
                bankAddress
            );
            uint256 rating = (allBanks[bankAddress].upvotes * 100) / bankCount;
            allBanks[bankAddress].rating = rating;
            return 0;
        }
        return 1;
    }

    /*
    function to get Customer rating
    @param - username(Uname) of the customer to fetch rating
    @returns - a uint value as rating of the customer
    */
    function getCustomerRating(string memory Uname)
        public
        view
        onlyBank
        returns (uint256)
    {
       /* address bankAddress = allBanks[msg.sender].ethAddress;
        if (bankAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (stringsEqual(allCustomers[i].uname, Uname)) {
                    return allCustomers[i].rating;
                }
            }
        /*}*/
    }

    /*
    function to get Bank getCustomerRating
    @param - address of the bank as bankAddress
    @returns -  rating of the bank
    */
    function getBankRating(address bankAddress)
        public
        view
        onlyBank
        returns (uint256)
    {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            return allBanks[bankAddress].rating;
        /*}*/
    }

    /*
    function to get the last bank that changed a cutomer's details
    @param - uname as name of the customer for whom bank that made last change is to be accessed
    @returns- the bank address that made changes to the Customer last
    */
    function getAccessHistory(string memory uname)
        public
        view
        onlyBank
        returns (address)
    {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (stringsEqual(allCustomers[i].uname, uname)) {
                    return allCustomers[i].bank;
                }
            }
        /*}*/
    }

    /*
    function to set password for a customer by a bank so that only a group of selected banks can modify customer data
    @params - username of the customer uname and password of the customer
    @returns- "true" when password is successfully set and "false" when password is not set as bank does not exist in the blockchain
    */
    function setPassword(string memory uname, string memory password)
        public
        payable
        onlyBank
        returns (bool)
    {
        /*address senderAddress = allBanks[msg.sender].ethAddress;
        if (senderAddress != 0x0000000000000000000000000000000000000000) {*/
            for (uint256 i = 0; i < allCustomers.length; ++i) {
                if (stringsEqual(allCustomers[i].uname, uname)) {
                    allCustomers[i].password = password;
                    return true;
                }
            }
        /*}*/
        return false;
    }

    /*
    event to display bank details
    */
    event bankDetails(
        string name,
        address ethAddress,
        uint256 KYC_count,
        string regNumber,
        uint256 rating
    );

    /*
    function to get the bank details of a bank
    @param - address of bank is passed
    @returns - details of the bank whose address is passed
    */
    function getBankDetails(address bankAddress) public payable onlyBank {
        /*address bank = allBanks[msg.sender].ethAddress;
        if (bank != 0x0000000000000000000000000000000000000000) {*/
            emit bankDetails(
                allBanks[bankAddress].name,
                allBanks[bankAddress].ethAddress,
                allBanks[bankAddress].KYC_count,
                allBanks[bankAddress].regNumber,
                allBanks[bankAddress].rating
            );
        /*}*/
    }
}
