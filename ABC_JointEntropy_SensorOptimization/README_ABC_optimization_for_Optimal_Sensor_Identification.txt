This code applies information theory together with the Artificial Bee Colony (ABC) optimization algorithm to determine optimal sensor locations for material characterization.
The simulated GPR signals are provided in "27Rx_Sim_v2.mat".

The callable MATLAB functions include:
"abc.m" and "RouletteWheelSelection.m", which are used for the Artificial Bee Colony (ABC) optimization algorithm;
"jointEntropy.m", which is used to calculate joint entropy H(X1, X2, ..., Xd) from multiple signals.

To execute the code, open "main.m" and set the following variables:
num_sensor = 4;              % Number of sensors to be selected
nNode = 27;                  % Total number of candidate sensor locations
sensor_loc = 0.01:0.01:0.27; % Coordinates of candidate sensor locations
run_time = 10;               % Number of independent optimization runs

The output results will be saved in the "OptResults" folder.
The plots of cost versus iteration are saved in the “CostPlots” folder.