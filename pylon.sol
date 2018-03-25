pragma solidity ^0.4.15;

/***************************************************************************\
 *   Pylon: Oracle output collection and broadcast contract
 *
 *   Pythian oracle contracts are push-based multisignature arrangements;
 *   pylon contracts can be used to collect their oracle outputs for
 *   pull-based retrievals as needed.
 *
 *   A pylon contract allows any other account or contract to write to it
 *   and maintains a mapping of the originating oracle, the output register
 *   written to, and the (hash) value written to that register.
 *   
\***************************************************************************/

contract Pylon {
    /******************\
     *  Value Status  *
     ********************************************************************\
     *  @dev The different possible value statuses:
     *       Active: value is not yet set (predictions can be made)
     *       Locked: value is not yet set (predictions cannot be made)
     *       Finalized: value is set
    \********************************************************************/
    // enum State { Active, Locked, Finalized }

    /*************\
     *  Storage  *
    \*************/
    mapping(address => mapping(bytes32 => bytes32)) public values;      // Oracle address => register => value
    mapping(address => mapping(bytes32 => uint)) public statuses;       // Oracle address => register => status of register
    bool public rewritable;                                             // Whether values can be updated after initial write

    /************\
     *  Events  *
    \************/
    event OracleOutput(address oracle, bytes32 register, bytes32 value);
    event StatusUpdate(address oracle, bytes32 register, uint status);

    /*********************\
     *  Public functions
     *********************\
     *  @dev Constructor
    \*********************/
    function Pylon(bool _rewritable) public {
        rewritable = _rewritable;
    }

    /***********************************************\
     *  @dev Set function
     *  @param register Output register written to
     *  @param value Value written to register
    \***********************************************/
    function set(bytes32 register, bytes32 value) public {
        require(statuses[msg.sender][register] < 2 || rewritable);

        values[msg.sender][register] = value;
        emit OracleOutput(msg.sender, register, value);

        // After value is set, update status (2 == State.Finalized)
        setStatus(register, 2);
    }

    /***************************************************\
     *  @dev Get function
     *  @param register Oracle lookup retrieved from
     *  @param register Value register retrieved from
     *  @return Value from register
    \***************************************************/
    function get(address oracle, bytes32 register) public constant returns (bytes32 value) {
        return values[oracle][register];
    }

    /************************************************\
     *  @dev setStatus function
     *  @param register Relevant register to update
     *  @param status Status to set register to
     *  Will not allow status to drop unless
     *    the pylon is rewritable
    \************************************************/
    function setStatus(bytes32 register, uint status) public {
        // For now, there's no status > Finalized
        require(status <= 2);
        require(rewritable || statuses[msg.sender][register] < status);
        statuses[msg.sender][register] = status;
        emit StatusUpdate(msg.sender, register, status);
    }

    /***************************************************\
     *  @dev incrementStatus function
     *  @param register Relevant register to increment
    \***************************************************/
    function incrementStatus(bytes32 register) public {
        uint status = statuses[msg.sender][register] + 1;
        // For now, there's no status > Finalized
        require(status <= 2);

        statuses[msg.sender][register] = status;
        emit StatusUpdate(msg.sender, register, status);
    }

    /***************************************************\
     *  @dev getStatus function
     *  @param register Oracle lookup retrieved from
     *  @param register Status register retrieved from
     *  @return Status from register
    \***************************************************/
    function getStatus(address oracle, bytes32 register) public constant returns (uint status) {
        return statuses[oracle][register];
    }
}