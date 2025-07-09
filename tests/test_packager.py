import os
import sys
from pathlib import Path

import cocotb
from cocotb.triggers import Timer
from cocotb.runner   import get_runner

async def generate_clock(dut):
    """Generate clock and initial condition"""
    for cycle in range(100000):
        dut.clk.value = 0
        await Timer(25, 'ns')
        dut.clk.value = 1
        await Timer(25, 'ns')    

@cocotb.test()
async def manch_basic_test(dut):
    cocotb.start_soon(generate_clock(dut))
    dut.data_adc0.value = 111
    dut.data_adc1.value = 222
    dut.data_adc2.value = 333
    dut.data_adc3.value = 444
    dut.data_adc4.value = 555
    dut.data_adc5.value = 777
    dut.write_enable.value = 1
    dut.sync_pulse.value = 1
    dut.busy.value       = 0
    dut.rst.value        = 0
    dut.data_valid.value = 1   
    dut.state.value = 0
    await Timer(1000, 'ns')





def test_manch_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "model"))

    if hdl_toplevel_lang == "verilog":
        sources = [proj_path / "rtl" / "packager.v"]
    build_test_args = []
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "tests"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="packager",
        always=True,
        build_args=build_test_args,
    )
    runner.test(
        hdl_toplevel="packager", test_module="test_packager", test_args=build_test_args
    )


if __name__ == "__main__":
    test_manch_runner()
