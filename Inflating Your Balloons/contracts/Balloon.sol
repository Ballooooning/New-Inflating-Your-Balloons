// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import { SuperAppBase } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import { ISuperfluid, ISuperToken, SuperAppDefinitions } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

/// @dev Constant Flow Agreement registration key, used to get the address from the host.
bytes32 constant CFA_ID = keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

contract Balloon is ERC721, SuperAppBase {

    error InvalidToken();
    error InvalidAgreement();
    error InvalidTransfer();
    error Unauthorized();

    /// @dev super token library
    using SuperTokenV1Library for ISuperToken;

    struct BalloonProfile {
        // timestamp where a balloon's flow was last modified - created, updated, or deleted to contract
        uint256 latestFlowMod;
        // current flow rate for the balloon
        int96 flowRate;
        // amount of air streamed to balloon so far upon a flow modification (created/update/delete)
        uint256 streamedSoFarAtLatestMod;
    } 

    /// @dev mapping balloon nft ids to balloon profile info
    mapping(uint256 => BalloonProfile) public balloonProfiles;

    /// @dev mapping of accounts to their balloons (ERC721 gives you token IDs to owners in _owners)
    mapping(address => uint256) public balloonOwned;

    /// @dev metadata for each stage of growth for balloon NFTs
    string[3] public stageMetadatas = [
        "ipfs://QmYUXy3JjoCjx1Fji71v9pPAWs3kAdrhBtUvVJw6m89g4A/plant1.json",
        "ipfs://QmYUXy3JjoCjx1Fji71v9pPAWs3kAdrhBtUvVJw6m89g4A/plant2.json",
        "ipfs:///QmYUXy3JjoCjx1Fji71v9pPAWs3kAdrhBtUvVJw6m89g4A/plant3.json"
    ];

    /// @dev how much seconds must pass for each stage of growth
    uint256[3] public stageAmounts;

    /// @dev current token ID
    uint256 public tokenId;

    /// @dev Super token that may be streamed to this contract
    ISuperToken public immutable acceptedToken;

    constructor(
        uint256[3] memory _stageAmounts,
        ISuperToken _acceptedToken
    ) ERC721(
        "Balloon",
        "Balloon"  
    ) {


        stageAmounts = _stageAmounts;
        acceptedToken = _acceptedToken;

        // Registers Super App, indicating it is the final level (it cannot stream to other super
        // apps), and that the `before*` callbacks should not be called on this contract, only the
        // `after*` callbacks.
        ISuperfluid(acceptedToken.getHost()).registerApp(
            SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
        );

    }

    // ---------------------------------------------------------------------------------------------
    // MODIFIERS

    modifier onlyHost() {
        //can call getHost() on super token to get address of host
        if ( msg.sender != acceptedToken.getHost()) revert Unauthorized();
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        if ( superToken != acceptedToken ) revert InvalidToken();
        IConstantFlowAgreementV1 _cfa = IConstantFlowAgreementV1(address(ISuperfluid(acceptedToken.getHost()).getAgreementClass(CFA_ID)));
        if ( agreementClass != address(_cfa) ) revert InvalidAgreement();
        _;
    }

    // ---------------------------------------------------------------------------------------------
    // CALLBACK LOGIC

    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        override
        onlyHost()
        onlyExpected(superToken, agreementClass)
        returns (bytes memory /*newCtx*/)
    {
        // get flow sender
        (address flowSender, ) = abi.decode(agreementData, (address, address));

        // if the flow sender DOESN'T already have a balloon
        if ( balloonOwned[flowSender] == 0 ) {

            tokenId++;

            // mint balloon to flow sender
            _mint(flowSender, tokenId);

            // set the token id for the flow sender
            balloonOwned[flowSender] = tokenId;

        }

        // update the info for the flow sender's balloon
        balloonUpdate(flowSender, tokenId);   

        return ctx;  
    }

    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        override
        onlyHost()
        onlyExpected(superToken, agreementClass)
        returns (bytes memory /*newCtx*/)
    {
        // get flow sender
        (address flowSender, ) = abi.decode(agreementData, (address, address));

        // get token id for flow sender
        uint256 tokenId = balloonOwned[flowSender];

        // update the info for the flow sender's balloon
        balloonUpdate(flowSender, tokenId); 

        return ctx;
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        override
        onlyHost()
        onlyExpected(superToken, agreementClass)
        returns (bytes memory /*newCtx*/)
    {
        // get flow sender
        (address flowSender, ) = abi.decode(agreementData, (address, address));

        // get token id for flow sender
        uint256 tokenId = balloonOwned[flowSender];

        // update the info for the flow sender's balloon
        balloonUpdate(flowSender, tokenId); 

        return ctx;
    }


    function balloonUpdate(address flowSender, uint256 tokenId) internal {

        // update streamedSoFarAtLatestMod to current value of streamedSoFar 
        balloonProfiles[tokenId].streamedSoFarAtLatestMod = streamedSoFar(tokenId);
        
        balloonProfiles[tokenId].flowRate = acceptedToken.getFlowRate(flowSender, address(this));
        // set flowRate to new flow rate
        // (,balloonProfiles[tokenId].flowRate,,) = cfaLib.cfa.getFlow(
        //     acceptedToken,  // super token being streamed
        //     flowSender,     // sender
        //     address(this)   // receiver
        // );

        // set latestFlowMod to current time stamp
        balloonProfiles[tokenId].latestFlowMod = block.timestamp;

    }



    // ---------------------------------------------------------------------------------------------
    // ERC721

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId, /* firstTokenId */
        uint256 /* batchSize */
    ) internal override {

        // if it's a transfer
        if ( from != address(0) ) {

            // balloon receiver can't already have a balloon
            if ( balloonOwned[to] != 0 ) revert InvalidTransfer();

            // cancel the balloon sender's stream
            acceptedToken.deleteFlow(        
                from,
                address(this)
            );

            // update the balloon's info
            balloonUpdate(from, firstTokenId);

            // update ownership
            balloonOwned[from] = 0;
            balloonOwned[to] = firstTokenId;

        }

    }

    // ---------------------------------------------------------------------------------------------
    // Read functions

    /// @notice Returns how much has been streamed so far to grow a certain Balloon
    /// @param tokenId ID of Balloon NFT being queried
    function streamedSoFar(uint256 tokenId) public view returns(uint256) {

        // seconds passed since last flow modification* tokens/second flow rate = tokens streamed since last flow modification
        uint256 streamedSinceLatestMod = uint(int(balloonProfiles[tokenId].flowRate)) * ( block.timestamp - balloonProfiles[tokenId].latestFlowMod );

        // amount streamed up until last modification (held staticly in mapping) + amount streamed since mod (changing per-second w/ rising block.timestamp)
        return balloonProfiles[tokenId].streamedSoFarAtLatestMod + streamedSinceLatestMod;

    }

    /// @notice Overrides tokenURI
    /// @param tokenId token ID of NFT being queried
    /// @return token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {

        // get amount streamed so far
        uint256 _streamedSoFar = streamedSoFar(tokenId);

        // iterate down levels and see which stage the token id has reached
        uint256 stageAmount = stageAmounts[0];
        for( uint256 i = 0; i < 2; i++) {

            // if amount streamed so far is under the stage's amount
            if (_streamedSoFar < stageAmount) {
                // it's within that tier, so return stage metadata
                return stageMetadatas[i];
            // else, the random number is above probability level
            } else {
                // increase probability sum to include next level
                stageAmount += stageAmounts[i];
            }

        }


        // if it's cleared the first two levels, then level 3 is everything beyond, so just return it
        return stageMetadatas[2];

    }

}
