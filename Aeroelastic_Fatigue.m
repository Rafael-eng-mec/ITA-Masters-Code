%% Script Matlab - Fatigue Calc: Aeroelastic Post Buckling Panel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: Rafael da Silva Alves
%
% SUBJECT:
% Aeronautical Panel in supersonic flow under post-buckling regime due to
% aeroelastic effects
%
% OBECTIVE:
% Obtain the fatigue life of an aeronautical panel structure reinforced
% with lateral stiffeners due to the combined effect of post buckling
% modeled by Non Linear geometrical FEM along with pressure loads from
% supersonic flow (M> 1,2) modeled by the First Order Piston Theory 
%
% Input data:
% a) Material properties
% b) Stress: Matrix with Stress values from FEM Results
% c) Time of the Stress sample event
% d) Estimated life in hours
%
% Output Data:
% a) Fatigue History graph
% b) Fatigue life 1 Cycle
% c) Fatigue work hours to failure
% d) Fatigue Margin of Safety (MS) in % for target life
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc
close all

%--------------------------------------------------------------------------
%% a) Read Stress History from FEM in Excel file

% ========================== MATERIAL DATA ================================
Mat = 'Aluminum 2024-T4';
s_u = 476; %[MPa] - Rupture limit
s_fb = 631; %[MPa] - Real fracture stress limit (according to Dowling)
A_fat = 839; %[MPa] - A parameter of S-N curve (according to Dowling)
B_fat = -0.102; % B parameter of S-N curve (segundo Dowling)
Kt = 2.3; % Stress geometric intensity factor
% =========================================================================

% ========================= STRESS HISTORY ================================
% Excel file must contain only 1 column with stress history
Stress = xlsread("Stress_History.xlsx");
Sigma = Stress.*Kt; % Stress with concentration factor
% =========================================================================

% ======================= FATIGUE PARAMETERS ==============================
ti = 0; % [s] Initial sample time
tf = 2; % [s] Final sample time
life = 8000; % [h] Fatigue Lifetime expected in hours
B_cycles = life*60*60/(tf-ti); % Number of cycle repetitions for life in h
% =========================================================================

%--------------------------------------------------------------------------
%% b) Calculate High Cycle Fatigue

% - Zero average equivalent stress method: GOODMAN
% - Count of cycles by rainflow method
% - Cumulative damage calculated using the Palmgren Miner method

dfile ='Non_Linear_Fatigue_Results.txt';
if exist(dfile, 'file') ; delete(dfile); end
diary(dfile)
diary on

diary('Non_Linear_Fatigue_Results.txt')
diary on

fprintf('Material = %s \n\n',Mat);
fprintf('Geometric Kt = %3.1f \n\n',Kt);

% Reduce stress history in cycle count
diary off

% Rainflow Classification ["Nj" "Sa" "Sm"];
[cycles,rm,rmr,rmm] = rainflow(Sigma);

Nj = cycles(:,1);
Sa = cycles(:,2)./2;
Sm = cycles(:,3);

header = {'Nj', 'Sa', 'Sm'};
fat_show = array2table(sortrows([Nj,Sa,Sm],2,'descend'),'VariableNames',header)
fat = table2array(fat_show);

% Rainflow Plots
fig = figure(100);
fig.Position = [488 201.8000 661.8000 560.2000];

subplot(2,1,1);
plot(Sigma,'r')
hold all
title('Fatigue Spectrum')
xlabel('Counts')
ylabel('Stress [MPa]')

subplot(2,1,2);
histogram2(Sa,Sm,[round(min(Sa)):1:round(max(Sa))],[round(min(Sm)):1:round(max(Sm))],'FaceColor','flat')
colorbar
title('Fatigue Rainflow')
xp = xlabel('Alternated Stress - Sa [MPa]');
%xp.Position = [70 -110 30]
%xp.Rotation = 10
yp = ylabel('Mean Stress - Sm [MPa]');
%yp.Position = [0 0 25]
%yp.Rotation = -15
zlabel('Occurence Number')

saveas(fig,'Fatigue_History.png')

diary on
fprintf('    Nj         Sa         Sm\n');
table = [Nj Sa Sm];
fprintf('%8.2f   %8.2f   %8.2f \n',table');

% Calculate S_ar for each event
S_ar = Sa./(1-(Sm./s_u));

% Calculate Nfj in S-N curve
Nfj = (S_ar./A_fat).^(1/B_fat);

Nj_Nfj = Nj./Nfj;


% ---------------- OUTPUT VALUES OF THE FINAL PROCESS: -------------------

% Maximum number of repetitions:
B_rep = 1/sum(Nj_Nfj);
hours = (B_rep*(tf-ti))/(60*60);

% Accumulated damage for 1 replay
c_1 = sum(Nj_Nfj);

% Accumulated damage for B_ cycle repetitions
c_B = c_1*B_cycles;

% MArgin of Safety
MS_fat = ((1/c_B)-1)*100;

fprintf('=======================================================\n\n');
fprintf('          RESULT OF NONLINEAR FATIGUE ANALYSIS         \n');
fprintf('           Expected service life = %3.0f h             \n\n',life);
fprintf('-------------------------------------------------------\n\n\n')

if B_rep > 100000*B_cycles
fprintf(' Number of cycle repetitions = Infinite                \n\n');    
else
fprintf(' Number of cycle repetitions = %3.0f                   \n\n',B_rep);    
end

if hours > 8e10
fprintf(' Total hours until failure = Infinite                  \n\n');
else
fprintf(' Total hours until failure = %3.1f h                   \n\n',hours);    
end

if c_1 < 0.0001
fprintf(' Accumulated damage from 1 cycle fatigue = %3.2e       \n\n',c_1);
else
fprintf(' Accumulated damage from 1 cycle fatigue = %3.6f       \n\n',c_1);    
end

if c_B < 0.0001
fprintf(' Accumulated fatigue damage for %3.0f h = %3.2e         \n\n',life,c_B);
else
fprintf(' Acumulated fatigue damage for %3.0f h = %3.6f        \n\n',life,c_B);    
end

if MS_fat > 1000
fprintf(' Fatigue Safety Margin for %3.0f h > 1000%%            \n\n\n',life);    
elseif MS_fat > -1000
fprintf(' Fatigue Safety Margin for %3.0f h = %3.0f%%           \n\n\n',life,MS_fat);        
else
fprintf(' Fatigue Safety Margin for %3.0f h < -1000%%           \n\n\n',life)    
end

fprintf('=======================================================\n\n\n');

diary off

%--------------------------------------------------------------------------