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
    /*************\
     *  Storage  *
    \*************/
    mapping(address => mapping(bytes32 => bytes32)) public values;      // Oracle address => register => value
    bool public rewritable;                                             // Whether values can be updated after initial write

    /************\
     *  Events  *
    \************/
    event OracleOutput(address oracle, bytes32 register, bytes32 value);

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
     *  @return Whether write was successful
    \***********************************************/
    function set(bytes32 register, bytes32 value) public returns (bool success) {
        if (values[msg.sender][register].length > 0 && !rewritable) {
            return false;
        }

        values[msg.sender][register] = value;
        OracleOutput(msg.sender, register, value);
    }
}