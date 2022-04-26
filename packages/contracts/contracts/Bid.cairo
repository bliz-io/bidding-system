# This indicates we're creating a starknet contract, rather than a pure Cairo program
%lang starknet

# Builtins are low-level execution units that perform some predefined computations useful to Cairo programs
#   pedersen is the builtin for Perdern hash computations
#   range_check is useful for numerical comparison operations
# Read more at: https://www.cairo-lang.org/docs/how_cairo_works/builtins.html
%builtins pedersen range_check

# The pedersen builtin is actually of type HashBuiltin, so we need to import that for function declarations
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.bool import (TRUE, FALSE)

# the math module contains useful math helpers for numerical comparisons, such as assert_le (assert lower-or-equal)
from starkware.cairo.common.math import (assert_le, assert_not_equal)
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_caller_address
)

namespace BidState:
    const UNCONFIRMED = 0
    const CONFIRMED = 1
    const REVELEAD = 2
end


struct Bid:
    member state : felt
    member pedersen_hash : felt
    member blocknumber : felt
    member account_id : felt
    member auction_id : felt
    member proof : felt
    member amount : felt
end

@storage_var
func bids(bid_id: felt) -> (placed_bid: Bid):
end

@storage_var
func confirmed_bids(key: felt) -> (bid_id : felt):
end


@event
func BidPlaced(bid_id : felt):
end

@event
func BidConfirmed(bid_id : felt):
end

@event
func BidRevealed(bid_id : felt):
end

# the constructor decorator is what you'd expect
# but function declarations may look weird at first, due to the two sets of arguments
# between {} we see the (not-so) implicit arguments
#   syscall_ptr allows access to system call, such as read() and write() of storage values
#   pedersen_ptr and range_check_ptr correspond to the two imported builtints. Storage values also require these behind the scenes
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end

# this one actually mutates state
@external
func place_bid{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
} (bid_hash : HashBuiltin*) -> (bid_id : HashBuiltin*):
    let (blocknumber) = get_block_number()
    let (account_id) = get_caller_address()
    tempvar bid = Bid(
        state= BidState.UNCONFIRMED,
        pedersen_hash= bid_hash,
        blocknumber= blocknumber,
        account_id= account_id,
        auction_id= 0,
        proof= 0,
        amount= 0,
    )
    local args_array : felt*
    args_array[0] = bid.pedersen_hash
    args_array[1] = bid.blocknumber
    args_array[2] = account_id
    let (id) = hash_chain{hash_ptr=pedersen_ptr}(args_array)
    bids.write(id, bid)
    BidPlaced.emit(id)
    return (id)
end

# this one actually mutates state
@external
func confirm_bid{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
} (bid_id : HashBuiltin*, auction_id : felt, proof : felt):
    
    let (exists) = _bid_exists(bid_id)
    with_attr error_message("IAuction: bid not found"):
        assert exists = TRUE
    end

    let (bid) = bids.read(bid_id)
    let (caller) = get_caller_address()
    with_attr error_message("IAuction: bidder don't match"):
        assert bid.account_id = caller
    end

    with_attr error_message("IAuction: invalid state"):
        assert_not_equal(bid.state, BidState.REVELEAD)
    end

    bid.auction_id = auction_id
    bid.proof = proof
    bid.state = BidState.CONFIRMED
    let (key) = hash2{hash_ptr=pedersen_ptr}(auction_id, bid.account_id)
    confirmed_bids.write(key, bid_id)
    BidConfirmed.emit(bid_id)

    return ()
end

@external
func reveal_bid{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
} (bid_id : HashBuiltin*, amount : felt):
    alloc_locals
    
    let (exists) = _bid_exists(bid_id)
    with_attr error_message("IAuction: bid not found"):
        assert exists = TRUE
    end

    let (bid) = bids.read(bid_id)
    let (caller) = get_caller_address()
    with_attr error_message("IAuction: bidder don't match"):
        assert bid.account_id = caller
    end

    let (key) = hash2{hash_ptr=pedersen_ptr}(bid.auction_id, bid.account_id)
    let (confirmed_bid) = confirmed_bids.read(key)
    with_attr error_message("IAuction: not the confirmed bid"):
        assert confirmed_bid = bid_id
    end

    with_attr error_message("IAuction: invalid state"):
        assert bid.state = BidState.CONFIRMED
    end

    local args_array : felt*
    args_array[0] = caller
    args_array[1] = bid.auction_id
    args_array[2] = bid.proof
    args_array[3] = amount
    let (check) = hash_chain{hash_ptr= pedersen_ptr}(args_array)
    with_attr error_message("IAuction: bid hash doesn't match"):
        assert check = bid.pedersen_hash
    end

    bid.state = BidState.REVELEAD
    bid.amount = amount
    BidRevealed.emit(bid_id)

    return ()
end

@view
func get_bid{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(bid_id : HashBuiltin*) -> (bid: Bid):
    let (exists) = _bid_exists(bid_id)
    with_attr error_message("IAuction: bid not found"):
        assert exists = TRUE
    end
    let (bid) = bids.read(bid_id)
    return (bid)
end

func _bid_exists{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(bid_id: HashBuiltin*) -> (res: felt):
    let (res) = bids.read(bid_id)

    if res.pedersen_hash == 0:
        return (FALSE)
    else:
        return (TRUE)
    end
end