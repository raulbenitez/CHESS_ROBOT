from os import system, name
import sys, time

import math
import cv2
import numpy as np
from matplotlib import pyplot as plt

from tensorflow.keras.preprocessing import image

labels = ['h','g','f','e','d','c','b','a']
str_coord = "1,0,0,0,0,100,100,0,100,100"
vgg_dim = (224,224)
display = False
exit = False

class gridCoordinates(object):

    def __init__(self,coord, coord_cent, label, angle, cx, cy, piece, top3):
        self.coord = coord
        self.coord_cent = coord_cent
        self.label = label
        self.angle = angle
        self.cx = cx
        self.cy = cy
        self.piece = piece
        self.top3 = top3

def cls():    #Clear screen
    # for windows
    if name == 'nt':
        _ = system('cls')
    # for mac and linux(here, os.name is 'posix')
    else:
        _ = system('clear')

def initCamera(device, ang):


    print("Connecting with the camera...")
    webcam = cv2.VideoCapture(0,cv2.CAP_DSHOW)

    webcam.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    webcam.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

    if webcam.isOpened():

        print("Center the board in the middle of the camera. Press Space once the board is detected to continue\n")

        while True:

            try:
                check, img = triggCameraUSB(webcam, ang)

                if check:

                    cls()
                    print("Center the board in the middle of the camera. Press Space once the board is detected to continue\n")
                    im_msg, str_msg, board, grid, center = getBoardData(img)

                    if str_msg == "NotFound":
                        im_msg = img.copy()

            except:

                cls()
                im_msg = img.copy()
                str_msg = "NotFound"
                print("Could not find the board, please relocate.")
                print("Center the board in the middle of the camera. Press Space once the board is detected to continue\n")


            cv2.imshow("Center board", cv2.cvtColor(im_msg, cv2.COLOR_BGR2RGB))
            k = cv2.waitKey(30)
            if k == ord(' ') and str_msg != "NotFound":
                cv2.destroyAllWindows()
                break
            elif k == 27:
                exit = True
                cv2.destroyAllWindows()
                sys.exit()

    return webcam, im_msg, str_msg, board, grid, center

def loadCAMBoard(device, ang):


    print("Connecting with the camera...")
    webcam = cv2.VideoCapture(0,cv2.CAP_DSHOW)

    webcam.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    webcam.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

    if webcam.isOpened():

        print("Center the board in the middle of the camera. Press Space once the board is detected to continue\n")

        p0 = 200
        roi = [0,720,p0,p0+720]

        file = "board.jpg"
        img = image.load_img(file)
        img = image.img_to_array(img)

        img_cut = np.uint8(img[roi[0]:roi[1], roi[2]:roi[3], :].copy())
        im_msg, str_msg, board, grid, center = getBoardData(img_cut)

    return webcam, im_msg, str_msg, board, grid, center

def getBoardPiecesIMG(webcam, ang, board, engine):

    if webcam.isOpened():

        print("Put pieces, press space to continue\n")

        while webcam.isOpened():

            check, img = triggCameraUSB(webcam, ang)

            if check:

                im1 = cv2.cvtColor(img.copy(), cv2.COLOR_BGR2RGB)
                cv2.drawContours(im1, [board.coord],  0, [0,255,0], 3)
                cv2.imshow('frame',im1)

                k = cv2.waitKey(30)
                if k == ord(' ') :
                    cv2.destroyAllWindows()
                    break
                elif k == 27:
                    exit = True
                    cv2.destroyAllWindows()
                    engine.quit()
                    sys.exit()

    else:

        cv2.destroyAllWindows()
        print("Camera conenction error!")
        exit = True
        engine.quit()
        sys.exit()

    return img

def triggCameraUSB(webcam, ang):

    check, frame = webcam.read()
    frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    img = []
    p0 = 200
    roi = [0,720,p0,p0+720]
    img = frame[roi[0]:roi[1], roi[2]:roi[3], :]

    h, w = img.shape[:2]
    cnt = (h/2,w/2)
    img = rotateImage(img, ang, cnt)

    if img is None:
        print('Error opening image!')
        exit = True
        system.exit()

    return check, img


def triggCamera(filename, ang):

    img = cv2.imread(filename, cv2.IMREAD_UNCHANGED)

    h, w = img.shape[:2]
    cnt = (h/2,w/2)
    img = rotateImage(img, ang, cnt)

    if img is None:
        print('Error opening image!')
        sys.exit()

    return img

def getBoardData(img):

    try:

        gray = cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)

        imb, ang_res, center = BinarizeBoard(gray)
        im_roi = img.copy()
        im_roi[imb==0] = (0,0,0)

        board, grid = getBoard(gray, imb, ang_res, center)
        im_msg, str_msg = printCoordinatesBoard(board, grid, img.copy())

    except:

        im_msg = img.copy()
        str_msg = "NotFound"

    return im_msg, str_msg, board, grid, center

def BinarizeBoard(img):

    blur = cv2.GaussianBlur(img,(5,5),2)
    imb =  cv2.adaptiveThreshold(blur,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV,13,2)

    #Morphological operators
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT,(4,4))
    imb = cv2.erode(imb,kernel)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT,(7,7))
    imb = cv2.dilate(imb,kernel)

    #Find countours
    hull = []
    area = 0
    contours,hierarchy = cv2.findContours(imb, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    for cnt in contours:

        hull = cv2.convexHull(cnt, False)

        rect = cv2.minAreaRect(hull)
        box = cv2.boxPoints(rect)
        box = np.int0(box)
        angle = rect[2]

        ret = cv2.matchShapes(hull,box,1,0.0)

        if cv2.contourArea(cnt) > area and ret <= 0.05:
            epsilon = 0.1*cv2.arcLength(cnt,True)
            area = cv2.contourArea(cnt)
            result = box
            ang_res = angle

    imb = np.uint8(np.zeros((np.size(imb,0),np.size(imb,1))))
    cv2.drawContours(imb, [result], 0, 255, 3)

    im_out = imFill(imb)

    M = cv2.moments(result)
    center = (int(M['m10']/M['m00']), int(M['m01']/M['m00']))

    print("Angle:", ang_res)

    if ang_res > 45:
        ang_res = ang_res - 90
    elif ang_res < -45:
        ang_res = ang_res + 90

    print("Angle corrected:", ang_res)

    return im_out, ang_res, center


def imFill(imb):

    # Mask used to flood filling.
    # Notice the size needs to be 2 pixels than the image.
    im_floodfill = imb.copy()
    h, w = imb.shape[:2]
    mask = np.zeros((h+2, w+2), np.uint8)

    # Floodfill from point (0, 0)
    cv2.floodFill(im_floodfill, mask, (0,0), 255)

    # Invert floodfilled image
    im_floodfill_inv = cv2.bitwise_not(im_floodfill)

    # Combine the two images to get the foreground.
    im_out = imb | im_floodfill_inv

    return im_out

def getBoard(gray, imb, ang_res, center):

    sigma = 0.3
    board = gridCoordinates(np.zeros((4, 2)),np.zeros((4, 2)),"Board",0,0,0, np.uint8(np.zeros(vgg_dim)),['-','-','-'])

    v = np.median(gray)
    lower = int(max(0, (1.0 - sigma) * v))
    upper = int(min(255, (1.0 + sigma) * v))


    gray_rotated = rotateImage(gray, ang_res, center)
    imb_rotated = rotateImage(imb, ang_res, center)

    blur = cv2.GaussianBlur(gray_rotated,(3,3),2)
    dst = cv2.Canny(blur, lower, upper,  3)

    imbl = np.uint8(np.zeros((np.size(gray_rotated,0),np.size(gray_rotated,1))))

    lines = cv2.HoughLines(dst, 1, 15*np.pi/180, 75)
    for rho,theta in lines[:,0]:

        a = np.cos(theta)
        b = np.sin(theta)
        x0 = a*rho
        y0 = b*rho
        x1 = int(x0 + 1000*(-b))
        y1 = int(y0 + 1000*(a))
        x2 = int(x0 - 1000*(-b))
        y2 = int(y0 - 1000*(a))

        cv2.line(imbl,(x1,y1),(x2,y2),255,2)
        imbl[imb_rotated==0] = 0

    contours,hierarchy = cv2.findContours(imbl, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    rect = cv2.minAreaRect(contours[0])

    board.coord_cent = cv2.boxPoints(rect)
    board.coord = rotateContours(cv2.boxPoints(rect), -ang_res, center)
    board.angle = rect[2] + ang_res

    M = cv2.moments(board.coord)
    cx = int(M['m10']/M['m00'])
    cy = int(M['m01']/M['m00'])
    board.cx, board.cy = rotateCoordiates(cx, cy, -ang_res, center)

    grid = getGrid(board, contours, ang_res, center, gray)

    #Readjusting the board coordinates to improve accuracy
    board.coord[0,:] = grid[7].coord[0,:]
    board.coord[1,:] = grid[63].coord[1,:]
    board.coord[2,:] = grid[56].coord[2,:]
    board.coord[3,:] = grid[0].coord[3,:]

    return board, grid

def getGrid(board, contours, ang_res, center, gray):

    grid = []
    i = 0
    board_area = cv2.contourArea(board.coord)
    grid_area = board_area/64

    for cnt in contours[1:]:

        rect = cv2.minAreaRect(cnt)
        box = cv2.boxPoints(rect)
        box = np.int0(box)

        if cv2.contourArea(box) <= 1.5*grid_area and cv2.contourArea(box) >= 0.5*grid_area:

            M = cv2.moments(box)
            cx = int(M['m10']/M['m00'])
            cy = int(M['m01']/M['m00'])
            cx, cy = rotateCoordiates(int(M['m10']/M['m00']), int(M['m01']/M['m00']), -ang_res, center)
            coord_rotated = rotateContours(box, -ang_res, center)
            grid.append(gridCoordinates(coord_rotated,box,labels[i-math.floor(i/8)*8] + str(math.floor(i/8)+1),board.angle,cx,cy,np.uint8(np.zeros(vgg_dim)), ['-','-','-']))
            i += 1


    if i != 64:
        print("Error!! Board detection error")
        raise Exception

    return grid

def printCoordinatesBoard(board,grid,img):

    #index = [ x.label for x in grid].index('A8')
    cv2.drawContours(img, [board.coord], 0, [0,0,255], 3)

    msg = '1' + ',' + str(board.angle)

    for i in [7,0,63,56]: #Corner grids
        #cv2.drawContours(im_msg, [grid[i].coord], 0, [0,0,255], 3)
        #cv2.putText(img, '*', (grid[i].cx - 7, grid[i].cy + 7), cv2.FONT_HERSHEY_SIMPLEX, 0.75, [0, 0, 255], 1 )
        #cv2.putText(img, str(i), (grid[i].cx - 7, grid[i].cy + 7), cv2.FONT_HERSHEY_SIMPLEX, 0.75, [0, 0, 255], 1 )
        msg = msg + ',' + str(grid[i].cx) + ',' + str(grid[i].cy)

    return img, msg

def findGrid(move):

    if len(move) != 4 and len(move) != 5:
        print("Grid not valid, select another move")
        pick = -1
        place = -1
        raise Exception

    try:

        id = int(labels.index(move[0]))
        pick = (id-math.floor(id/8)*8)+(int(move[1])-1)*8

        id = int(labels.index(move[2]))
        place = (id-math.floor(id/8)*8)+(int(move[3])-1)*8

        return pick, place

    except:

        print("Grid not valid, id not found")
        pick = -1
        place = -1

        raise Exception

def showBoard(img, grid, move):

    pick, place = findGrid(move)
    if pick == -1:
        sys.exit()

    im1 = img.copy()
    cv2.drawContours(im1, [grid[pick].coord],  0, [0,0,255], 3)
    cv2.drawContours(im1, [grid[place].coord],  0, [0,255,0], 3)

    cv2.imshow("Board detected", cv2.cvtColor(im1, cv2.COLOR_BGR2RGB))
    cv2.waitKey(5)

    return

def rotateImage(img, angle, center):

    #Rotate image for test
    h, w = img.shape[:2]
    M = cv2.getRotationMatrix2D(center,angle,1)
    im_out = cv2.warpAffine(img,M,(h,w))

    return im_out

def rotateCoordiates(cx, cy, angle, center):

    M = cv2.getRotationMatrix2D(center,angle,1)
    coord = np.stack([cx, cy, 1])
    rotated = M.dot(coord.T).T

    return int(rotated[0]), int(rotated[1])

def rotateContours(box, angle, center):

    coord_rotated = np.zeros((4,2))
    coord = np.int0(box)
    for i in range(0,4):
        coord_rotated[i][:] = rotateCoordiates(coord[i][0], coord[i][1], angle, center)

    return np.int0(coord_rotated)

def dividedBoard(img, angle, grid, center, dim, display):

    img_centered = rotateImage(img, angle, center)

    plt.figure("Divided Board")

    for i in range(0,64):

        ymax = np.amax(grid[i].coord_cent[:,0])
        ymin = np.amin(grid[i].coord_cent[:,0])
        xmax = np.amax(grid[i].coord_cent[:,1])
        xmin = np.amin(grid[i].coord_cent[:,1])

        id = ord(grid[i].label[0]) - 96 + 8*((int(grid[i].label[1])) - 1) #Change values from 1 to 64

        if display == True:
            plt.xticks([])
            plt.yticks([])
            plt.grid(False)

            plt.subplot(8,8,id)
            plt.xticks([])
            plt.yticks([])
            plt.grid(False)
            plt.imshow(img_centered[xmin:xmax,ymin:ymax,:], cmap=plt.cm.binary)

            plt.xlabel(grid[i].label)

        grid[i].piece = cv2.resize(img_centered[xmin:xmax,ymin:ymax,:].copy(), dim)

    if display == True:
        plt.show()

    return grid
