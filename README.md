# 🔨 Digital Auction System (VHDL / FPGA)

A modular, real-time digital auction control system implemented in **VHDL-2008** on the **Digilent Nexys A7 FPGA** board using **Xilinx Vivado**. The architecture features a central Finite State Machine (FSM), debounced push-button inputs, priority bidding evaluation, status LED controllers, and dynamic Seven-Segment display multiplexing.

---

## 📌 Project Overview
Digital auction systems require strict timing, low-latency input handling, and transparent state management to evaluate concurrent bids accurately. This system models a multi-participant auction environment directly in hardware, maintaining state synchrony, countdown tracking, and real-time bid validation.

### Key Features
- **Deterministic FSM Controller (`auction_fsm.vhd`):** Manages operational cycles including system idle, active bidding, bid incrementing, count validation, and winner determination.
- **Hardware Debouncing & Edge Detection (`edge_detect.vhd`):** Filters mechanical contact bounce on push-buttons to guarantee single-pulse trigger inputs.
- **Dynamic 7-Segment Display Multiplexer (`display_mux.vhd`):** Time-multiplexes numerical values across multi-digit displays for real-time bid price tracking.
- **Visual Status Controller (`led_ctrl.vhd`):** Drives onboard LEDs to reflect continuous auction states and error conditions.
- **Modular Package (`auction_pkg.vhd`):** Encapsulates shared custom data types, system constants, and utility functions.

---

## 🛠️ System Architecture & VHDL Modules

```text
                        ┌─────────────────────────┐
                        │      auction_top        │
                        └────────────┬────────────┘
                                     │
    ┌────────────────┬───────────────┼───────────────┬────────────────┐
    │                │               │               │                │
┌───┴────────────┐ ┌─┴──────────┐ ┌──┴───────────┐ ┌─┴───────────┐ ┌──┴──────────┐
│  edge_detect   │ │auction_fsm │ │ display_mux  │ │  led_ctrl   │ │auction_pkg │
│ (Button Sync)  │ │(FSM Logic) │ │ (7-Segment)  │ │(LED Status) │ │ (Types/Package)│
└────────────────┘ └────────────┘ └──────────────┘ └─────────────┘ └────────────┘
```

### Module Breakdown
- **`auction_top.vhd`**: Top-level entity instantiating and interconnecting logic blocks with physical FPGA I/O ports.
- **`auction_fsm.vhd`**: Core state machine executing main operational rules and bid validations.
- **`edge_detect.vhd`**: Edge detection circuit mapping asynchronous button inputs to single system clock pulses.
- **`display_mux.vhd`**: Refresh multiplexer driving multi-digit 7-segment display arrays.
- **`led_ctrl.vhd`**: Logic mapping current state flags to status LEDs.
- **`auction_pkg.vhd`**: Shared package containing global constants, array types, and parameter definitions.

---

## 📂 Repository Structure

```text
nexys-a7-auction-system/
├── project_final.srcs/
│   ├── sources_1/new/         # VHDL Source Files
│   │   ├── auction_top.vhd
│   │   ├── auction_fsm.vhd
│   │   ├── edge_detect.vhd
│   │   ├── display_mux.vhd
│   │   ├── led_ctrl.vhd
│   │   └── auction_pkg.vhd
│   └── constrs_1/new/         # Physical Constraints
│       └── xdc_final.xdc
├── project_final.xpr          # Vivado Project File
└── README.md                  # Project Documentation
```

---

## 💻 Building & Deployment

### Development Environment
- **EDA Tool:** Xilinx Vivado Design Suite
- **Target Hardware:** Digilent Nexys A7 FPGA (Artix-7 XC7A100T)
- **HDL Language:** VHDL

### Steps to Build
1. Open **Xilinx Vivado**.
2. Select **Open Project** and navigate to `project_final.xpr`.
3. Run **Synthesis** (`Run Synthesis` or `Ctrl + Shift + R`).
4. Run **Implementation** (`Run Implementation`).
5. Click **Generate Bitstream** to produce the hardware executable file (`.bit`).
6. Connect the Nexys A7 FPGA board via USB and program it using **Hardware Manager**.

---

## 📸 Demo & Hardware Results

<p align="center">
  <img src="https://github.com/user-attachments/assets/4f2d3c9b-9fb4-4964-af36-3395dab2aaf7" alt="Nexys A7 Auction Demo" width="600"/>
  <br/>
  <i>Figure 1: Digital Auction System running on Digilent Nexys A7 FPGA.</i>
</p>

---

## 👨‍💻 Author

**Goravit Promvaree**
* **Education:** B.Eng. in Computer Engineering, Khon Kaen University
* **Email:** [goravit.p@kkumail.com](mailto:goravit.p@kkumail.com)
* **GitHub:** [@goravit-p](https://github.com/goravit-p)
