clc
clear
close all

load 27Rx_Sim_v2.mat
radar_signal = radar_signal';
sensor_loc = 0.01:0.01:0.27;

%% Artificial bee colony optimization

h=waitbar(0,'please wait');
num_sensor = 4;
nNode = 27;
run_time = 10;

SolAll = zeros(run_time,num_sensor);
CostAll = zeros(run_time,1);

for i = 1:run_time
    BestSol = abc(radar_signal,num_sensor,nNode,i);
    % BestSol = abc(radar_signal,num_sensor,nNode,j);
    SolAll(i,:) = BestSol.Position;
    CostAll(i) = BestSol.Cost;
    waitbar(i/run_time,h)

    [loc,idx] = sort(BestSol.Position);
    sensor_loc(loc)
end

delete(h)

fname = sprintf('OptResults/Results_%dSensors.mat', num_sensor);
save(fname,'SolAll','CostAll')

% results = SolAll(:);
% histfit(results,11)
% set(gca,'fontsize',14)
% saveas(gcf,'Histogram_10','fig')
