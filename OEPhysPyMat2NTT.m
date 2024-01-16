%% Convert spikes detected by ExtractOEphys.py data to NLX .ntt file
% This function converts an OEphys .spikes file to a NLX .ntt file.
% The output file has the same name as the input file

%INPUTS:
%InPath: path with OEphys .spikes file. E.g. 'M:\Leemburg\OEphysTEST';
%InFile: filename of .mat file E.g. 'TT5.mat';
%OutPath: path where .ntt file will be stored

%requires LoadTT_openephys.m (from OpenEphys analysis tools).
%Our is found here: M:\$spoluprace\JEZEK LAB\DATA\work\OEPhys\analysis-tools-master

%requires Mat2NlxSpike.mexw32 or Mat2NlxSpike.mexw64 Version 6.0.0 (from Neuralynx, details see Mat2NlxSpike.m).

%made by Susan


function InFile = OEPhysPyMat2NTT(InPath,InFile,OutPath,Header)
%% load spike file
disp('loading spikes')
load([InPath,'/',InFile],'Spikes','Timestamps');

%% convert to correct formats
Timestamps = Timestamps*10^6; %convert to microseconds
Timestamps = double(Timestamps); 
numspikes = numel(Timestamps);

Spikes = double(Spikes); %if Spikes and Timestamps are not double, everything BSODs. 
Spikes = -Spikes; %flip waveforms
%% make output filename
Outname = strsplit(InFile,'.');
NTTname = [OutPath,'\',Outname{1},'.ntt'];

%% make inputs for .ntt file

%BitVolts = 0.19499999284744262695; %from Continuous_Data.openephys

% FieldSelectionFlags(1): Timestamps (1xN vector of timestamps, ascending
% order
% FieldSelectionFlags(2): Spike Channel Numbers
% FieldSelectionFlags(3): Cell Numbers (here: 0, no cells sorted yet)
% FieldSelectionFlags(4): Spike Features (8xN integer vector of features
% from cheetah: peaks for 4 channels and valley for 4 channels.
% FieldSelectionFlags(5): Samples 32x4xN integer matrix with the datapoints
% (waveform) for each spike for all 4 channels.
% FieldSelectionFlags(6): Header

AppendToFileFlag = 0; %new file will be created or old file will be overwritten
ExportMode = 1; %export all
FieldSelectionFlags = [1,1,1,1,1,1];


ScNumbers = zeros(1,numspikes); %set to 0 (cheetah also does this)
CellNumbers = ScNumbers; %all cells in cluster 0

Features = nan(8,numspikes);
for s = 1:numspikes
    Features(1:4,s) = max(Spikes(:,:,s),[],1);
    Features(5:8,s) = min(Spikes(:,:,s),[],1);
end

%%
disp(['exporting to ', OutPath])
Mat2NlxSpike(NTTname, AppendToFileFlag, ExportMode, [], FieldSelectionFlags, Timestamps, ScNumbers, CellNumbers, Features, Spikes, Header)

disp(['created ',[OutPath,'\',Outname{1}],'.ntt'])

end