// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Consumer {
    function GetBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function deposit() public payable {}
}

contract SmartContractWallet {
    address payable public owner;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public IsallowtoSend;
    mapping(address => bool) public Guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) NextOwnerVotedBool;
    uint256 GuardianResetCount;
    uint256 public constant ConfirmationForGuardianReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    function Setguardians(address _Guardians, bool _isGuardian) public {
        require(msg.sender == owner, "you are not the owner,aboting");
        Guardians[_Guardians] = _isGuardian;
    }

    function ProposedOwner(address payable _NewOwner) public {
        require(Guardians[msg.sender], "you are not a guardian,Aborting");
        require(
            NextOwnerVotedBool[_NewOwner][msg.sender] == false,
            "you already voted aborting"
        );
        if (_NewOwner != nextOwner) {
            nextOwner = _NewOwner;
            GuardianResetCount = 0;
        }
        GuardianResetCount++;
        if (GuardianResetCount >= ConfirmationForGuardianReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function SetAllowance(address _for, uint256 _amount) public {
        require(msg.sender == owner, "you are not the owner,aboting");
        allowance[_for] == _amount;

        if (_amount > 0) {
            IsallowtoSend[_for] = true;
        } else {
            IsallowtoSend[_for] = false;
        }
    }

    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory _payload
    ) public returns (bytes memory) {
        //require(msg.sender == owner, "you are not the owner aborting");
        if (msg.sender != owner) {
            require(
                allowance[msg.sender] >= _amount,
                "You are trying to send more than you allowed,aborting"
            );
            require(
                IsallowtoSend[msg.sender],
                "You are not allowed to send anything,aborting"
            );

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returndata) = _to.call{value: _amount}(
            _payload
        );
        require(success, "aborting call was not successful");
        return returndata;
    }

    receive() external payable {}
}
