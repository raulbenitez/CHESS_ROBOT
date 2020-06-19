import time
from sockets_TFM import *

class RCommands(object):
    #Commands to control de robotIP
    opencom = '1;1;OPEN=USERTOOL'
    close = '1;1;CLOSE'
    cntlon = '1;1;CNTLON'
    cntloff = '1;1;CNTLOFF'
    srvon = '1;1;SRVON'
    srvoff = '1;1;SRVOFF'
    prgload = '1;1;PRGLOAD='
    slotinit = '1;1;SLOTINIT'
    rstalrm = '1;1;RSTALRM'
    run = '1;1;RUN'
    stop = '1;1;STOP'

    def loadProgram(self, prg):
        msg = self.prgload + prg
        return msg

def initRT3COM(sock):

    #Load list of Commands
    commands = RCommands()

    #Create Socket for RT3 commands using a different port
    TCP_PORT = 10001
    if sock.Port == 10001:
        TCP_PORT = 10002

    RT3_address = SockData(sock.IP, TCP_PORT)

    #Create socket TCP client for RT3 Commands
    try :

        RT3_sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        RT3_sock.settimeout(300.0)

        RT3_sock.connect((RT3_address.IP, RT3_address.Port))

    except  socket.error:

        RT3_sock.shutdown(socket.SHUT_RDWR)
        RT3_sock.close()
        print( "ERROR: socket unsuccessful")
        sys.exit()

    return RT3_address, commands, RT3_sock

def initRobot(RT3_sock, RT3_address, commands):

    #Open R3 Communication
    print("Connecting port...")
    data = sendCommand(RT3_address, RT3_sock, commands.opencom)

    if data[:3] == 'QoK':
        #Delay for controller Communciation
        time.sleep(0.50)
    else:
        data = 'opencom'
        alarmHandling(RT3_address, RT3_sock, commands, data)

    #Open R3 Communication
    print("Getting operation rights...")
    data = sendCommand(RT3_address, RT3_sock, commands.cntlon)

    if data == 'QoK':
        #Delay for controller Communciation
        time.sleep(0.50)
    else:
        data = 'rights'
        alarmHandling(RT3_address, RT3_sock, commands, data)

    print("Reseting robot...")
    stopRobot(RT3_sock, RT3_address, commands)

    return

def runRobot(RT3_sock, RT3_address, commands):

    #Run MAIN Progran
    data = sendCommand(RT3_address, RT3_sock, commands.run)
    time.sleep(0.50)

    if data[:3] == 'QoK':
        #Delay for controller Communciation
        time.sleep(0.50)
    elif data[3:7] == '6020':
        alarmHandling(RT3_address, RT3_sock, commands, data)
    else:
        data = "blocked"
        alarmHandling(RT3_address, RT3_sock, commands, data)

    return

def stopRobot(RT3_sock, RT3_address, commands):

    #Load MAIN Program and start the application
    data = sendCommand(RT3_address, RT3_sock, commands.stop)
    time.sleep(0.50)

    if data == 'QoK':
        #Delay for controller Communciation
        time.sleep(0.50)
    else:
        alarmHandling(RT3_address, RT3_sock, commands, data)

    #Activate program selection
    data = sendCommand(RT3_address, RT3_sock, commands.slotinit)
    time.sleep(0.50)

    if data == 'QoK':
        #Delay for controller Communciation
        time.sleep(0.50)
    else:
        data = 'reset'
        alarmHandling(RT3_address, RT3_sock, commands, data)

    return

def loadProgram(RT3_sock, RT3_address, commands, msg):

    prog = commands.loadProgram(msg)

    data = sendCommand(RT3_address, RT3_sock, prog)
    if data[:3] == 'QoK':
        #Delay for controller Communciation
        time.sleep(0.50)

    else:
        alarmHandling(RT3_address, RT3_sock, commands, data)


    return

def sendCommand(RT3_address, RT3_sock, command):

        msg = command.encode('utf-8')

        #Send command to robot
        DataTransmission(RT3_address,RT3_sock,msg)

        try:
            RT3_sock.settimeout(300.0)
            data, addr = RT3_sock.recvfrom(MAXBUFLEN)
        except Exception as e:
            print("Exception %s occured during recieving data" %(e))
            RT3_sock.shutdown(socket.SHUT_RDWR)
            RT3_sock.close()
            sys.exit()

        return data.decode("utf-8")

def closeCOM(RT3_address, RT3_sock,commands):

    data = sendCommand(RT3_address, RT3_sock, commands.cntloff)
    time.sleep(0.50)

    RT3_sock.shutdown(socket.SHUT_RDWR)
    RT3_sock.close()

    return

def alarmHandling(RT3_address, RT3_sock, commands, data):

        #Reset Error Alarm
        data_rst = sendCommand(RT3_address, RT3_sock, commands.rstalrm)
        time.sleep(0.50)

        if data[3:7] == '4140':

            print("ERROR!! Program not found!")
            print("Please load all the programs to the robot and restart the application\n")

        elif data[3:7] == '6020':

            print("ERROR!! Permission error!")
            print("Please make sure the robot is in AUTO mode and the TB is not on the Operation screen.")
            print("Please restart the application\n")

        elif data[3:7] == '4190':

            #Activate program selection
            data = sendCommand(RT3_address, RT3_sock, commands.slotinit)
            time.sleep(0.50)

            #Load DUMMY program to clear the program bug
            prg = commands.prgload + 'DUMMY'
            data = sendCommand(RT3_address, RT3_sock, prg)
            time.sleep(0.50)
            print("ERROR!! Function proceadure programming bug")
            print("Please restart the controller\n")

        elif data == "blocked":

            print("ERROR! Could not run the robot, please restart the application")

            #Activate program selection
            data = sendCommand(RT3_address, RT3_sock, commands.slotinit)
            time.sleep(0.50)

            #Load DUMMY program to clear the program bug
            prg = commands.prgload + 'DUMMY'
            data = sendCommand(RT3_address, RT3_sock, prg)
            time.sleep(0.50)

        elif data == 'opencom':

            print("\nERROR!! Cannot connect with the robot. Please check the connection")

        elif data == 'rights':

            print("\nERROR!! Cannot get operation rights, please reset the robot")

        elif data == 'reset':

            print("\nERROR!! Cannot reset the robot, please restart the controller")

        else:

            print("ERROR!! Cannot connect with the robot.")
            print("Please check the connection\n")

        data = sendCommand(RT3_address, RT3_sock, commands.cntloff)
        time.sleep(0.50)

        RT3_sock.shutdown(socket.SHUT_RDWR)
        RT3_sock.close()
        sys.exit()
