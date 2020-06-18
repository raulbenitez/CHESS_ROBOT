# CNN_TFM.py
import numpy as np # linear algebra
from scipy import stats
import cv2
import io

#Input Keras and Tensorflow Environment
import tensorflow as tf
from tensorflow.python.keras import datasets, layers, models, utils, regularizers, applications, optimizers
from tensorflow.python.keras.preprocessing import image
from tensorflow.python.keras.optimizers import SGD
import matplotlib.pyplot as plt
from sklearn.externals import joblib

from vision_TFM import *
from os import system

import chess
import chess.engine

pred_board = np.chararray((8,8))
pred_board[:] = '.'

previous = np.chararray((8,8))
previous[:] = '.'

labels_grid = ['h','g','f','e','d','c','b','a']
labels = ["-", "b", "k","n","p", "q", "r", "B", "K","N","P", "Q", "R"]

def LoadCNN(folder):

    print("Loading Neural Network...\n")
    vggmodel = models.load_model(folder)

    episodes = 100
    learning_rate = 0.001

    vggmodel.compile(optimizer='Adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])

    featmodel = models.Sequential()
    for layer in vggmodel.layers[:-3]: # go through until last layer
        featmodel.add(layer)

    featmodel.compile(optimizer='Adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])

    return vggmodel, featmodel

def LoadSVM(joblib_file):

    clf = joblib.load(joblib_file)
    return clf

def isinTop3(grid, lbl, msg_grid, vggmodel):

    id = [i for i in range(0,64) if grid[i].label == msg_grid]
    img = grid[id[0]].piece
    img = np.expand_dims(img/255., axis=0)

    pred = vggmodel.predict(img, batch_size = 1)
    ind_cnn = np.argsort(pred)[0][-3:]

    #Save top 3 in case of error
    top3 = [labels[ind_cnn[0]], labels[ind_cnn[1]], labels[ind_cnn[2]]]
    top3 = ['.' if lbl == '-' else lbl for lbl in top3]  #Change empty class label to match with the board

    return lbl in top3

def predictBoard(grid, featmodel, clf1):

    for i in range(0,64):

        img = grid[i].piece/255.
        img = np.expand_dims(img, axis=0)

        msg = grid[i].label
        id = int(labels_grid.index(msg[0]))

        feat = featmodel.predict(img, batch_size = 1) #Prediction one by one due to memory limitation
        dd = np.expand_dims(np.squeeze(feat), axis=0)
        pred = clf1.predict(dd)

        ind = pred[0]
        pred_board[8 - int(msg[1]), 7 - id] = labels[ind]  #Prediction for CNN + SVM

    str_board = Board2FEN(pred_board)
    return pred_board, str_board, grid

def Board2FEN(pred_board):

    # Use StringIO to build string more efficiently than concatenating
    with io.StringIO() as s:
        for row in pred_board:
            empty = 0
            for cell in row:
                c = str(cell)
                if c[2] != "-":
                    if empty > 0:
                        s.write(str(empty))
                        empty = 0
                    s.write(c[2])
                else:
                    empty += 1
            if empty > 0:
                s.write(str(empty))
            s.write('/')
        # Move one position back to overwrite last '/'
        s.seek(s.tell() - 1)
        # If you do not have the additional information choose what to put
        s.write(' w KQkq - 0 1')
        return s.getvalue()

def Board2UCIMove(fen_next, fen_previous):

    uci_move = ''
    uci_prev = ''
    uci_next = ''

    uci_change = []
    lbl_change = []

    next = str(chess.Board(fen_next)).split()
    previous = str(chess.Board(fen_previous)).split()
    castling = []
    occ = 0

    for i in range(0,64):

        move_found = False

        if str(next[i]) != str(previous[i]):

            prv = str(previous[i])
            nxt = str(next[i])
            move_found = True
            uci_fail = labels_grid[7-((i+1)-8*math.floor(i/8)-1)] + str(8-math.floor(i/8))

            if prv == '.' and nxt != '.':
                occ += 1
                uci_next = labels_grid[7-((i+1)-8*math.floor(i/8)-1)] + str(8-math.floor(i/8))
                lbl = nxt

            if prv != '.' and nxt == '.':
                uci_prev = labels_grid[7-((i+1)-8*math.floor(i/8)-1)] + str(8-math.floor(i/8))

            if prv != '.' and nxt != '.':
                uci_change.append(labels_grid[7-((i+1)-8*math.floor(i/8)-1)] + str(8-math.floor(i/8)))
                lbl_change.append(nxt)


            msg = uci_fail + prv + nxt
            castling.append(msg)


    uci_move = uci_prev + uci_next

    if occ == 1:
        return [chess.Move.from_uci(uci_move)], [lbl], occ, castling
    elif occ == 0 or occ == 2:
        if uci_prev:
            moves = [chess.Move.from_uci(uci_prev + ch) for ch in uci_change]
            return moves, lbl_change, occ, castling

    return [],[''],0,[]

def FENBoard_FindMove(fen_next, board_play):

    fen_previous = board_play.fen()

    move = ""
    fen_legal = ""

    for mv in board_play.legal_moves:

        prev_board = chess.Board(fen_previous)
        prev_board.push(mv)

        msg = prev_board.fen()

        if msg[:msg.find(' ')] == fen_next[:fen_next.find(' ')]:

            move = mv
            fen_legal = msg
            break

    return move, fen_legal
