1 #Include "MFPVISION"                                            'Vision Program Implementation
2 #Include "MFPLEARNING"                                          'Deep Reinforcement Learning Implementation
3 '
4 '############################     GLOBAL VARIABLES    ##########################################
5 '
6 Def Inte MRows, MCols                                           'Number of Row and Columns of Board Chess (8x8)
7 Def Inte MMode                                                  'Game (1-Chess, 2-Shogi, 3-Go)
8 Def Inte MBoard, MPick, MPut                                    'Board Number and Piece Number Position
9 Def Inte MTurn                                                  'Turn Robot/Player definition
10 Def Inte MVsNum                                                 'Vision Calibration Parameters
11 Def Inte MVsFound                                               'Check If found or not
12 Def Inte PltBoard                                               'Palet funciton Board
13 '
14 '############################     GLOBAL POSITIONS    ##########################################
15 '
16 Def Pos P1,P2,P3,P4                                             'Board Edges Positions
17 Def Pos P1_Align,P2_Align,P3_Align,P4_Align                     'Board Edges Positions
18 Def Pos PVSDATA                                                 'Vision Data regarding board position
19 'Def Pos PTrg_Board, PTrg_Play                                   'Board and playing Trigger Position
20 Def Pos PTrg                                                    'Board and playing Trigger Position
21 Def Pos PBoard                                                  'Board Located, and Base position
22 Def Pos PPick                                                   'Piece located
23 Def Pos PDrop                                                   'Movement decided
24 Def Pos PSafe                                                   'Place to drop eliminated pieces
25 '
26 '############################           MAIN          ##########################################
27 '
28 Function Main
29 '
30     MoveToHOME()                                                'Move to Home position
31     GoSub *Initialize
32     ErrStt=VisionActivation()                                   'Vison Activation
33 '
34     Mov PTrg                                                    'Photo Trigger For Board Position
35     Dly 0.2
36     PBoard_Play = SetBoard(MVsNum, PVSDATA1, PTrg, MErrStt)     'Set Board Position in Robot Coordinates
37     Def Plt MBoard,P1_Align,P2_Align,P3_Align,P4_Align,MRows,MCols,2
38     'PTrg_Play = Plt 1, 5                                       'Middle Point
39     'PTrg_Play.Z = PTrg_Play.Z + 100                             'Photo Trigger For Playing
40     Hlt
41     *LOOPGAME
42     '
43         Ovrd 30
44         Mov PTrg                                               'Photo Trigger For Playing
45         Dly 0.2
46         '
47         MErrStt = MFPVsTrigger_Play(MVsNum, MMode, MPick, MPut, MTurn) 'Play
48         If MTurn = 1 Then
49             '
50             If MErrStt <= 0 Then
51                 MErrStt=-1
52                 GoTo *VsErr_PlayError
53             EndIf
54             '
55             PPick = Plt MBoard, MPick
56             PPut = Plt MBoard, MPut
57             '
58             'Check If objective position Is taken
59             Ovrd 10
60             If  MErrStt = 2 Then
61                 PickPiece(PPut)                                     'Pick up eliminated Piece
62                 RemovePiece()
63                 Mov PTrg                                            'Go back to Trg Position
64                 Dly 0.2
65             EndIf
66             '
67             ' Play
68             PickPiece(PPick)                                    'Pick Piece
69             PutPiece(PPut)                                      'Put Piece
70             '
71            EndIf
72     '
73             If MErrStt = 3 Then                                 'Check If Checkmate
74                 GoTo *ENDGAME                               'Finish game
75             Else
76                 GoTo *LOOPGAME                              'Keep Playing
77             EndIf
78     '
79     *ENDGAME
80     Hlt
81     '
82     End
83     '########################     INITIALIZATION    ######################################
84     '
85     *Initialize
86         Ovrd 30
87         MTurn = 0
88         MBoard = 1
89         MRows = 8
90         MCols = 8
91         MPiece = 1
92         MMode = 1
93         If M_Out(900) = 1 Then
94             RemovePiece()                                           'If Gripper Activated Remove picked piece
95         EndIf
96     Return
97     '############################     Errors    ##########################################
98     '
99     *VsErr_Board
100       Error 9101   'Board not found
101       Hlt
102     GoTo *VsErr_Board
103    *VsErr_VisionActivation
104       Error 9102   'Board not found
105       Hlt
106     GoTo *VsErr_VisionActivation
107    *VsErr_PlayError
108       Error 9103   'Board not found
109       Hlt
110     GoTo *VsErr_PlayError
111 FEnd
112 '
113 '
114 '
115 '############################     FUNCTIONS    ##########################################
116 '
117 ' Initialization: Move to Home position
118 '
119 Function V MoveToHOME()
120 '
121         Servo On                                                'Servo ON
122         PSTART=P_Fbc(1)                                         'Acquire the current position
123         PSTART.Z=PSTART.Z+50
124         If P_Fbc(1).Z<PHome.Z Then                              'If the current height is below the origin
125             Ovrd 10
126             Mvs PSTART                                          'Move to the escape position
127             Ovrd 30
128         EndIf
129         Mov PHome                                               'Move to the origin
130 FEnd
131 '
132 'Vision Activation process
133 '
134 Function M! VisionActivation()
135 '
136         MVsNum=1                                                'Vision Number (Lower Fixed camera)
137         MCalibNum=0                                             'Calibration Number (0:Use Vision Calibration, 1:Use Robot Calibration)
138         MErrStt1=MFPVsActivation(MVsNum)                        'Activate vision system - 1
139         '
140         If MErrStt1<0 Or MErrStt2<0 Then
141             MErrStt=-1
142             *VsErr_VisionActivation
143             Exit Function
144         EndIf
145         VisionActivation=MErrStt
146     '
147 FEnd
148 '
149 'Find and locate Chess Board
150 '
151 Function P SetBoard(MVsNum, PVSDATA1, PTrg_Board, ByRef MErrStt)
152 '
153         MErrStt=MFPVsTrigger_Board(MVsNum, MVsFound1, PVSDATA, P1, P2, P3, P4)             'Vision Trigger For Board Position
154         If MErrStt<0 Or MVsFound1=0 Then
155             SetBoard = P_Zero
156             *VsErr_Board
157             Exit Function
158         EndIf
159         'Compute real board position in World Coordintes
160         PB = MFPVsAlignHandCamT(MVsNum, PVSDATA, PTrg_Board, MErrStt)                      'Calculate alignment position
161         '
162         'Edges in World Coordinates
163         P1_Align = PB                                            'Calculate alignment position for P1
164         P2_Align = MFTPAlignEdge(1,P2,P1_Align)                                            'Calculate alignment position for P2
165         P3_Align = MFTPAlignEdge(1,P3,P1_Align)                                            'Calculate alignment position for P3
166         P4_Align = MFTPAlignEdge(1,P4,P1_Align)                                            'Calculate alignment position for P4
167         '
168         'FinalPosition
169         SetBoard = P1_Align
170 FEnd
171 '
172 ' Moving Piece Processes
173 '
174 Function M! PickPiece(PObjective)           'Pick piece in the given position
175 '
176         Mov PObjective,-100
177         Mvs PObjective
178         Dly 0.1
179         HOpen 1
180         Mvs, -100
181 '
182 FEnd
183 '
184 Function M! PutPiece(PObjective)            'Put piece in the given position
185 '
186         Mov PObjective,-100
187         Mvs PObjective
188         Dly 0.1
189         HClose 1
190         Mvs, -100
191 '
192 FEnd
193 '
194 Function M! RemovePiece()                   'Go to safe position and release load
195 '
196         Mvs,-50
197         Mov PHome                           'Safe Point
198         Mov PSafe, -50
199         Mvs PSafe                           'Drop Piece
200         Dly 0.2
201         HClose 1
202         Mvs, -50
203         Mov PHome                           'Safe Point
204 '
205 FEnd
P1=(+106.00,+618.00,+0.00,+0.00,+0.00,+0.12)(0,0)
P2=(+598.00,+619.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
P3=(+107.00,+124.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
P4=(+599.00,+125.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
P1_Align=(+340.51,-321.21,+175.00,+180.00,-0.00,+179.99,+0.00,+0.00)(7,0)
P2_Align=(+360.28,-119.52,+175.00,+180.00,-0.00,+179.99,+0.00,+0.00)(7,0)
P3_Align=(+155.35,-320.34,+175.00,+180.00,-0.00,+179.99,+0.00,+0.00)(7,0)
P4_Align=(+156.16,-118.72,+175.00,+180.00,-0.00,+179.99,+0.00,+0.00)(7,0)
PVSDATA=(+106.00,+618.00,+0.00,+0.00,+0.00,+0.12)(0,0)
PTrg=(+270.00,+0.00,+250.00,-180.00,+0.00,-180.00)(7,0)
PBoard=(+350.00,-315.00,+175.00,-180.00,+0.00,+180.00)(7,0)
PPick=(+182.03,-262.86,+175.00,+180.00,+0.00,+179.99,+0.00,+0.00)(7,0)
PDrop=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PSafe=(+270.00,+0.00,+85.00,+180.00,+0.00,+180.00)(7,0)
PF_CamTL=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(7,0)
PHome=(+270.00,+0.00,+505.00,+180.00,-0.00,+180.00)(7,0)
PPUT=(+234.94,-263.11,+175.00,+180.00,+0.00,+179.99)(7,0)
