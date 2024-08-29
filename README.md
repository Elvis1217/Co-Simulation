# Co-Simulation
Imperial College London Dissertation Used Cases

In this project, a co-simulation communication interface based on Matlab/Simulink is designed. The interface uses the TCP/IP protocol to transmit signals over LAN and WAN. Independent simulation models can then be connected through the interface to facilitate co-simulation by multiple parties without disclosing proprietary models. The interface was tested using a grid-connected inverter model and a 116-bus transmission line model, and simulation results were recorded for both LAN and cross-grid communication. To improve the simulation efficiency, the project also explores the combination of parallel simulation and co-simulation.

1) The simulation framework of the grid-connected inverter model as：
![0000003](https://github.com/user-attachments/assets/9d57ea3d-8e00-4b15-b4a8-ed295ee53fbf)

The original model used for the grid-connected inverter co-simulation is provided by the Matlab test case, which can be accessed by visiting the link: [https://uk.mathworks.com/help/sps/ug/grid-tied-inverter-current-control.html](https://uk.mathworks.com/help/sps/ug/grid-tied-inverter-current-control.html)

The controller of the inverter (GridTiedInverterOptimalI_2023_SS) and the rest of the circuit (GridTiedInverterOptimalI_2024_SS) are separated into two submodels in this project. To test this co-simulation, you can install Matlab 2023b & 2024a in one computer and open the sub-models in both Matlabs and make sure that the corresponding interface files (Server4 and Client4, respectively) are present in the current path of the editor. To perform co-simulation, you must first run the server-side submodel (GridTiedInverterOptimalI_2023_SS). Once the "Initializing TCP server..." message appears in the diagnostic viewer window, you can then run the client-side submodel (GridTiedInverterOptimalI_2024_SS). If the connection is successfully established, you can then see the string data transferred over the interface in the Diagnostic Viewer window.

In addition, if you start the model again and find that the model section reports an error about missing initial variables, you can first run it using a command line window: openExample('simscapeelectrical/GridTiedInverterOptimalIExample'). The reason for this error is that Matlab did not find the default corresponding file in the case library, which may be related to the storage path set when downloading Matlab.



2) The simulation framework of the 116bus grid transmission model as：
![000001](https://github.com/user-attachments/assets/e7be7056-57a9-4add-a883-10890ecd9fa5)

The original model of 29-bus system can be accessed by visiting the link: [https://uk.mathworks.com/help/sps/ug/grid-tied-inverter-current-control.html
](https://uk.mathworks.com/help/sps/ug/initializing-a-29-bus-7-power-plant-network-with-the-load-flow-tool-of-powergui.html)
This 116bus power system is actually a combination of four 29bus systems.

Prior to co-simulating the 116bus power system, I strongly recommend that you first try co-simulation using the contents of 'LoadFlow58BusNetwork'. This folder contains two 29bus power systems, and by decoupling the directly connected transmission lines and using a single communication interface, we can enable the interaction of three-phase current and voltage signals. The co-simulation is built in the same way as in the case of the grid-connected inverter, the Server terminal model 'LoadFlow58BusNetwork_2023.slx' must be started first, and then the Client terminal model ' LoadFlow58BusNetwork_2024.slx'. Make sure that the current paths of the editors in both Matlabs include 'Server5' and 'Client5' respectively.

After successfully establishing the co-simulation for the 58-bus case, you can view the contents of 'LoadFlow116BusNetwork.' The 116-bus system has been divided into four submodels: 'Sub1,' 'Sub2,' 'Sub3,' and 'Sub4.' Sub1 and Sub4 run on one computer (or in one instance of MATLAB), while Sub2 and Sub3 run on another computer. To avoid confusion, the MATLAB version associated with Sub2 and Sub3 is set to 2023. The simulation structure is illustrated in the framework diagram. To ensure the connections are properly established, you must create a function to simultaneously launch the two submodels running in parallel on the same computer. Alternatively, you can use 'SimulationApp.m,' a parallel simulation program I created. Simply select the appropriate files, run the program, and it will automatically create the parallel pool. We designate the computer running Sub1 and Sub4 as the server, and the computer running Sub2 and Sub3 as the client. During the simulation, first, start Sub1 and Sub4, then wait for the server to enter the listening state. After that, start the client-side programs (Sub2 and Sub3) to successfully establish the connection.

3) Co-simulation APP
![image](https://github.com/user-attachments/assets/6b8ef3e7-7d92-4c73-b4a5-913b321a7903)

The application was built to perform parallel simulations quickly, but is still cumbersome to use in practice. In order to create a simulation, you must change the name of the simulation file set in the app, e.g. 'Sub1', so that it corresponds to the name of the model. In order to get the simulation results, you have to make sure that the Scope in the corresponding model has been set to output the results to the workspace, and change the name of the function grabbed in the app to the name of the corresponding data, e.g. app.SimulationResults.(modelName).SM_speeds = simOut.get('SM_speeds '); If you find it more cumbersome to obtain images, you may wish to view them directly from Scope. The main purpose of the app is also to make the sub-models of the parallel simulation start running at the same time after the initialization is completed, in order to prevent the transferred data from being misaligned due to the different initialization times. Of course, you can also use Simulink's own data checker to better analyze the error between the simulation results and the original model results (located in the upper right corner of the Simulink interface, you need to run the original model once, then run the simulation again, and then start the data checker to retrieve the required curves)

4) All recorded simulation images from the test can be found in the Appendix of the Co-Simulation MSc Report.
