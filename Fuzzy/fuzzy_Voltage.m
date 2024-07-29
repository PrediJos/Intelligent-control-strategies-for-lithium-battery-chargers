%% FUZZY CONTROLLER
% Inicializacion de matlab
clc, clear
Ts = 1e-6;
%% SUGENO Fuzzy PD
fisPD = sugfis; % tipo de sistema de inferencia sugeno sugfis o mandano manfis
% Input MF -> Funcion de membresia
fisPD = addInput(fisPD,[-100 100],'Name','E'); % Rango del error con una ganancia para amplificar el error

fisPD = addMF(fisPD,'E','trimf',[-100 0 100],'Name','Z'); % funcion de membresia triangular tipo triangular
fisPD = addMF(fisPD,'E','trimf',[0 100 200],'Name','P'); % funcion de membresia triangular tipo triangular
fisPD = addMF(fisPD,'E','trimf',[-200 -100 0],'Name','N'); % funcion de membresia triangular tipo triangular

fisPD = addInput(fisPD,[-100 100],'Name','dE'); % Dos entradas Una salida
fisPD = addMF(fisPD,'dE','trimf',[-100 0 100],'Name','Z');
fisPD = addMF(fisPD,'dE','trimf',[0 100 200],'Name','P');
fisPD = addMF(fisPD,'dE','trimf',[-200 -100 0],'Name','N');

plotmf(fisPD,'input',2)

% Output MF
fisPD = addOutput(fisPD,[0 24],'Name','U');
fisPD = addMF(fisPD,'U','constant',0,'Name','Min');
fisPD = addMF(fisPD,'U','constant',12,'Name','Zero');
fisPD = addMF(fisPD,'U','constant',24,'Name','Max');

% rules

rules = [...
    "E==N && dE==P => U=Zero"; ...
    "E==N && dE==Z => U=Min"; ...
    "E==N && dE==N => U=Min"; ...

    "E==Z && dE==P => U=Max"; ...
    "E==Z && dE==Z => U=Zero"; ...
    "E==Z && dE==N => U=Min"; ...

    "E==P && dE==P => U=Max"; ...
    "E==P && dE==Z => U=Max"; ...
    "E==P && dE==N => U=Zero"; ...
    ];
fisPD = addRule(fisPD,rules);
writeFIS(fisPD,'fisPD.fis')
figure
gensurf(fisPD)
