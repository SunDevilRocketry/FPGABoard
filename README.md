# FPGA Board
ICE40UP5K Accelerated STM based flight computer for data logging, dual deploy, and later hopefully controlls

## Theory
The documentation on the basic operation, theory, and part selections for this board can be found on [this slideshow](https://docs.google.com/presentation/d/1FIGTJVlo11-MBKBVNAReX1bhZ2mO-nYcKgodC_zX_tc/edit?usp=sharing)

## Prerequisites
I reccomend using [Anaconda](https://www.anaconda.com/docs/getting-started/installation) or a similar package manager to run this program, as the python version required for apio is quite old (3.11).

Once you have a conda downloaded, your terminal will appear looking like 
`(base) User/Home`

When you see the base, thats how you know conda is working. Use 
`conda create --name FPGA python=3.11`
to create a conda environment called FPGA using python 3.11. Using a seperate environment isolates the old python version to this environment.

After creating the environment, use 
`conda activate FPGA`
to use the environment. The terminal should now look like 
`(FPGA) User/Home`

Once `(FPGA)` displays, use 
`pip install apio`
to install [apio](https://fpgawars.github.io/apio/docs/). This is currently the only dependency

Once installed, go into the Ice40 folder in VSCode, use Command/Windows + P to "Select Python Interpreter", choose FPGA, and you should be able to use all the essential commands! Basic commands are included in the **Ice40** section of **Structure**

## Structure
### Ice40
Ice 40 contains the basic verilog modules as described in the slideshow. This project utilizes APIO to generate files, compile and sim verilog, and perform general FPGA related functions. 

The _build folder contains APIO generated files neccesary for function

Each subfolder is named by its module, and contains the `.sv` (verilog code) `_tb.sv` (test bench), and `_tb.gtkw`, the gtkwave output from simulating the testbench

#### Modules (`.sv`)
Each module file contains the basic operation and commented functionality of each of the blocks. This is the code we write to get what we want. use 
`apio lint -t [FILENAME]`
inside the Ice40 folder to run the basic linter on the file

#### Testbenches (`_tb.sv`)
Each testbench contains an instantiation and level setting definitions required to test the functionality of the module. use
`apio sim [module/module_tb.sv]` 
when in the Ice40 folder to simulate the testbench. Make sure to lint first to ensure no errors occur prior to simulation. 

#### GTKWave files (`_tb.gtkw`)
These are APIO autogen. Please do not touch them yourself (just run `apio sim` again)

### STM32
(WIP)
Will contain the autogen, drivers, and other essential applications for STM32 functionality

### Altium
(WIP)
Contains the Altium source documents needed for 3D modeling and printing/assembling the board