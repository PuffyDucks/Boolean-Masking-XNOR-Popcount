import marimo

__generated_with = "0.23.9"
app = marimo.App(width="medium")


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    # Correlation Power Analysis on XNOR-Popcount Operations
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ChipWhisperer Husky and ADC Configuration
    """)
    return


@app.cell
def _():
    import numpy as np
    import marimo as mo
    import matplotlib.pyplot as plt
    import time

    def xnor_popcount(a, b):
        return (~(a^b) & 0xFF).bit_count()

    return mo, np, plt, time, xnor_popcount


@app.cell
def _(time):
    import chipwhisperer as cw
    scope = cw.scope()
    if not scope._is_husky:
        raise TypeError("Scope is not ChipWhisperer-Husky")

    scope.default_setup()
    scope.adc.samples = 30
    scope.adc.offset = 0
    scope.adc.basic_mode = "rising_edge"
    scope.trigger.triggers = "tio4"
    scope.io.tio1 = "serial_rx"
    scope.io.tio2 = "serial_tx"
    scope.io.hs2 = 'clkgen'
    scope.gain.db = 15
    scope.clock.clkgen_freq = 7372800 # 7.3728 MHz
    scope.clock.clkgen_src = 'system'
    scope.clock.adc_mul = 4
    scope.clock.reset_dcms()

    target = cw.target(scope, cw.targets.SimpleSerial)

    for _ in range(5):
        scope.clock.reset_adc()
        time.sleep(1)
        if scope.clock.adc_locked:
            break
    assert scope.clock.adc_locked, "ADC failed to lock"
    return scope, target


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ### Bitstream Flashing
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    bitstream_dropdown = mo.ui.dropdown(
        options={
            "No Masking": "build/xnor_popcount_unmasked.bin",
            "Masked XNOR": "build/xnor_popcount_masked_xnor.bin",
            "Full Mask": "build/xnor_popcount_all_masked.bin",
        },
        value="No Masking",
    )
    flash_btn = mo.ui.run_button(label="Flash")
    mo.hstack([bitstream_dropdown, flash_btn], justify="start")
    return bitstream_dropdown, flash_btn


@app.cell
def _(bitstream_dropdown, flash_btn, mo, scope):
    mo.stop(not flash_btn.value)

    from chipwhisperer.hardware.naeusb.programmer_targetfpga import LatticeICE40

    fpga = LatticeICE40(scope)
    fpga.erase_and_init()
    fpga.program(bitstream_dropdown.value, sck_speed=20e6, use_fast_usb=True, start=True)

    mo.md(f"Flashed `{bitstream_dropdown.value}` to `iCE40UP5K`")
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ### Capturing Traces
    """)
    return


@app.cell
def _(expected, mo, np, scope, target, xnor_popcount):
    activations = []
    traces = []
    N = 5000

    secret_w = 0x55

    for _ in mo.status.progress_bar(range(N), subtitle='Collecting trace captures...', 
                                    show_eta=True, show_rate=True):
        a = np.random.randint(0, 256, dtype=np.uint8)

        scope.arm()
        target.simpleserial_write('a', bytearray([a]))
        target.simpleserial_write('w', bytearray([secret_w]))

        ret = scope.capture()
        if ret: raise TimeoutError()

        result = target.simpleserial_read('o', 1, ack=False)
        out = result[0] if result else None
        if (out != xnor_popcount(a, secret_w)):
            raise ValueError(f"Output mismatch for a=0x{a:02X}: got {out}, expected {expected}")

        activations.append(a)
        traces.append(scope.get_last_trace())

    activations = np.array(activations)
    traces = np.array(traces)

    mo.md(f"{N} traces captured.")
    return N, activations, secret_w, traces


@app.cell(hide_code=True)
def _(N, mo):
    slider = mo.ui.slider(start=1, stop=N, label="Trace", value=1, full_width=True)
    return (slider,)


@app.cell(hide_code=True)
def _(N, mo, np, plt, slider, traces):
    trace = traces[slider.value-1]
    xrange = np.arange(len(trace))
    fig, ax = plt.subplots(figsize=(10, 4))
    ax.plot(trace)
    ax.set_xlabel("Sample")
    ax.set_ylabel("ADC Measurement")
    plot = mo.ui.matplotlib(ax)

    mo.vstack([
        mo.md(f"### Power trace {slider.value:04d}/{N}"),
        plot, 
        slider
    ], gap="0.75rem",)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ### Results
    """)
    return


@app.cell
def _(activations, mo, np, secret_w, traces, xnor_popcount):
    corr_coeffs = []
    for w in range(256):
        predictions = [xnor_popcount(a, w) for a in activations]
        trace_means = np.mean(traces, axis=1)
        (_, _), (r, _) = np.corrcoef(predictions, trace_means)
        corr_coeffs.append(r)

    sorted_indices = np.argsort(corr_coeffs)[::-1]
    extracted_w = sorted_indices[0]
    top_1 = secret_w == extracted_w
    top_5 = secret_w in sorted_indices[:5]
    correct_rank = int((sorted_indices == secret_w).argmax()) + 1

    rankings = [
        {
            "Rank": i + 1,
            "Weight (hex)": f"0x{sorted_indices[i]:02X}",
            "Correlation": f"{corr_coeffs[sorted_indices[i]]:.6f}",
            "": "Secret weight" if sorted_indices[i] == secret_w else "",
        } 
        for i in range(256)
    ]

    mo.vstack([
        mo.hstack([
            mo.stat(f"0x{extracted_w:02X}", label="Extracted weight"),
            mo.stat(f"#{correct_rank}", label="Correct weight rank", caption=f"0x{secret_w:02X}"),
            mo.stat("✓" if top_1 else "✗", label="Top-1 match"),
            mo.stat("✓" if top_5 else "✗", label="Top-5 match"),
        ], justify="start", gap="1rem"),
        mo.ui.table(rankings),
    ])
    return


if __name__ == "__main__":
    app.run()
