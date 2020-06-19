1 '##############################################
2 ' VISION CAMERA FUNCTIONS
3 '##############################################
4 '
5 Static Dim MNumFound(7)                     'Number of find : MNumFound(Vision number)
6 Static Dim PVs(7,10)                        'Vision data : PVs(Vision MNumberFound,Data number)
7 Static Dim CF_CPPRG$(7)                     'JOB name
8 '
9 Static Dim MCCDX(10),MCCDY(10),MCCDC(10)    'Vision Data
10 '
11 Dim  PF_TCVSD(3)
12 Dim  PF_VsTrigPosBs(3)
13 Dim  PF_VsOpePosTBs(3)
14 '
15 '*** Set a default vison command string ***
16 Const Dim CDVsCmd$(7)
17 Const CDVsCmd$(1)="Board"                   'Set vision command string as default Values
18 '
19 '*** Set a vison communication port name ***
20 Const Dim CVsCOM$(7)
21 Const CVsCOM$(1)="COM2:"                     'Set communication port name For vision
22 '##### Vision avtivation process #####
23 'Input:MVsNum=Vision number
24 Function M! MFPVsActivation(MVsNum)
25   CF_CPPRG$(MVsNum)=CDVsCmd$(MVsNum)          'Set JOB name
26   CCOM$=CVsCOM$(MVsNum)
27   MFPVsActivation=MFPVSOpen(MVsNum, CCOM$)    'Open communication port of vision
28 FEnd
29 '
30 '##### Vision Trigger process #####
31 'Trigger vision system
32 'Input:MVsNum=Vision number
33 'Output:MNumberFound=Pass/Not pass
34 '       PVSDATA=1st Vision result
35 'Return Value:Error Status(1:no Error, -2:Vision number Error)
36 Function M! MFPVsTrigger_Board(MVsNum, ByRef MNumberFound, ByRef PVSDATA, ByRef P1, ByRef P2, ByRef P3, ByRef P4)
37     Print #1, CF_CPPRG$(1) '
38     Input #1, MNumFound(1), MCCDC(1),MCCDX(1),MCCDY(1), MCCDX(2),MCCDY(2),MCCDX(3),MCCDY(3),MCCDX(4),MCCDY(4)  'Get Board Edge Points + Middle
39     MNumberFound = MNumFound(1)
40     If MNumberFound = 1 Then   'If Board Is found
41         For MVsCnt = 1 To 4
42             PVs(MVsNum,MVsCnt)=P_Zero
43             PVs(MVsNum,MVsCnt).X=MCCDX(MVsCnt)
44             PVs(MVsNum,MVsCnt).Y=MCCDY(MVsCnt)
45         Next MVsCnt
46         PVs(MVsNum,1).C=Rad(MCCDC(1))
47         Break
48     Else
49         MFPVsTrigger_Board = -2
50         Exit Function
51     EndIf
52 '
53 '   EDGE POINTS
54     P1 = PVs(MVsNum,1)
55     P2 = PVs(MVsNum,2)
56     P3 = PVs(MVsNum,3)
57     P4 = PVs(MVsNum,4)
58 '
59 '   VISION DATA OUTPUT
60     PVSDATA  = PVs(MVsNum,1)
61     MFPVsTrigger_Board = 1
62 '
63 FEnd
64 '
65 '##### COM Open process #####
66 'Input:MVsNum=Vision number
67 '      CCCOM$=Communication port number
68 'Return Value:Error Status(1:no Error, -1:Open Error, -2:File number Error)
69 Function M! MFPVSOpen(MVsNum, CCCOM$)
70   If M_Open(MVsNum)<>1 Then
71     Select MVsNum
72     Case 1
73       Open CCCOM$ As #1
74       Break
75     Case 2
76       Open CCCOM$ As #2
77       Break
78     Case 3
79       Open CCCOM$ As #3
80       Break
81     Case 4
82       Open CCCOM$ As #4
83       Break
84     Case 5
85       Open CCCOM$ As #5
86       Break
87     Case 6
88       Open CCCOM$ As #6
89       Break
90     Case 7
91       Open CCCOM$ As #7
92       Break
93     Default
94       MFPVSOpen=-2
95       Exit Function
96     End Select
97   EndIf
98   '
99   MFPVSOpen=M_NvOpen(MVsNum)
100 FEnd
101 '
102 '
103 '##### COM Close process #####
104 'Input:MVsNum=Vision number
105 'Return Value:Error Status(1:no Error, -1:Close Error, -2:File number Error)
106 Function M! MFPVSClose(MVsNum)
107   Select MVsNum
108   Case 1
109     Close #1
110     Break
111   Case 2
112     Close #2
113     Break
114   Case 3
115     Close #3
116     Break
117   Case 4
118     Close #4
119     Break
120   Case 5
121     Close #5
122     Break
123   Case 6
124     Close #6
125     Break
126   Case 7
127     Close #7
128     Break
129   Default
130     MFPVSClose=-2
131     Exit Function
132   End Select
133   '
134   If M_Open(MVsNum)=1 Then
135     MFPVSClose=-1
136     Exit Function
137   EndIf
138   MFPVSClose=1
139 FEnd
140 '
141 ''##### Alignment process #####
142 Function P MFPVsAlignHandCamT(MVsNum, PVSDATA, PTrg_Board, ByRef MErrSt)
143     'Change Coordinates
144         PVSDATA2=PVSCal(1,PVSDATA.X,PVSDATA.Y,PVSDATA.C)
145         MTCVSD_X#=PF_TCVSD(MVsNum).X
146         MTCVSD_Y#=PF_TCVSD(MVsNum).Y
147         MTCVSD_C#=PF_TCVSD(MVsNum).C
148         PTCVSD=PVSCal(1,MTCVSD_X#,MTCVSD_Y#,MTCVSD_C#)
149     'Calculate alignment position
150         PDest=P_Zero
151         PShift = Inv(PTCVSD)*Inv(PF_VsTrigPosBs(MVsNum))*PF_VsOpePosTBs(MVsNum)
152         PDest = PTrg_Board*PVSDATA2*PShift
153         PDest.FL1=PTrg_Board.FL1
154         PDest.FL2=PTrg_Board.FL2
155      '
156         MFPVsAlignHandCamT = PDest
157 FEnd
158 '
159 Function P MFTPAlignEdge(MCalib,PVSDATA,PRef)
160 '
161         PDest = P_Zero
162         PDest = PVSCal(MCalib,PVSDATA.X,PVSDATA.Y,PVSDATA.C)                        'Calculate alignment position for P2
163         PDest.Z = PRef.Z
164         PDest.A = PRef.A
165         PDest.B = PRef.B
166         PDest.C = PRef.C
167         PDest.FL1 = PRef.FL1
168         PDest.FL2 = PRef.FL2
169         MFTPAlignEdge = PDest
170 '
171 FEnd
172 Function V MFPTrainVsBaseHndCam(MVsNum, PTCVSD, PVsTrgPos, PBaseOpePosT)
173 '
174   PF_TCVSD(MVsNum)=PTCVSD
175   PF_VsTrigPosBs(MVsNum)=PVsTrgPos
176   PF_VsOpePosTBs(MVsNum)=PBaseOpePosT
177   Save 0
178 '
179 FEnd
PVs(1,1)=(+106.00,+618.00,+0.00,+0.00,+0.00,+0.12,+0.00,+0.00)(0,0)
PVs(1,2)=(+598.00,+619.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
PVs(1,3)=(+107.00,+124.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
PVs(1,4)=(+599.00,+125.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
PVs(1,5)=(+45.00,+25.00,+0.00,+0.00,+0.00,+30.00,+0.00,+0.00)(0,0)
PVs(1,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(1,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(1,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(1,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(1,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,1)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,4)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,5)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(2,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,1)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,4)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,5)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(3,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,1)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,4)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,5)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(4,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,1)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,4)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,5)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(5,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,1)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,4)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,5)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(6,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,1)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,4)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,5)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,6)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,7)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,8)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,9)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PVs(7,10)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PF_TCVSD(1)=(+121.00,+595.00,+0.00,+0.00,+0.00,-0.21,+0.00,+0.00)(0,0)
PF_TCVSD(2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PF_TCVSD(3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PF_VsTrigPosBs(1)=(+270.00,+0.00,+250.00,-180.00,+0.00,-180.00,+0.00,+0.00)(7,0)
PF_VsTrigPosBs(2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PF_VsTrigPosBs(3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PF_VsOpePosTBs(1)=(+350.00,-315.00,+175.00,-180.00,+0.00,+180.00,+0.00,+0.00)(7,0)
PF_VsOpePosTBs(2)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PF_VsOpePosTBs(3)=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
