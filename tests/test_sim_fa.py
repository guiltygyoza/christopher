import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import random

@pytest.mark.asyncio
async def test_queue():
    starknet = await Starknet.empty()
    print()

    contract_sim = await starknet.deploy ('contracts/sim.cairo')
    print(f'> sim.cairo deployed.')

    TEST_GATES = 'gates_fulladder4_generated'
    contract_gates = await starknet.deploy (f'contracts/{TEST_GATES}.cairo')
    print(f'> {TEST_GATES}.cairo deployed.')
    print()

    seed = random.randrange(1,100)
    await contract_sim.admin_initialize_seed(seed).invoke()

    ret = await contract_gates.net_count().call()
    net_count = ret.result.net_count
    ret = await contract_gates.input_net_count().call()
    input_net_count = ret.result.input_net_count
    ret = await contract_gates.output_net_count().call()
    output_net_count = ret.result.output_net_count

    print('> Submitting gates to the simulator ...')
    await contract_sim.submit_gates_for_simulation(contract_gates.contract_address).invoke()
    print('  -> Done\n')

    # ret = await contract_sim.admin_get_event_queue_read_head().call()
    # eq_rd_head = ret.result.rd_idx
    # ret = await contract_sim.admin_get_event_queue_write_head().call()
    # eq_wr_head = ret.result.wr_idx

    # print(f'> Content of event_queue:')
    # for i in range(eq_rd_head, eq_wr_head):
    #     ret = await contract_sim.admin_read_event_queue(i).call()
    #     print(ret.result.event)
    # print()

    print(f'> Running simulation ...')
    ret_simulation = await contract_sim.run_simulation(contract_gates.contract_address).invoke()
    #print(ret.result)
    print('  -> Done\n')

    # print(f'> Content of net_table:')
    # for i in range(net_count):
    #     ret = await contract_sim.admin_view_net_table(i).call()
    #     print(f'{i} : {ret.result}')
    # print()

    ## retrieve input stimulus for A and B
    A = ''
    B = ''
    for i in range(input_net_count):
        #print(f'> querying {i}th of net table')
        ret = await contract_sim.admin_view_net_table(i).call()
        if i%2==0:
            #A += ret.result.net_val * 2**i
            A = str(ret.result.net_val) + A
        else:
            #B += ret.result.net_val * 2**i
            B = str(ret.result.net_val) + B
    A_int = int(A,2)
    B_int = int(B,2)
    print(f'> A=0x{A} ({A_int}), B=0x{B} ({B_int})')

    S = ''
    for i in range(output_net_count):
        idx = net_count-output_net_count+i
        #print(f'> querying {idx}th of net table')
        ret = await contract_sim.admin_view_net_table(idx).call()
        if idx%2==1:
            #S += ret.result.net_val * 2**i
            S = str(ret.result.net_val) + S
        elif idx==net_count-1:
            #S += ret.result.net_val * 2**i
            S = str(ret.result.net_val) + S
    S_int = int(S,2)
    print(f'> S=0x{S} ({S_int})')

    assert S_int == A_int + B_int, f'{S_int} != {A_int} + {B_int}'
    print(f'> {S_int} == {A_int} + {B_int}')
    print('  -> Test passed')
    print()

    print('Performance estimation:')
    print(f'> Latency: {ret_simulation.result.latency_unitless} (unitless)')
    print(f'> Area: {ret_simulation.result.area} (unitless)')
    print()


    # ret = await contract_sim.admin_get_event_queue_read_head().call()
    # eq_rd_head = ret.result.rd_idx
    # ret = await contract_sim.admin_get_event_queue_write_head().call()
    # eq_wr_head = ret.result.wr_idx

    # print(f'> Content of event_queue:')
    # for i in range(eq_rd_head, eq_wr_head):
    #     ret = await contract_sim.admin_read_event_queue(i).call()
    #     print(ret.result.event)
    # print()

    # ret = await contract_sim.admin_get_gate_queue_read_head().call()
    # gq_rd_head = ret.result.rd_idx
    # ret = await contract_sim.admin_get_gate_queue_write_head().call()
    # gq_wr_head = ret.result.wr_idx

    # print(f'> Content of gate_queue:')
    # for i in range(gq_rd_head, gq_wr_head):
    #     ret = await contract_sim.admin_read_gate_queue(i).call()
    #     print(ret.result)
    # print()