%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

## Netlist:
## N0, N1 -> G0 (XOR) -> N17
## N0, N1 -> G1 (AND) -> N18
## N2, N3 -> G2 (XOR) -> N8
## N18, N8 -> G3 (XOR) -> N19
## N18, N8 -> G4 (AND) -> N9
## N2, N3 -> G5 (AND) -> N10
## N9, N10 -> G6 (OR) -> N20
## N4, N5 -> G7 (XOR) -> N11
## N20, N11 -> G8 (XOR) -> N21
## N20, N11 -> G9 (AND) -> N12
## N4, N5 -> G10 (AND) -> N13
## N12, N13 -> G11 (OR) -> N22
## N6, N7 -> G12 (XOR) -> N14
## N22, N14 -> G13 (XOR) -> N23
## N22, N14 -> G14 (AND) -> N15
## N6, N7 -> G15 (AND) -> N16
## N15, N16 -> G16 (OR) -> N24

## Constants viewable:
const GATE_COUNT = 17
@view
func gate_count {} () -> (gate_count : felt):
    return (GATE_COUNT)
end

const NET_COUNT = 25
@view
func net_count {} () -> (net_count : felt):
    return (NET_COUNT)
end

const INPUT_NET_COUNT = 8
@view
func input_net_count {} () -> (input_net_count : felt):
    return (INPUT_NET_COUNT)
end

const OUTPUT_NET_COUNT = 8
@view
func output_net_count {} () -> (output_net_count : felt):
    return (OUTPUT_NET_COUNT)
end

## Net value initialization:
@view
func init_net_values {range_check_ptr} () -> (
        arr_len : felt,
        arr : felt*
    ):
    alloc_locals
    let (local arr) = alloc()
    assert [arr+0] = 2
    assert [arr+1] = 2
    assert [arr+2] = 2
    assert [arr+3] = 2
    assert [arr+4] = 2
    assert [arr+5] = 2
    assert [arr+6] = 2
    assert [arr+7] = 2
    assert [arr+8] = 2
    assert [arr+9] = 2
    assert [arr+10] = 2
    assert [arr+11] = 2
    assert [arr+12] = 2
    assert [arr+13] = 2
    assert [arr+14] = 2
    assert [arr+15] = 2
    assert [arr+16] = 2
    assert [arr+17] = 2
    assert [arr+18] = 2
    assert [arr+19] = 2
    assert [arr+20] = 2
    assert [arr+21] = 2
    assert [arr+22] = 2
    assert [arr+23] = 2
    assert [arr+24] = 2
    return (25, arr)
end

## Gate index-to-type lookup:
@view
func gate_idx_to_typ {range_check_ptr} (gate_idx : felt) -> (gate_typ : felt):
    alloc_locals
    if gate_idx == 0:
        return (2)
    end
    if gate_idx == 1:
        return (1)
    end
    if gate_idx == 2:
        return (2)
    end
    if gate_idx == 3:
        return (2)
    end
    if gate_idx == 4:
        return (1)
    end
    if gate_idx == 5:
        return (1)
    end
    if gate_idx == 6:
        return (0)
    end
    if gate_idx == 7:
        return (2)
    end
    if gate_idx == 8:
        return (2)
    end
    if gate_idx == 9:
        return (1)
    end
    if gate_idx == 10:
        return (1)
    end
    if gate_idx == 11:
        return (0)
    end
    if gate_idx == 12:
        return (2)
    end
    if gate_idx == 13:
        return (2)
    end
    if gate_idx == 14:
        return (1)
    end
    if gate_idx == 15:
        return (1)
    end
    if gate_idx == 16:
        return (0)
    else:
        ## nonexistent gate index
        return (3) # 3 is an undefined gate type
    end
end

## For querying fanout gates of a given net:
@view
func fanout_gate_given_net  {range_check_ptr} (
        net_idx : felt
    ) -> (
        gate_idx_arr_len : felt,
        gate_idx_arr : felt*
    ):
    ## input felt: net index
    ## output felt: array of gate indices
    alloc_locals
    let (local gate_idx_arr) = alloc()

    if net_idx == 0:
        assert [gate_idx_arr + 0] = 1
        assert [gate_idx_arr + 1] = 0
        return (2, gate_idx_arr)
    end
    if net_idx == 1:
        assert [gate_idx_arr + 0] = 1
        assert [gate_idx_arr + 1] = 0
        return (2, gate_idx_arr)
    end
    if net_idx == 2:
        assert [gate_idx_arr + 0] = 5
        assert [gate_idx_arr + 1] = 2
        return (2, gate_idx_arr)
    end
    if net_idx == 3:
        assert [gate_idx_arr + 0] = 5
        assert [gate_idx_arr + 1] = 2
        return (2, gate_idx_arr)
    end
    if net_idx == 4:
        assert [gate_idx_arr + 0] = 10
        assert [gate_idx_arr + 1] = 7
        return (2, gate_idx_arr)
    end
    if net_idx == 5:
        assert [gate_idx_arr + 0] = 10
        assert [gate_idx_arr + 1] = 7
        return (2, gate_idx_arr)
    end
    if net_idx == 6:
        assert [gate_idx_arr + 0] = 12
        assert [gate_idx_arr + 1] = 15
        return (2, gate_idx_arr)
    end
    if net_idx == 7:
        assert [gate_idx_arr + 0] = 12
        assert [gate_idx_arr + 1] = 15
        return (2, gate_idx_arr)
    end
    if net_idx == 8:
        assert [gate_idx_arr + 0] = 3
        assert [gate_idx_arr + 1] = 4
        return (2, gate_idx_arr)
    end
    if net_idx == 9:
        assert [gate_idx_arr + 0] = 6
        return (1, gate_idx_arr)
    end
    if net_idx == 10:
        assert [gate_idx_arr + 0] = 6
        return (1, gate_idx_arr)
    end
    if net_idx == 11:
        assert [gate_idx_arr + 0] = 8
        assert [gate_idx_arr + 1] = 9
        return (2, gate_idx_arr)
    end
    if net_idx == 12:
        assert [gate_idx_arr + 0] = 11
        return (1, gate_idx_arr)
    end
    if net_idx == 13:
        assert [gate_idx_arr + 0] = 11
        return (1, gate_idx_arr)
    end
    if net_idx == 14:
        assert [gate_idx_arr + 0] = 13
        assert [gate_idx_arr + 1] = 14
        return (2, gate_idx_arr)
    end
    if net_idx == 15:
        assert [gate_idx_arr + 0] = 16
        return (1, gate_idx_arr)
    end
    if net_idx == 16:
        assert [gate_idx_arr + 0] = 16
        return (1, gate_idx_arr)
    end
    if net_idx == 17:
        return (0, gate_idx_arr)
    end
    if net_idx == 18:
        assert [gate_idx_arr + 0] = 3
        assert [gate_idx_arr + 1] = 4
        return (2, gate_idx_arr)
    end
    if net_idx == 19:
        return (0, gate_idx_arr)
    end
    if net_idx == 20:
        assert [gate_idx_arr + 0] = 8
        assert [gate_idx_arr + 1] = 9
        return (2, gate_idx_arr)
    end
    if net_idx == 21:
        return (0, gate_idx_arr)
    end
    if net_idx == 22:
        assert [gate_idx_arr + 0] = 13
        assert [gate_idx_arr + 1] = 14
        return (2, gate_idx_arr)
    end
    if net_idx == 23:
        return (0, gate_idx_arr)
    end
    if net_idx == 24:
        return (0, gate_idx_arr)
    else:
        ## nonexistent net index
        return (0, gate_idx_arr)
    end
end

## Gate-to-ports lookup:
@view
func gate_ports_lookup {range_check_ptr} (gate_idx : felt) -> (vo_net_idx : felt, vi_1_net_idx : felt, vi_2_net_idx : felt):
    if gate_idx == 0:
        return (17,0,1)
    end
    if gate_idx == 1:
        return (18,0,1)
    end
    if gate_idx == 2:
        return (8,2,3)
    end
    if gate_idx == 3:
        return (19,18,8)
    end
    if gate_idx == 4:
        return (9,18,8)
    end
    if gate_idx == 5:
        return (10,2,3)
    end
    if gate_idx == 6:
        return (20,9,10)
    end
    if gate_idx == 7:
        return (11,4,5)
    end
    if gate_idx == 8:
        return (21,20,11)
    end
    if gate_idx == 9:
        return (12,20,11)
    end
    if gate_idx == 10:
        return (13,4,5)
    end
    if gate_idx == 11:
        return (22,12,13)
    end
    if gate_idx == 12:
        return (14,6,7)
    end
    if gate_idx == 13:
        return (23,22,14)
    end
    if gate_idx == 14:
        return (15,22,14)
    end
    if gate_idx == 15:
        return (16,6,7)
    end
    if gate_idx == 16:
        return (24,15,16)
    else:
        ## nonexistent gate index
        return (0,0,0)
    end
end
