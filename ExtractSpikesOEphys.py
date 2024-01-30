# -*- coding: utf-8 -*-
import spikeinterface.extractors as se
import numpy as np
from probeinterface import read_prb
from spikeinterface.sortingcomponents.peak_detection import detect_peaks
from spikeinterface.preprocessing import bandpass_filter
from scipy.io import savemat
from tqdm import tqdm


InFolder = "C:/Users/susan/Desktop/2023-06-04_13-47-08"
OutFolder = "C:/Users/susan/Desktop/klustatest"
Probepath ="C:/Users/susan/Desktop/klustatest"
ChanList = 'KKtetlist2.txt' # text file listing good and bad channels
TetList = [1,2,3] #analyse only these tetrodes (1-based, as on drive)

spike_thresh = 5 # detection threshold for spike detection is spike_thresh* signal SD
spike_sign = 'neg' #detect negative peaks only. can be: 'neg', 'pos', 'both'

################################################################################################
# assign channel numbers, group by tetrode
tetgrouping = np.array([1,1,1,1,2,2,2,2,3,3,3,
               3,4,4,4,4,5,5,5,5,6,6,6,
               6,7,7,7,7,8,8,8,8])

# read bad channel list, set bad channels to 17
tetlist = np.loadtxt(InFolder + '/' + ChanList,
                 delimiter=",")

for tetnum in range(16):
        thistet = np.where(tetgrouping==tetnum)
        thistet = np.array(thistet)
        thesewires = tetlist[tetnum,1:5]
        badwires = np.where(thesewires==0)
        badwires = np.array(badwires)
        badchans = thistet[0][badwires]
        tetgrouping[badchans]=17
 
# read recfile, add grouping labels
MyRec = se.OpenEphysLegacyRecordingExtractor (InFolder)
MyRec.set_channel_groups(channel_ids = MyRec.get_channel_ids(),groups = tetgrouping)
all_chan_ids = MyRec.get_channel_ids()

# select a tetrode
for tetnum in TetList:

    tet_chan_ids = all_chan_ids[np.where(tetgrouping == tetnum-1)]

    if np.size(tet_chan_ids)>2:
        
        # 4-wire tetrode
        if np.size(tet_chan_ids) == 4:
           new_chans = [0,1,2,3]
           probename = "tet4_probe.prb"
        
        # 3-wire tetrode
        if np.size(tet_chan_ids) == 3:
            new_chans = [0,1,2]
            probename = "tet3_probe.prb"
        
    myprobe = read_prb(Probepath + "/" + probename)

    #select channels and add probe
    thistet = MyRec.channel_slice(tet_chan_ids, renamed_channel_ids=new_chans)
    thistet = thistet.set_probegroup(myprobe)

    # preprocess (filter)
    thistet_f = bandpass_filter(thistet, freq_min=600, freq_max=6000)

    #detect peaks
    detectradius = 30 #tetrode map is 10x10um square, thsi should capture all spikes in this channelgroup
    TetPeaks = detect_peaks(thistet_f, method='locally_exclusive', pipeline_nodes=None, gather_mode='memory', folder=None, names=None,
                            peak_sign=spike_sign, detect_threshold=spike_thresh, exclude_sweep_ms=0.1, radius_um=detectradius)

    # get waveforms. must be 32 samples long, I'm setting peak at sample 8 (same as NLX)
    prepeak = 8
    postpeak = 24

    print('extracting waveforms')

    allWFs = np.zeros([32, 4, len(TetPeaks['sample_index'])], dtype='int16')
    for p in tqdm(range(len(TetPeaks['sample_index'])), desc="collecting waveforms"):
        sf = TetPeaks['sample_index'][p] - prepeak
        ef = TetPeaks['sample_index'][p] + postpeak

        thisWF = thistet_f.get_traces(segment_index=None, start_frame=sf, end_frame=ef)

        #write only complete spike waveforms (might skip last spike if too short)
        if np.size(thisWF, 0) == 32:
           allWFs[:, :, p] = thisWF

        del thisWF

   #save peaks to mat file (for later processing with Mat2NlxSpike to generate .ntt file)
    print('saving to mat file')
    outname = OutFolder+"tt"+str(thistet) + '.mat'
    savemat(outname, {"Timestamps":TetPeaks['sample_index'], "Spikes": allWFs})
