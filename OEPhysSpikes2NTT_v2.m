%% Convert OpenEphys TT data to NLX .ntt file
% This function converts an OEphys .spikes file to a NLX .ntt file.
% The output file has the same name as the input file, but with any periods
% replaced with underscores (e.g. TTp110.0n2.spikes is stored as
% TTp110_0n2.ntt)

%INPUTS:
%InPath: path with OEphys .spikes file. E.g. 'M:\Leemburg\OEphysTEST\2024-01-11_11-59-42\Record Node 112';
%InFile: full filename of OEphys .spikes file E.g. 'TTp110.0n2.spikes';
%wv_plot: set to 1 to plot 500 waveforms from the loaded file, set to 0 to
%skip that.
%spk_plot: set to 1 to plot 500 spike-peak scatter plots from the loaded file, set to 0 to
%skip that.
%OutPath: path where .ntt file will be stored
%addScFac: set to 1 to use aut-scaling of waveforms, set to 0 to skip that

%requires load_open_ephys_data.m (from OpenEphys analysis tools).
%Our is found here: M:\$spoluprace\JEZEK LAB\DATA\work\OEPhys\analysis-tools-master

%requires Mat2NlxSpike.mexw32 or Mat2NlxSpike.mexw64 Version 6.0.0 (from Neuralynx, details see Mat2NlxSpike.m).

%made by Susan


function [InFile, ScFac,data,Features,timestamps]= OEPhysSpikes2NTT_v2(InPath,InFile,OutPath,wv_plot,spk_plot, addScFac)
%% load spike file
disp('loading spikes')
fn = [InPath,'/',InFile];
[data, timestamps, info] = load_open_ephys_data(fn);

numspikes = numel(timestamps);

%% plot 500 random waveforms from this tetrode (if mkplot is set to 1)


if wv_plot == 1
    numWV = 1000;%numspikes; %change for different number of waveforms in plot
    %WVsToPlot = 1:numspikes;
    WVsToPlot =randperm(size(timestamps,1),numWV);
    
    figure;
    PlotName = strsplit(InFile,'.spikes');
    PlotName = PlotName{1};
    sgtitle(PlotName);
    
    minY = min(min(min(data(WVsToPlot,:,:))));
    maxY = max(max(max(data(WVsToPlot,:,:))));
    for w = 1:4
        subplot(2,2,w)
        plot(1:40,squeeze(data(WVsToPlot,:,w)))
        hold on
        plot([8,8],[minY maxY],'k')
        title(['w ',num2str(w-1)])
        xlim([0 40])
        ylim([minY maxY])
    end
end

%% shorten waveforms, permute matrices
%data = data(:,1:32,:); %.ntt requires waveform of 32pts, not 40, OEPhys: 8 pre-peak and 32 post-peak samples
data = data(:,1:32,:);
data = permute(data,[2,3,1]);

timestamps = timestamps';
timestamps = timestamps*10^6; %convert to microseconds
%% make output filename
Outname = strsplit(InFile,'.');
NTTname = [OutPath,'\',Outname{1},'_',Outname{2},'.ntt'];

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

%% add scaling (or not)

if addScFac == 1
    
    maxval = max(max(max((abs(data)))));
    ScFac = 25000/maxval;
    ScFac = round(ScFac);
    
    data = data*ScFac;
    
else
    ScFac = 1;
end

% Need integers for .ntt waveforms
data = round(data);
data = -data; %invert signal

%
Features = nan(8,numspikes);
for s = 1:numspikes
    Features(1:4,s) = max(data(:,:,s),[],1);
    Features(5:8,s) = min(data(:,:,s),[],1);
end

%% plot spikes scatterplot (peaks only)
if spk_plot ==1
    
    if wv_plot ~=1 %if the waveforms are plotted, use the same spikes for the scatterplot
        numWV = 1000; %change for different number of waveforms in plot
        WVsToPlot =randperm(size(timestamps,1),numWV);
    end
    
    figure;
    PlotName = strsplit(InFile,'.spikes');
    PlotName = PlotName{1};
    sgtitle(PlotName);
    
    maxY = max(max(max(data(:,:,WVsToPlot))));
    subplot(2,3,1)
    plot(Features(1,WVsToPlot),Features(2,WVsToPlot),'.k')
    xlabel('w 0')
    ylabel('w 1')
    xlim([0 maxY])
    ylim([0 maxY])
    
    subplot(2,3,2)
    plot(Features(1,WVsToPlot),Features(3,WVsToPlot),'.k')
    xlabel('w 0')
    ylabel('w 2')
    xlim([0 maxY])
    ylim([0 maxY])
    
    subplot(2,3,3)
    plot(Features(1,WVsToPlot),Features(4,WVsToPlot),'.k')
    xlabel('w 0')
    ylabel('w 3')
    xlim([0 maxY])
    ylim([0 maxY])
    
    subplot(2,3,4)
    plot(Features(2,WVsToPlot),Features(3,WVsToPlot),'.k')
    xlabel('w 1')
    ylabel('w 2')
    xlim([0 maxY])
    ylim([0 maxY])
    
    subplot(2,3,5)
    plot(Features(2,WVsToPlot),Features(4,WVsToPlot),'.k')
    xlabel('w 1')
    ylabel('w 3')
    xlim([0 maxY])
    ylim([0 maxY])
    
    subplot(2,3,6)
    plot(Features(3,WVsToPlot),Features(4,WVsToPlot),'.k')
    xlabel('w 2')
    ylabel('w 3')
    xlim([0 maxY])
    ylim([0 maxY])
end

%%
disp(['exporting to ', OutPath])
Mat2NlxSpike(NTTname, AppendToFileFlag, ExportMode, [], FieldSelectionFlags, timestamps, ScNumbers, CellNumbers, Features, data)

disp(['created ',[OutPath,'\',Outname{1},'_',Outname{2}],'.ntt'])

end
