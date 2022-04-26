%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_in_range
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import split_felt

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.starknet.common.messages import send_message_to_l1

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

#
# Custom logic
# 

struct Listing:
    member id : felt
    member nft_contract_address : felt
    member nft_id : felt
    member owner: felt
    member end_date: felt
    member type_of_award: felt
    member type_of_bid: felt
    member status: felt
end

@storage_var
func owner_address() -> (address: felt):
end

@storage_var
func id_to_listing(id: felt) -> (listing : Listing):
end



@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner
    ):
    owner_address.write(owner)
    return ()
end


@external
func create_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(listing: Listing):
    alloc_locals

    id_to_listing.write(listing.id, Listing(
        id=listing.id,
        nft_contract_address=listing.nft_contract_address,
        nft_id=listing.nft_id,
        owner=listing.owner,
        end_date=listing.end_date,
        type_of_award=listing.type_of_award,
        type_of_bid=listing.type_of_bid,
        status=0
        )
    )

    let (contract_address) = get_contract_address()
    let (token_id: Uint256) = felt_to_uint256(listing.nft_id)
    
    IERC721.transferFrom(
        contract_address=listing.nft_contract_address, from_=listing.owner, to=contract_address, tokenId=token_id
    )
    # ERC721_transferFrom(listing.owner, contract_address, token_id)
    return ()
end

@view
func get_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(listing_id : felt) -> (listing : Listing):
    let (listing) = id_to_listing.read(listing_id)
    return (listing)
end

@external
func finalize_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(listing_id: felt, winner: felt):
    alloc_locals

    let (listing) = id_to_listing.read(listing_id)
    assert listing.status = 0

    id_to_listing.write(listing_id, Listing(
        id=listing.id,
        nft_contract_address=listing.nft_contract_address,
        nft_id=listing.nft_id,
        owner=listing.owner,
        end_date=listing.end_date,
        type_of_award=listing.type_of_award,
        type_of_bid=listing.type_of_bid,
        status=1
        ))
    let (contract_address) = get_contract_address()

    let (token_id: Uint256) = felt_to_uint256(listing.nft_id)

     IERC721.transferFrom(
        contract_address=listing.nft_contract_address, from_=contract_address, to=winner, tokenId=token_id
    )

    return ()
end

func felt_to_uint256{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x : felt) -> (x_ : Uint256):
    let (high, low) = split_felt(x)

    return (Uint256(low=low, high=high))
end

