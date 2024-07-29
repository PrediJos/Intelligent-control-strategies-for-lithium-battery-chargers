%% Inicializacion de Matlab
clc, clear
Ts = 1e-6;

%% Modelo Simulink
open("RL_TF_SS.slx")

%% Creacion de entorno
% Observation info
obsInfo = rlNumericSpec([4 1]);
obsInfo.LowerLimit = [-inf 0 0 0]';
obsInfo.UpperLimit = [inf 12 12 10]';
obsInfo.Name = "Observations";
obsInfo.Description = "Error Voltage SetPoint Control";

% Actions Info
actInfo = rlNumericSpec([1 1]);
actInfo.LowerLimit = 0;
actInfo.UpperLimit = 10;
actInfo.Name = "Voltage";

% Create environment object
env = rlSimulinkEnv("RL_TF_SS", "RL_TF_SS/RL_Charger", obsInfo, actInfo);
env.ResetFcn = @(in)LclRstFcn_1(in);
rng(0)

%% Critic
criticNet = [
    featureInputLayer(prod(obsInfo.Dimension))
    fullyConnectedLayer(5)
    reluLayer
    fullyConnectedLayer(10)
    reluLayer
    fullyConnectedLayer(15)
    reluLayer
    fullyConnectedLayer(20)
    reluLayer
    fullyConnectedLayer(1)
    ];

criticNet = dlnetwork(criticNet);
summary(criticNet)

critic = rlValueFunction(criticNet, obsInfo);
getValue(critic, {rand(obsInfo.Dimension)})

%% Actor
% Input path
inPath = [ 
    featureInputLayer(prod(obsInfo.Dimension), Name="netObsIn")
    fullyConnectedLayer(prod(actInfo.Dimension), Name="infc")
    ];

% Mean value path
meanPath = [ 
    tanhLayer(Name="tanhMean")
    fullyConnectedLayer(10)
    reluLayer
    fullyConnectedLayer(5)
    reluLayer
    fullyConnectedLayer(prod(actInfo.Dimension))
    scalingLayer( ...
    Name="netMout", ...
    Scale=actInfo.UpperLimit)
    ];

% Standard deviation path
sdevPath = [ 
    tanhLayer(Name="tanhStdv")
    fullyConnectedLayer(10)
    reluLayer
    fullyConnectedLayer(5)
    reluLayer
    fullyConnectedLayer(prod(actInfo.Dimension))
    softplusLayer(Name="netSDout")
    ];

% Add layers to network object
actorNet = layerGraph;
actorNet = addLayers(actorNet, inPath);
actorNet = addLayers(actorNet, meanPath);
actorNet = addLayers(actorNet, sdevPath);

% Connect layers
actorNet = connectLayers(actorNet, "infc", "tanhMean/in");
actorNet = connectLayers(actorNet, "infc", "tanhStdv/in");

actorNet = dlnetwork(actorNet);
summary(actorNet)

actor = rlContinuousGaussianActor(actorNet, obsInfo, actInfo, ...
    ActionMeanOutputNames="netMout",...
    ActionStandardDeviationOutputNames="netSDout",...
    ObservationInputNames="netObsIn");

getAction(actor, {rand(obsInfo.Dimension)})

%% Creacion de agente
agent = rlACAgent(actor, critic);
agent.SampleTime = Ts;

agent.AgentOptions.NumStepsToLookAhead = 32;
agent.AgentOptions.DiscountFactor = 0.99; % Ajuste del factor de descuento

agent.AgentOptions.CriticOptimizerOptions.LearnRate = 10e-3; % Ajuste de la tasa de aprendizaje
agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;

agent.AgentOptions.ActorOptimizerOptions.LearnRate = 10e-3; % Ajuste de la tasa de aprendizaje
agent.AgentOptions.ActorOptimizerOptions.GradientThreshold = 1;
%% Entrenamiento
trainOpts = rlTrainingOptions(...
    MaxEpisodes = 206, ...
    MaxStepsPerEpisode = 200, ...
    ScoreAveragingWindowLength = 20, ...
    Verbose = true, ...
    Plots = "training-progress", ...
    StopTrainingCriteria = "AverageReward", ...
    StopTrainingValue = 10000);

trainingStats = train(agent, env, trainOpts);