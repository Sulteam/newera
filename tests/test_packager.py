import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.runner   import get_runner

@cocotb.test()
async def packager_test(dut):
    """Test for packager module"""
    
    ADC_COUNT = 6
    
    clock = Clock(dut.mclkin, 52, units="ns") 
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    await ClockCycles(dut.mclkin, 5)
    dut.rst.value = 0
    await ClockCycles(dut.mclkin, 5)
    
    dut.write_enable.value = 0
    dut.sync_pulse.value = 0
    dut.tx_ready.value = 0
    
    test_data = [i*100 + 500 for i in range(ADC_COUNT)]
    dut.data_adc_0.value = test_data[0]
    dut.data_adc_1.value = test_data[1]
    dut.data_adc_2.value = test_data[2]
    dut.data_adc_3.value = test_data[3]
    dut.data_adc_4.value = test_data[4]
    dut.data_adc_5.value = test_data[5]
    dut.write_enable.value = 1
    await ClockCycles(dut.mclkin, 1)
    dut.write_enable.value = 0
    

    dut.sync_pulse.value = 1
    await ClockCycles(dut.mclkin, 1)
    dut.sync_pulse.value = 0
    
    await ClockCycles(dut.mclkin, 1)
    
    for i in range(12):
        dut.tx_ready.value = 1
        await ClockCycles(dut.mclkin, 2)
        dut.tx_ready.value = 0
        await ClockCycles(dut.mclkin, 5)




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
