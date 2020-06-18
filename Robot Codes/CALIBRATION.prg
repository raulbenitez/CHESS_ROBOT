1 '############### CALIBRATION PROCESS ####################
2 '
3 #Include "MAIN"
4 '
5 Function Main
6 '#### Initialise ####
7   MErrStt=VisionActivation()    'Activate the vision sensor
8 '
9 '##### Main Process #####
10   MoveToHOME() 'Move to Home position
11 '
12   Mov PTrg    'Move to Board trigger position
13   Dly 1.0
14   MFPVsTrigger_Board(MVsNum, MVsFound, PVSDATA1, P1, P2, P3, P4)  'Vision trigger
15   MFPTrainVsBaseHndCam(MVsNum, PVSDATA1, PTrg, PBoard)  'Train recognized vision data as a Base data.
16   '
17   'Pick-up the work from place position
18   Mov PBoard,-50
19   Mvs PBoard
20   Fine 0.2, P
21   HClose 1
22   Dly 0.5
23   Mvs PBoard,-50
24 '
25   Hlt
26 '
27 FEnd
28 '
