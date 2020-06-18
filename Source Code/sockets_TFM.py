import socket, select, sys
import time

MAXBUFLEN = 512

class SockData(object):
    #Socket Data initialization
    def __init__(self,IP,Port):
        self.IP = IP
        self.Port = Port
    #Creating an UDP socket client to connect with the controller

def CreateSocket(sockInfo):

        print("Connecting...")
        try :
            sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
            sock.settimeout(5.0)
        except  clientSock.error:
            sock.shutdown(socket.SHUT_RDWR)
            sock.close()
            print( "ERROR: socket unsuccessful")
            sys.exit()
        #Trying connection
        try:
            sock.bind((sockInfo.IP, sockInfo.Port))
            sock.listen()
        except Exception as e:
            print("Exception %s occured during socket creation" %(e))
            sock.shutdown(socket.SHUT_RDWR)
            sock.close()
            sys.exit()
        return sock

def ConnectRobot(sock):

    print("Please connect the robot")
    try:
        sock.settimeout(300000.0)
        conn, addr = sock.accept()
    except Exception as e:
        print("Exception %s occured while sending data" %(e))
        sock.shutdown(socket.SHUT_RDWR)
        sock.close()
        sys.exit()
    else:
        print("Robot connected with address ", addr)

    return conn, addr

def DataTransmission(add,sock,msg):

    #First send the data desired
    try:
        sock.sendto(msg, (add.IP,add.Port))
        sock.settimeout(1.0)
    except Exception as e:
        print("Exception %s occured while sending data" %(e))
        sock.shutdown(socket.SHUT_RDWR)
        sock.close()
        sys.exit()

def RecieveData(sock):

        #If no exception occurs, recieve the data
        data = []
        for retry in range(1,3):
            try:
                readable, writable, exceptional = select.select([sock], [], [], 2)
            except Exception as e:
                print("Exception %s occured while recieving data" %(e))
                sock.shutdown(socket.SHUT_RDWR)
                sock.close()
                sys.exit()
            else:
                if readable:
                    try:
                        data, addr = sock.recvfrom(MAXBUFLEN)
                        sock.settimeout(500.0)
                    except Exception as e:
                        print("Exception %s occured during recieving data" %(e))
                        sock.shutdown(socket.SHUT_RDWR)
                        sock.close()
                        sys.exit()
                    else:
                        break
                else:
                    if retry < 3:
                        continue
                    else:
                        print("Socket disconnected!!!")
                        sock.shutdown(socket.SHUT_RDWR)
                        sock.close()
                        sys.exit()

        if data:
            msg = data.decode("utf-8")
        else:
            msg = []

        return msg
