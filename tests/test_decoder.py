import os
import sys
from pathlib import Path

import cocotb
from cocotb.triggers import Timer
from cocotb.runner import get_runner

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def send_manchester_bit(dut, bit, bit_time):
    """Отправка одного бита в Manchester кодировке"""
    # Manchester: 0 = 01, 1 = 10
    first_half = bit ^ 1  # Инвертируем для первой половины
    second_half = bit     # Прямое значение для второй половины
    
    dut.rx.value = first_half
    await Timer(bit_time // 2, units='ps')
    dut.rx.value = second_half
    await Timer(bit_time // 2, units='ps')

async def send_idle(dut, bit_time, cycles=1):
    """Линия в покое (передаем Manchester-1)"""
    for _ in range(cycles):
        await send_manchester_bit(dut, 1, bit_time)

async def send_manchester_byte(dut, data, bit_time):
    """Отправка байта с Manchester кодировкой"""
    # Перед началом - линия в покое (Manchester-1)
    await send_idle(dut, bit_time, 2)
    
    # Старт бит (0)
    await send_manchester_bit(dut, 0, bit_time)
    
    # 8 бит данных (младший бит первый)
    for i in range(8):
        bit = (data >> i) & 0x1
        await send_manchester_bit(dut, bit, bit_time)
    
    # Стоп бит (1) и возврат в покой
    await send_manchester_bit(dut, 1, bit_time)
    await send_idle(dut, bit_time, 2)

@cocotb.test()
async def simple_test(dut):
    """Простой тест Manchester декодера"""
    
    # Инициализация
    dut.reset.value = 1
    dut.rx.value = 0  # Начинаем с 0 (первая половина Manchester-1)
    dut.rx_ready.value = 0
    
    # Запуск тактовой частоты
    clock = Clock(dut.clk, 52, units='ns')  # 75 MHz
    cocotb.start_soon(clock.start())
    
    # Сброс
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    
    # Параметры
    bit_time = int(1e12 / 115200)  # Время одного бита в пикосекундах
    
    # Перед началом - линия в покое (Manchester-1)
    await send_idle(dut, bit_time, 4)
    
    # Тест 1: Отправка числа 0x55 (01010101)
    await send_manchester_byte(dut, 0x55, bit_time)
    
    # Ждем когда данные станут валидными
    while dut.rx_valid.value != 1:
        await RisingEdge(dut.clk)
    
    # Проверяем полученные данные
    assert dut.rx_data.value == 0x55, f"Ожидалось 0x55, получено {dut.rx_data.value}"
    
    # Подтверждаем прием
    dut.rx_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rx_ready.value = 0
    
    # Линия в покое между сообщениями
    await send_idle(dut, bit_time, 4)
    
    # Тест 2: Отправка числа 0xAA (10101010)
    await send_manchester_byte(dut, 0xAA, bit_time)
    
    while dut.rx_valid.value != 1:
        await RisingEdge(dut.clk)
    
    assert dut.rx_data.value == 0xAA, f"Ожидалось 0xAA, получено {dut.rx_data.value}"
    
    dut.rx_ready.value = 1
    await RisingEdge(dut.clk)
    
  

def test_manch_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "model"))

    if hdl_toplevel_lang == "verilog":
        sources = [proj_path / "rtl" / "decoder_manch.v"]
    build_test_args = []
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "tests"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="decoder_manch",
        always=True,
        build_args=build_test_args,
    )
    runner.test(
        hdl_toplevel="decoder_manch", test_module="test_decoder", test_args=build_test_args
    )


if __name__ == "__main__":
    test_manch_runner()