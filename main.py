import marimo

__generated_with = "0.23.9"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import chipwhisperer as cw
    from chipwhisperer.hardware.naeusb.programmer_targetfpga import LatticeICE40
    import time

    return LatticeICE40, cw, time


@app.cell
def _(cw, time):
    scope = cw.scope()
    if not scope._is_husky:
        raise TypeError("Scope is not ChipWhisperer-Husky")

    scope.default_setup()
    scope.adc.samples = 80
    scope.adc.offset = 0
    scope.adc.basic_mode = "rising_edge"
    scope.trigger.triggers = "tio4"
    scope.io.tio1 = "serial_rx"
    scope.io.tio2 = "serial_tx"
    scope.io.hs2 = 'clkgen'
    scope.gain.db = 50
    scope.clock.clkgen_freq = 7372800 # 7.3728 MHz
    scope.clock.clkgen_src = 'system'
    scope.clock.adc_mul = 4
    scope.clock.reset_dcms()

    target = cw.target(scope, cw.targets.SimpleSerial)

    for i in range(5):
        scope.clock.reset_adc()
        time.sleep(1)
        if scope.clock.adc_locked:
            break
    assert scope.clock.adc_locked, "ADC failed to lock"
    return scope, target


@app.cell
def _(LatticeICE40, scope, target):
    fpga = LatticeICE40(scope)
    fpga.erase_and_init()
    fpga.program("build/module.bin", sck_speed=20e6, use_fast_usb=True, start=True)
    print("Bitstream flashed")

    test_cases = [0x00, 0xFF, 0xAA, 0x55, 0x12, 0xF0]
    rows = []
    for byte_in in test_cases:
        expected = (~byte_in) & 0xFF
        target.simpleserial_write('n', bytearray([byte_in]))
    
        response = target.simpleserial_read('o', 1, ack=False)
        byte_out = int.from_bytes(response)
        print(f"IN: {byte_in:02X}, OUT: {byte_out:02X}, EXPECTED: {expected:02X}, {"PASSED" if (expected == byte_out) else "FAILED"}")
    return


if __name__ == "__main__":
    app.run()
