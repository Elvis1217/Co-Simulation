# Co-Simulation
Imperial College London Dissertation Used Cases

In this project, a co-simulation communication interface based on Matlab/Simulink is designed. The interface uses the TCP/IP protocol to transmit signals over LAN and WAN. Independent simulation models can then be connected through the interface to facilitate co-simulation by multiple parties without disclosing proprietary models. The interface was tested using a grid-connected inverter model and a 116-bus transmission line model, and simulation results were recorded for both LAN and cross-grid communication. To improve the simulation efficiency, the project also explores the combination of parallel simulation and co-simulation.

1) The simulation framework of the grid-connected inverter model as：
![0000003](https://github.com/user-attachments/assets/9d57ea3d-8e00-4b15-b4a8-ed295ee53fbf)

The original model used for the grid-connected inverter co-simulation is provided by the Matlab test case, which can be accessed by visiting the link: https://uk.mathworks.com/help/sps/ug/grid-tied-inverter-current-control.html

The controller of the inverter (GridTiedInverterOptimalI_2023_SS) and the rest of the circuit (GridTiedInverterOptimalI_2024_SS) are separated into two submodels in this project. To test this co-simulation, you can install Matlab 2023b & 2024a in one computer and open the sub-models in both Matlabs and make sure that the corresponding interface files (Server4 and Client4, respectively) are present in the current path of the editor. To perform co-simulation, you must first run the server-side submodel (GridTiedInverterOptimalI_2023_SS). Once the "Initializing TCP server..." message appears in the diagnostic viewer window, you can then run the client-side submodel (GridTiedInverterOptimalI_2024_SS). If the connection is successfully established, you can then see the string data transferred over the interface in the Diagnostic Viewer window.

In addition, if you start the model again and find that the model section reports an error about missing initial variables, you can first run it using a command line window: openExample('simscapeelectrical/GridTiedInverterOptimalIExample'). The reason for this error is that Matlab did not find the default corresponding file in the case library, which may be related to the storage path set when downloading Matlab.



2) The simulation framework of the 116bus grid transmission model as：
![000001](https://github.com/user-attachments/assets/e7be7056-57a9-4add-a883-10890ecd9fa5)
