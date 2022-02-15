%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.bitwise import bitwise_operations, bitwise_or, bitwise_and, bitwise_xor
from starkware.cairo.common.alloc import alloc

## Event-driven simulator. ref: http://cs.baylor.edu/~maurer/aida/desauto/chapter3.pdf

####################################
########### Event Queue ############
####################################

struct Event:
    member net_idx : felt
    member new_val : felt
end

@storage_var
func event_queue (
        idx : felt
    ) -> (
        event : Event
    ):
end

@storage_var
func event_queue_read_head () -> (
        rd_idx : felt
    ):
end

@storage_var
func event_queue_write_head () -> (
        wr_idx : felt
    ):
end

@view
func admin_get_event_queue_read_head {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (
        rd_idx : felt
    ):
    return event_queue_read_head.read()
end

@view
func admin_get_event_queue_write_head {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (
        wr_idx : felt
    ):
    return event_queue_write_head.read()
end

func _write_event_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        event : Event
    ) -> ():
    let (wr_idx) = event_queue_write_head.read()
    event_queue.write(wr_idx, event)
    event_queue_write_head.write(wr_idx+1)
    return ()
end

@view
func admin_read_event_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt
    ) -> (
        event : Event
    ):
    ## TODO: assert rd_idx < idx < wr_idx
    let (event) = event_queue.read(idx)
    return (event)
end

func _pop_event_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (
        event : Event
    ):
    let (rd_idx) = event_queue_read_head.read()
    let (event) = event_queue.read(rd_idx)
    event_queue_read_head.write(rd_idx+1)

    return (event)
end


####################################
########### Gate Queue ############
####################################

struct Gate:
    member gate_idx : felt
    member gate_typ : felt
end

@storage_var
func gate_queue (
        idx : felt
    ) -> (
        gate : Gate
    ):
end

@storage_var
func gate_queue_read_head () -> (
        rd_idx : felt
    ):
end

@storage_var
func gate_queue_write_head () -> (
        wr_idx : felt
    ):
end

@view
func admin_get_gate_queue_read_head {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (
        rd_idx : felt
    ):
    return gate_queue_read_head.read()
end

@view
func admin_get_gate_queue_write_head {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (
        wr_idx : felt
    ):
    return gate_queue_write_head.read()
end

func _write_gate_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        gate : Gate
    ) -> ():
    let (wr_idx) = gate_queue_write_head.read()
    gate_queue.write(wr_idx, gate)
    gate_queue_write_head.write(wr_idx+1)
    return ()
end

@view
func admin_read_gate_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt
    ) -> (
        gate : Gate
    ):
    ## TODO: assert rd_idx < idx < wr_idx
    let (gate) = gate_queue.read(idx)
    return (gate)
end

func _pop_gate_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (
        gate : Gate
    ):
    let (rd_idx) = gate_queue_read_head.read()
    let (gate) = gate_queue.read(rd_idx)
    gate_queue_read_head.write(rd_idx+1)

    return (gate)
end

####################################
######### Gate Evaluation ##########
####################################

## evaluate gate output from input and gate-type
func _gate_evaluation {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        gate_typ : felt,
        vi_1 : felt,
        vi_2 : felt
    ) -> (
        vo : felt
    ):
    alloc_locals

    let (local result_and, local result_xor, local result_or) = bitwise_operations(vi_1, vi_2)
    let (local result_nand) = _invert(result_and)
    let (local result_not) = _invert(vi_1)
    let (local is_or)   = _is_zero(gate_typ - 0)
    let (local is_and)  = _is_zero(gate_typ - 1)
    let (local is_xor)  = _is_zero(gate_typ - 2)
    let (local is_nand) = _is_zero(gate_typ - 3)
    let (local is_not)  = _is_zero(gate_typ - 4)
    tempvar vo = result_or * is_or + result_and * is_and + result_xor * is_xor + result_nand * is_nand + result_not * is_not

    return (vo)
end

####################################
##### gates contract interface #####
####################################

# The interface for the other function is defined.
@contract_interface
namespace IContractGates:
    func gate_count () -> (gate_count : felt):
    end

    func init_net_values () -> (arr_len : felt, arr : felt*):
    end

    func input_net_count () -> (input_net_count : felt):
    end

    func output_net_count () -> (output_net_count : felt):
    end

    func fanout_gate_given_net (net_idx : felt) -> (gate_idx_arr_len : felt, gate_idx_arr : felt*):
    end

    func gate_idx_to_typ (gate_idx : felt) -> (gate_typ : felt):
    end

    func gate_ports_lookup (gate_idx : felt) -> (vo_net_idx : felt, vi_1_net_idx : felt, vi_2_net_idx : felt):
    end
end

####################################
############ Simulator #############
####################################

@storage_var
func net_table (
        net_idx : felt
    ) -> (
        net_val : felt
    ):
end

@storage_var
func gate_dict (
        gate_idx : felt
    ) -> (
        exist_in_gatequeue : felt
    ):
end

@view
func admin_view_net_table {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        net_idx : felt
    ) -> (
        net_val : felt
    ):
    let (net_val) = net_table.read(net_idx)
    return (net_val)
end

## TODO: could add a queue for submission-addresses, decoupling submission from simulation
@external
func submit_gates_for_simulation {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        gates_address : felt
    ) -> ():
    alloc_locals

    # initialize net table -- for now use submissions's init_net_values()
    let (local net_count : felt, local net_init_values : felt*) = IContractGates.init_net_values(gates_address)
    let (local input_net_count : felt)  = IContractGates.input_net_count(gates_address)
    let (local output_net_count : felt) = IContractGates.output_net_count(gates_address)
    _recurse_populate_net_table(net_count, net_init_values, 0)

    # create random stimuli and expected output -- for now use a single constant stimulus - all one's
    let (local input_stimuli) = alloc()
    _recurse_populate_random(input_net_count, input_stimuli, 0) # populate the array input_stimuli, from 0 to input_net_count

    # for each in Stimuli (skipped for now)
    # initialize EQ with stimulus
    _recurse_init_event_queue(input_net_count, input_stimuli, 0)

    return ()
end

@external
func run_simulation {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        gates_address : felt
    ) -> (latency_unitless : felt, area : felt):
    alloc_locals

    # main loop
    let (latency_unitless) = _main_loop(gates_address)

    # area estimation
    let (area) = _area_estimation(gates_address)

    return (latency_unitless, area)
end

####################################
##### Functions for recursion ######
####################################

func _recurse_populate_net_table {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        len : felt, arr : felt*, idx : felt) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    net_table.write(idx, [arr+idx])
    _recurse_populate_net_table (len, arr, idx+1)
    return ()
end

func _recurse_populate_random {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        len : felt, arr : felt*, idx : felt) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    let (random_bit) = _get_1b_pseudorandom()
    assert [arr+idx] = random_bit
    _recurse_populate_random (len, arr, idx+1)
    return ()
end

func _recurse_init_event_queue {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        len : felt, arr : felt*, idx) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    local new_val = [arr+idx]

    local syscall_ptr : felt* = syscall_ptr
    let (old_val) = net_table.read(idx)

    if new_val != old_val:
        _write_event_queue( Event(net_idx=idx, new_val=new_val) )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    _recurse_init_event_queue (len, arr, idx+1)
    return ()
end

func _main_loop {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        gates_address : felt
    ) -> (latency_unitless : felt):
    alloc_locals

    ## clear GateDict
    let (local gate_count) = IContractGates.gate_count(gates_address)
    _recurse_clear_gate_dict(gate_count, 0)

    ## Event Loop (populate GateLoop)
    _recurse_event_loop(gates_address)

    ## Check GateQueue size
    let (gq_rd_head) = gate_queue_read_head.read()
    let (gq_wr_head) = gate_queue_write_head.read()
    tempvar gq_size = gq_wr_head - gq_rd_head
    let (local bool_gq_is_not_empty) = is_not_zero(gq_size)

    ## Gate Loop (run if GateQueue is not empty)
    _recurse_gate_loop(gates_address)

    ## Check if EventQueue is empty
    let (eq_rd_head) = event_queue_read_head.read()
    let (eq_wr_head) = event_queue_write_head.read()
    tempvar eq_size = eq_wr_head - eq_rd_head
    if eq_size == 0:
        return (bool_gq_is_not_empty) ## this assume the submission has at least one gate. TODO handle exceptions
    end

    let (rest_of_latency) = _main_loop(gates_address)
    return (bool_gq_is_not_empty + rest_of_latency) ## this assume the submission has at least one gate. TODO handle exceptions
end

func _recurse_clear_gate_dict {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        len : felt, idx : felt) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    gate_dict.write(idx, 0)
    _recurse_clear_gate_dict (len, idx+1)
    return ()
end

func _recurse_event_loop {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (gates_address : felt) -> ():

    alloc_locals

    let (eq_rd_head) = event_queue_read_head.read()
    let (eq_wr_head) = event_queue_write_head.read()
    tempvar eq_size = eq_wr_head - eq_rd_head
    if eq_size == 0:
        return ()
    end

    ## Pop EventQueue
    let (local event : Event) = _pop_event_queue()

    ## Update NetTable with event
    net_table.write(event.net_idx, event.new_val)

    ## Find all fanout gates of event's net using submitted contract's fanout_gate_given_net()
    let (
        gate_idx_arr_len : felt, gate_idx_arr : felt*
    ) = IContractGates.fanout_gate_given_net(gates_address, event.net_idx)

    ## loop over gate_idx_arr, convert each gate_idx to gate_typ using submitted contract's gate_idx_to_typ()
    _recurse_update_gate_queue (gates_address, gate_idx_arr_len, gate_idx_arr, 0)

    ## recurse
    _recurse_event_loop(gates_address)
    return ()
end

func _recurse_update_gate_queue {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        gates_address : felt, len : felt, arr : felt*, idx) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    local gate_idx = [arr+idx]

    local syscall_ptr : felt* = syscall_ptr
    let (exist_in_gate_queue) = gate_dict.read(gate_idx)

    if exist_in_gate_queue == 0:
        let (gate_typ) = IContractGates.gate_idx_to_typ(gates_address, gate_idx)
        _write_gate_queue( Gate(gate_idx=gate_idx, gate_typ=gate_typ) )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    _recurse_update_gate_queue (gates_address, len, arr, idx+1)
    return ()
end

func _recurse_gate_loop {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        gates_address : felt
    ) -> ():

    alloc_locals

    ################
    ## Pseudocode ##
    ################
    ## for G in GQ:
    ##     vo = NT.read(G's output net_idx)
    ##     vi = NT.read(G's input net_idx)
    ##     vo_ = G's function (vi)
    ##     if vo != vo_:
    ##         EQ.write(G's output net_idx, vo_)

    let (gq_rd_head) = gate_queue_read_head.read()
    let (gq_wr_head) = gate_queue_write_head.read()
    tempvar gq_size = gq_wr_head - gq_rd_head
    if gq_size == 0:
        return ()
    end

    ## Pop GQ
    let (local gate : Gate) = _pop_gate_queue()

    ## Retrieve gate's in/out net indices from submitted contract using gate_ports_lookup()
    let (vo_net_idx, vi_1_net_idx, vi_2_net_idx) = IContractGates.gate_ports_lookup(gates_address, gate.gate_idx)

    ## Get the before-value of gate's output
    let (local vo) = net_table.read(vo_net_idx)

    ## Get the values of gate's input
    let (local vi_1) = net_table.read(vi_1_net_idx)
    let (local vi_2) = net_table.read(vi_2_net_idx)

    ## Evaluate the after-value of gate's output
    let (local vo_) = _gate_evaluation (gate.gate_typ, vi_1, vi_2)

    ## Write to EQ if gate's output changes
    tempvar vo_diff = vo - vo_
    if vo_diff != 0:
        _write_event_queue( Event(net_idx=vo_net_idx, new_val=vo_) )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    ## Recurse
    _recurse_gate_loop (gates_address)
    return ()
end

func _area_estimation {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*} (
        gates_address : felt
    ) -> (area : felt):
    alloc_locals

    let (local gate_count) = IContractGates.gate_count(gates_address)
    let (area) = _recurse_estimate_area(gates_address, gate_count, 0)

    return (area)
end

func _recurse_estimate_area {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        gates_address : felt, len : felt, idx : felt) -> (total_area : felt):
    alloc_locals

    if idx == len:
        return (0)
    end

    let (gate_typ) = IContractGates.gate_idx_to_typ(gates_address, idx)

    let (local is_or)   = _is_zero(gate_typ - 0)
    let (local is_and)  = _is_zero(gate_typ - 1)
    let (local is_xor)  = _is_zero(gate_typ - 2)
    let (local is_nand) = _is_zero(gate_typ - 3)
    let (local is_not)  = _is_zero(gate_typ - 4)
    local area = is_or * 2 + is_and * 2 + is_xor * 2 + is_nand * 2 + is_not * 1

    let (rest_area) = _recurse_estimate_area (gates_address, len, idx+1)
    tempvar total_area = area + rest_area

    return (total_area)
end

#################

# Utiliy function that inverts input 0<->1
func _invert {range_check_ptr} (value) -> (res):
    if value == 0:
        return (res=1)
    else:
        return (res=0)
    end
end

# Utility function that wraps and inverts is_not_zero()
func _is_zero {range_check_ptr} (value) -> (res):
    let (temp) = is_not_zero(value)
    let (temp_inv) = _invert(temp)
    return (res = temp_inv)
end

# Utility functions for pseudorandom number generation

@storage_var
func entropy_seed(
    ) -> (
        value : felt
    ):
end

@external
func admin_initialize_seed{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(seed : felt) -> ():

    entropy_seed.write(seed)

    return ()
end

## PRBS-7; ref: https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence
func _get_1b_pseudorandom{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*
    }() -> (num : felt):
    alloc_locals

    let (local a) = entropy_seed.read()

    let (local a_rightshift_6, _) = unsigned_div_rem(a, 64)
    let (local a_rightshift_5, _) = unsigned_div_rem(a, 32)
    local a_leftshirt_1 = a * 2

    ## random bit = ((a >> 6) ^ (a >> 5)) & 1
    let (newbit_) = bitwise_xor(a_rightshift_6, a_rightshift_5)
    let (local newbit) = bitwise_and(newbit_, 1)

    ## next a = ((a << 1) | newbit) & 0x7f
    let (a_next_) = bitwise_or(a_leftshirt_1, newbit)
    let (a_next) = bitwise_and(a_next_, 127)
    entropy_seed.write(a_next)

    return (newbit)
end
