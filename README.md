# Logic Lab Final Project – FPGA Smart Workout Timer

**Course:** Logic Circuits Laboratory  
**Term:** Spring 2025  
**Assignment Type:** Final Project (GitHub Classroom)

---

## 📌 Project Description
This project implements a **smart workout timing system** on an FPGA using **Verilog HDL**.  
The system calculates the required workout duration based on user parameters and controls exercise/rest cycles using a **finite state machine (FSM)**.

The design strictly follows **structural modeling constraints** for combinational logic and is fully synthesizable.

---

## 🎯 Learning Objectives
- Design combinational circuits without using multiplication/division operators
- Implement FSM-based timing control
- Practice modular Verilog design
- Perform simulation, synthesis, and FPGA implementation
- Work with real hardware I/O (7-segment display, buttons, buzzer)

---

## 🧮 Workout Time Calculation
The total workout time is calculated using:

T = (Cal × 60) / (MET × W × G)

Where:
- `Cal` ∈ {50, 100, 150, 200}
- `W` ∈ {50–120} kg
- `MET` ∈ {1, 2, 4, 8}
- `G = 1` (Male), `G = 1.125` (Female)

> ⚠️ Multiplication and division operators are **not used** in Verilog implementation.

---

## 🧩 System Architecture
### 1. Combinational Unit
- Computes total workout duration
- Implemented using:
  - Lookup tables
  - Shifts
  - Multiplexers
  - Adders

### 2. Control Unit (FSM)
- Controls workout flow:
  - Exercise (45s)
  - Rest (15s)
- Handles user inputs:
  - `Start`
  - `Skip`
  - `Reset`

---

## 🎛️ Inputs & Outputs

### Inputs
- Switches: Weight, Calories, MET, Gender
- Buttons: Start, Skip, Reset
- Clock: 40 MHz

### Outputs
- 4-digit 7-segment display
- Buzzer (exercise / finish alerts)
- Finish signal

---

## 🧪 Simulation
- Testbench reads input vectors from `input.txt`
- Output results written to `output.txt`
- Tested using:
  - ISIM
  - ModelSim

---

## 📁 Repository Structure
.
├── src/ # Verilog source files
├── sim/ # Testbench and test vectors
├── report/ # Project report (PDF)
└── README.md

yaml
Copy code

---

## 🛠️ How to Build & Simulate
1. Open the project in your FPGA tool (ISE / Vivado)
2. Add all files from `src/`
3. Run simulation using files in `sim/`
4. Synthesize and implement on FPGA board

---

## 📜 Academic Integrity
This repository is submitted through **GitHub Classroom**.  
Any form of plagiarism or code sharing outside the team violates course policy.

---

## 👥 Team Members
| Name | last name |
|-----|------------|
| Amin    | Agahifard           |
|   Ali  |    Johari        |

---

## ✅ Submission Checklist
- [ ] All Verilog files compile without errors
- [ ] Testbench included
- [ ] Report uploaded as PDF
- [ ] README completed
