import os
import sys
from pathlib import Path

import cocotb
from cocotb.triggers import Timer
from cocotb.runner import get_runner

async def generate_clock(dut):
    """Generate clock and initial condition"""
    dut.rst.value = 0
    dut.tx_data.value = 0
    dut.clk_counter.value = 0
    dut.CLK_TX.value = 0
    dut.tx_manch.value = 0
    for cycle in range(100000):
        dut.clk.value = 0
        await Timer(25, 'ns')
        dut.clk.value = 1
        await Timer(25, 'ns')

@cocotb.test()
async def manch_basic_test(dut):
    cocotb.start_soon(generate_clock(dut))
    for cycle in range(5000):
        dut.tx_data.value = 1
        await Timer(5000, 'ns')
        dut.tx_data.value = 0
        await Timer(5000, 'ns')
        dut.tx_data.value = 1
        await Timer(5000, 'ns')

def test_manch_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "model"))

    if hdl_toplevel_lang == "verilog":
        sources = [proj_path / "rtl" / "manch_encoding.v"]
    build_test_args = []
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "tests"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="manch_encoding",
        always=True,
        build_args=build_test_args,
    )
    runner.test(
        hdl_toplevel="manch_encoding", test_module="test_manch", test_args=build_test_args
    )


if __name__ == "__main__":
    test_manch_runner()
