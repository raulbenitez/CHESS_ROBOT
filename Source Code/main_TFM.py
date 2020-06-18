import sys, time
from os import system, name

from tensorflow.keras.preprocessing import image
import matplotlib.pyplot as plt

from sockets_TFM import *
from sfcom_TFM import *
from vision_TFM import *
from comRT3_TFM import *
from cnn_TFM import *

move_st = []
move_pl = []
msg = []
command = []

display = False
turn_pl =  True
ang = 0
dim = (720,720)

print("Loading model...")
vggmodel, featmodel = LoadCNN('models/vggmodel19_tfm.h5')
clf1 = joblib.load('models/svm_tfm.pkl')

cls()

print("\n----------CONNECTION PARAMETERS-----------\n")
msg = input("Input connection destination IP address (192.168.0.90): ")
if not msg:
    #SockData.IP = "192.168.0.90"
     SockData.IP = "192.168.100.115"
else:
    SockData.IP = msg
msg = []
while not msg:
    msg = input("Input connection destination port No. (10003): ")
    if not msg:
        msg = "10003"
        SockData.Port = 10003
    else:
        try:
            SockData.Port = int(msg, 10)
        except  ValueError:
            print("Please enter a valid port")
            msg = []

print("IP = %s / PORT = %i\n" %(SockData.IP,SockData.Port))
input("\nIs it all right? [Enter] / [Ctrl+C] ")

print("\n")

destSocket = CreateSocket(SockData)     #Communication for vision and playing data
RT3_address, commands, RT3_sock = initRT3COM(SockData)      #Communciation for RT3 Commands

initRobot(RT3_sock, RT3_address, commands)      #Initialize Robot configuration
time.sleep(0.5)

#Load MAIN Program and start the application
loadProgram(RT3_sock, RT3_address, commands, "MAIN")

#Run the Robot
runRobot(RT3_sock, RT3_address, commands)
robotCOM, robotIP = ConnectRobot(destSocket)

print("Waiting the robot...\n")

while command[0:len("Board")] != "Board":
    command = RecieveData(robotCOM)

command = []

print("Robot connected, finding board...")


webcam, im_msg, str_msg, board_coord, grid, center = initCamera(0,0)   #Online images
#webcam, im_msg, str_msg, board_coord, grid, center = loadCAMBoard(0,0)  #Offlines images

DataTransmission(SockData,robotCOM,msg.encode('utf-8'))

cls()
engine, board = initGame()
print(board, "\n")

input("Ready to play? [Enter] / [Ctrl+C] ")
print("\n")

#Start the robot playing
runRobot(RT3_sock, RT3_address, commands)

while not board.is_game_over():

    print("Waiting the robot...\n")

    while command[0:len("Chess")] != "Chess":
        command = RecieveData(robotCOM)

    if turn_pl:

        legal_move = False
        board_prev = chess.Board(board.fen())

        while not legal_move:

            print("Make your move. Press Enter to continue.")
            print('\n')


            img = getBoardPiecesIMG(webcam, ang, board_coord, engine)
            grid = dividedBoard(img, board_coord.angle, grid, center, vgg_dim, display)

            print("Predicting board...\n")
            pred_board, str_board, grid = predictBoard(grid, featmodel, clf1)

            try:
                board, move_pl, info, legal_move = playUser(board, engine, str_board, legal_move, grid, vggmodel)
            except Exception as e:
                print(e)
                destSocket.close()
                engine.quit()
                sys.exit()

            if legal_move == False:
                continue

            for mv in move_pl:

                move_st = str(mv)
                showBoard(img, grid, move_st)

                turn_pl = False
                msg_move = []

                while msg_move != 'Y' and msg_move != 'y' and msg_move != 'n' and msg_move != 'N':

                    print("Move selected:", mv.uci())
                    msg_move = input("Was that your move? [Y/N]")

                    if msg_move == 'n' or msg_move == 'N':
                        print("\n")
                        board = chess.Board(board_prev.fen())
                        legal_move = False
                        continue
                    elif msg_move == 'Y' or msg_move == 'y':
                        print("\n")
                        legal_move = True
                        board.push(mv)
                        msg = getDataPackage(mv.uci(),board)
                        info = engine.analyse(board, chess.engine.Limit(time=0.100))

                if legal_move == True and (msg_move == 'Y'or msg_move == 'y'):
                    break


    else:

        board,move_st,info,msg = playStockFish(board,engine)
        turn_pl = True

        check, img = triggCameraUSB(webcam, ang)
        showBoard(img, grid, move_st)

        time.sleep(1)

    #Check if it's endgame after pushing the board and add it to the DataPackage
    endgame = str(int(board.is_game_over()))
    str_turn = str(int(turn_pl))
    str_msg = str_turn + "," + msg + endgame

    DataTransmission(SockData,robotCOM,str_msg.encode('utf-8'))

    command = []

    cls()
    print("Last engine's move:", move_st, "/ Last player move: ", mv.uci() ,"\n")
    print("Score: ", info["score"],"\n" )
    print(board, "\n")

    print(str_msg)

input("Endgame")

destSocket.close()
engine.quit()
sys.exit()
