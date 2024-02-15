%% Convert spikes detected by ExtractOEphys.py data to NLX .ntt file
% This function converts an OEphys .spikes file to a NLX .ntt file.
% The output file has the same name as the input file

%INPUTS:
%InPath: path with OEphys .spikes file. E.g. 'M:\Leemburg\OEphysTEST';
%InFile: filename of .mat file E.g. 'TT5.mat';
%OutPath: path where .ntt file will be stored
%Fs: sampling rate in Hz
%addScFac: option for setting a scaling factor for the waveforms. Set to 0
%to use original scaling, set to 1 to use automatic scaling (maximum spike
%amplitude will be set to 20000 and everything else will be multiplied
%accordingly).

%requires LoadTT_openephys.m (from OpenEphys analysis tools).
%Our is found here: M:\$spoluprace\JEZEK LAB\DATA\work\OEPhys\analysis-tools-master

%requires Mat2NlxSpike.mexw32 or Mat2NlxSpike.mexw64 Version 6.0.0 (from Neuralynx, details see Mat2NlxSpike.m).

%made by Susan


function [InFile,Spikes,Features,Timestamps, ScFac, Fs] = OEPhysPyMat2NTT_v2(InPath,InFile,OutPath, Fs,addScFac)
%% load spike file
disp('loading spikes')
load([InPath,'/',InFile],'Spikes','Timestamps');

%% convert to correct formats
%Fs = 30000; %sampling rate
microsamp = (10^6)/Fs; %microsecond per sample
Timestamps = Timestamps*microsamp; %convert to microseconds
Timestamps = double(Timestamps);
numspikes = numel(Timestamps);

Spikes = double(Spikes); % convert to doubleif Spikes and Timestamps are not double, everything BSODs.
Spikes = -Spikes; %flip waveforms

%%
if addScFac == 1
    
    maxval = max(max(max((Spikes))));
    ScFac = 25000/maxval;
    ScFac = round(ScFac);
    
    Spikes = Spikes*ScFac;
    
else
    ScFac = 1;
end

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
FieldSelectionFlags = [1,1,1,1,1,0];


ScNumbers = zeros(1,numspikes); %set to 0 (cheetah also does this)
CellNumbers = ScNumbers; %all cells in cluster 0

Features = nan(8,numspikes);
for s = 1:numspikes
    Features(1:4,s) = max(Spikes(:,:,s),[],1);
    Features(5:8,s) = min(Spikes(:,:,s),[],1);
end

%%
disp(['exporting to ', OutPath])
Mat2NlxSpike(NTTname, AppendToFileFlag, ExportMode, [], FieldSelectionFlags, Timestamps, ScNumbers, CellNumbers, Features, Spikes)

disp(['created ',[OutPath,'\',Outname{1}],'.ntt'])

end
