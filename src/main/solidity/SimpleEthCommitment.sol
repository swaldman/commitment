pragma solidity ^0.5.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9fdc91758dbd958a28a238a87c71b21e501a47c7/contracts/math/SafeMath.sol";
import "https://github.com/swaldman/sol-key-iterable-mapping/blob/8773f95687c6467979936f32b0aaa72f921e4a75/src/main/solidity/AddressUInt256KeyIterableMapping.sol";

contract SimpleEthCommitment {
  // libraries
  using SafeMath for uint256;
  using AddressUInt256KeyIterableMapping for AddressUInt256KeyIterableMapping.Store;

  // event definitions
  event Funded( address indexed funder, uint256 oldValue, uint256 newValue );
  event Unfunded( address indexed funder, uint256 oldValue, uint256 newValue );
  event Committed( address indexed funder );
  event CommittingStarts( address indexed firstComitter );
  event CommitmentsCanceled( address indexed withdrawer );
  event Locked( address indexed lastCommitter );
  event Burnt( address indexed burner );
  event Completed();
  event Withdrawal( address indexed withdrawer, uint256 amount );

  // STILL TO DO!!! Emit events in code

  // storage

  AddressUInt256KeyIterableMapping.Store private team;
  mapping (address=>bool) public committed;

  enum State { Funding, Committing, Locked, Complete, Burnt }

  uint256 public duration;
  uint256 public expiration;

  // without a low max, unbounded iterations might become unperformable in transactions
  uint8 constant MAX_TEAM_SIZE = 5; 

  State public state;

  constructor( uint256 _duration ) public {
    duration   = _duration;
    expiration = 0;
    state      = State.Funding;
  }

  // public functions

  function fund() public payable {
    require( state == State.Funding );
    require( msg.value > 0 );
    ( , uint256 value ) = team.get( msg.sender );
    uint256 newValue = value.add( msg.value );
    team.put( msg.sender, newValue );
    require( team.keyCount() <= MAX_TEAM_SIZE );
  }

  function commit() public {
    require( state == State.Funding || state == State.Committing );
    require( team.keyCount() > 1 );

    ( bool exists, uint256 value ) = team.get( msg.sender );

    require( exists && value > 0 );

    committed[ msg.sender ] = true;

    if ( allCommitted() ) {
      lock();
    }
    else {
      if ( state == State.Funding ) {
	state = State.Committing;
      }
    }
  }

  function burn() public {
    if ( state == State.Locked && now > expiration) complete();
    require( state == State.Locked );
    state = State.Burnt;
    address(0).transfer( address(this).balance );
  }

  function withdraw() public {
    if ( state == State.Locked && now > expiration) complete();
    require( state == State.Funding || state == State.Committing || state == State.Complete );
    ( bool exists, uint256 toPay ) = team.get( msg.sender );
    require( exists && toPay > 0 );
    team.remove( msg.sender );
    delete committed[msg.sender];
    if ( state == State.Committing ) uncommit();
    msg.sender.transfer(toPay);
  }

  // public accessors
  function getState() public view returns (uint256 _state) {
    _state = uint256(state);
  }

  function getParticipants() public view returns( address[] memory _participants ) {
    _participants = team.allKeys();
  }

  function bondFor( address participant ) public view returns( uint256 amount ) {
    ( bool exists, uint256 value ) = team.get( participant );
    require( exists );
    amount = value;
  }

  function isCommitted( address participant ) public view returns (bool _committed) {
    _committed = committed[ participant ];
  }

  // private utilities

  function complete() private {
    require( state == State.Locked );
    state = State.Complete;
  }

  function lock() private {
    require( state == State.Committing );
    state = State.Locked;
    expiration = now.add( duration );
  }

  // dangerous, unbounded iteration.
  // if there are too many users, this function may not be able to execute
  function allCommitted() private view returns (bool) {
    uint256 count = team.keyCount();
    for ( uint256 i = 0; i < count; ++i ) {
      if (!committed[ team.keyAt(i) ]) return false;
    }
    return true;
  }

  // dangerous, unbounded iteration.
  // if there are too many users, this function may not be able to execute
  function uncommit() private {
    uint256 count = team.keyCount();
    for ( uint256 i = 0; i < count; ++i ) delete committed[ team.keyAt(i) ];
    state = State.Funding;
  }
}
