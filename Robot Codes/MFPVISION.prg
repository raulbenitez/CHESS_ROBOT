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
64 'Function M! MFPVsTrigger_Play(MVsNum, ByRef MNumberFound, ByRef PVSDATA)
65 'FEnd
66 '
67 '##### COM Open process #####
68 'Input:MVsNum=Vision number
69 '      CCCOM$=Communication port number
70 'Return Value:Error Status(1:no Error, -1:Open Error, -2:File number Error)
71 Function M! MFPVSOpen(MVsNum, CCCOM$)
72   If M_Open(MVsNum)<>1 Then
73     Select MVsNum
74     Case 1
75       Open CCCOM$ As #1
76       Break
77     Case 2
78       Open CCCOM$ As #2
79       Break
80     Case 3
81       Open CCCOM$ As #3
82       Break
83     Case 4
84       Open CCCOM$ As #4
85       Break
86     Case 5
87       Open CCCOM$ As #5
88       Break
89     Case 6
90       Open CCCOM$ As #6
91       Break
92     Case 7
93       Open CCCOM$ As #7
94       Break
95     Default
96       MFPVSOpen=-2
97       Exit Function
98     End Select
99   EndIf
100   '
101   MFPVSOpen=M_NvOpen(MVsNum)
102 FEnd
103 '
104 '
105 '##### COM Close process #####
106 'Input:MVsNum=Vision number
107 'Return Value:Error Status(1:no Error, -1:Close Error, -2:File number Error)
108 Function M! MFPVSClose(MVsNum)
109   Select MVsNum
110   Case 1
111     Close #1
112     Break
113   Case 2
114     Close #2
115     Break
116   Case 3
117     Close #3
118     Break
119   Case 4
120     Close #4
121     Break
122   Case 5
123     Close #5
124     Break
125   Case 6
126     Close #6
127     Break
128   Case 7
129     Close #7
130     Break
131   Default
132     MFPVSClose=-2
133     Exit Function
134   End Select
135   '
136   If M_Open(MVsNum)=1 Then
137     MFPVSClose=-1
138     Exit Function
139   EndIf
140   MFPVSClose=1
141 FEnd
142 '
143 ''##### Alignment process #####
144 Function P MFPVsAlignHandCamT(MVsNum, PVSDATA, PTrg_Board, ByRef MErrSt)
145     'Change Coordinates
146         PVSDATA2=PVSCal(1,PVSDATA.X,PVSDATA.Y,PVSDATA.C)
147         MTCVSD_X#=PF_TCVSD(MVsNum).X
148         MTCVSD_Y#=PF_TCVSD(MVsNum).Y
149         MTCVSD_C#=PF_TCVSD(MVsNum).C
150         PTCVSD=PVSCal(1,MTCVSD_X#,MTCVSD_Y#,MTCVSD_C#)
151     'Calculate alignment position
152         PDest=P_Zero
153         PShift = Inv(PTCVSD)*Inv(PF_VsTrigPosBs(MVsNum))*PF_VsOpePosTBs(MVsNum)
154         PDest = PTrg_Board*PVSDATA2*PShift
155         PDest.FL1=PTrg_Board.FL1
156         PDest.FL2=PTrg_Board.FL2
157      '
158         MFPVsAlignHandCamT = PDest
159 FEnd
160 '
161 Function P MFTPAlignEdge(MCalib,PVSDATA,PRef)
162 '
163         PDest = P_Zero
164         PDest = PVSCal(MCalib,PVSDATA.X,PVSDATA.Y,PVSDATA.C)                        'Calculate alignment position for P2
165         PDest.Z = PRef.Z
166         PDest.A = PRef.A
167         PDest.B = PRef.B
168         PDest.C = PRef.C
169         PDest.FL1 = PRef.FL1
170         PDest.FL2 = PRef.FL2
171         MFTPAlignEdge = PDest
172 '
173 FEnd
174 Function V MFPTrainVsBaseHndCam(MVsNum, PTCVSD, PVsTrgPos, PBaseOpePosT)
175 '
176   PF_TCVSD(MVsNum)=PTCVSD
177   PF_VsTrigPosBs(MVsNum)=PVsTrgPos
178   PF_VsOpePosTBs(MVsNum)=PBaseOpePosT
179   Save 0
180 '
181 FEnd
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
