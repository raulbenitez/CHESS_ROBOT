import cv2
import numpy as np
from vision_TFM import *
from os import system
import sys, time

#import tensorflow as tf

system("cls")
file = "dataset/set1/board4.jpg"
ang = 0
vggdim = (224, 244)
p0 = 200
roi = [0,720,p0,p0+720]

cap = cv2.VideoCapture(0,cv2.CAP_DSHOW)

cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

while(True):
    # Capture frame-by-frame
    ret, frame = cap.read()

    # Our operations on the frame come here
    img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    #print(img.shape[:2])
    img_cut = frame[roi[0]:roi[1], roi[2]:roi[3], :]

    try:
        im_msg, str_msg, board, grid, center = getBoardData(img_cut)
    except:
        im_msg =img_cut.copy()
        str_msg = "NotFound"

    cv2.imshow('frame',im_msg)

    k = cv2.waitKey(30)
    if k == ord(' ') and str_msg != "NotFound":
        break
    elif k == 27:
        sys.exit()




#dividedBoard(im_msg, board.angle, grid, center)
cv2.imshow('frame',im_msg)
cv2.waitKey(0)
print(board.coord)

msg = input("Put one piece: ")
folder = 'dataset/train/' + msg
folder = 'dataset/validate/' + msg
cv2.destroyAllWindows()
n = 178

for i in range(0,3):

    for id in range(0,64):

        ready = False
        while not ready:

            ret, frame = cap.read()
            img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img_cut = frame[roi[0]:roi[1], roi[2]:roi[3], :]
            im1 = img_cut.copy()
            cv2.drawContours(im1, [grid[id].coord],  0, [0,255,0], 3)
            cv2.imshow("Grid", im1)
            if (cv2.waitKey(10) & 0xFF == ord(' ')) and str_msg != "NotFound":
                ready = True

        dividedBoard(img_cut, board.angle, grid, center, vggdim, False)
        cv2.imwrite(folder +'/im (' + str(n) + ').jpg', grid[id].piece)
        n += 1
