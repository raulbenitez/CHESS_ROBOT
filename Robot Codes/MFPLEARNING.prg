1 '##############################################
2 ' DEEP LEARNING FUNCTIONS
3 '##############################################
4 '
5 #Include "MFPVISION"
6 '
7 Const Dim CDVsCmdMode$(3)
8 Const CDVsCmdMode$(1)="Chess"                               'Set vision command string as default Values
9 Const CDVsCmdMode$(2)="Shogi"                               'Set vision command string as default Values
10 Const CDVsCmdMode$(3)="GO"                                 'Set vision command string as default Values
11 Static Dim CPick$(2), CPut$(2)
12 '
13 '
14 '*** Set a vison communication port name ***
15 Const Dim CVsCOM$(7)
16 Const CVsCOM$(1)="COM2:"                                    'Set communication port name For vision
17 '
18 Function M! MFPVsTrigger_Play(MVsNum, ModePlay, ByRef MPick, ByRef MPut, ByRef MTurn, ByRef MEnd)
19 '
20     Print #1,CDVsCmdMode$(ModePlay)                                    'Select Mode Play
21     Input #1,MTurn,MPick,MPut,MCKPC,MCKMT         'Get Play: Turn + Pick Pose + Drop Pose + Check If there Is a piece on Drop pose + Check If checkmate
22     '
23     'Check Errors
24     If MPick <= 0 Or  MPut <= 0 Then
25         MFPVsTrigger_Play = -2
26     EndIf
27     'Check If Checkmate
28     If MCKMT = 1 Then MEnd = 1 Else MEnd = 0
29     'Check If There is a piece in objective place
30     If MCKPC = 1 Then
31         MFPVsTrigger_Play = 2
32     Else
33         MFPVsTrigger_Play = 1
34     EndIf
35 FEnd
