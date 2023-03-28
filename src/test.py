import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

@cocotb.test()
async def run_smoke_test(dut):
    dut._log.info("start")

    period = 1000    
    units  = "ns"

    dut.dclk_period.value = int(period)

    dut.go.value = 0

    dut.record_vcd.value = 1
    dut.run_smoke_test.value = 1
    dut.run_measurement.value = 1
    dut.run_show_status.value = 1

    clock = Clock(dut.dclk, period, units=units)
    cocotb.start_soon(clock.start())

    dut.go.value = 1
    await ClockCycles(dut.dclk, 1)

    dut._log.info("pass {}".format(dut.pass_flag.value))
    assert 0 == dut.pass_flag.value

    await ClockCycles(dut.dclk, 10)
    if dut.run_measurement.value:
        await ClockCycles(dut.dclk, 100)
 

    dut._log.info("pass {}".format(dut.pass_flag.value))
    assert 1 == dut.pass_flag.value
