import chess
import chess.engine
import sys, time

from cnn_TFM import *

board_cols = ('a','b','c','d','e','f','g','h')
board_rows = ('1','2','3','4','5','6','7','8')

def initGame():

    engine = chess.engine.SimpleEngine.popen_uci("./engine/stockfish_10_x64")
    board = chess.Board(chess.STARTING_FEN)

    return engine, board

def playStockFish(board,engine):

    result = engine.play(board, chess.engine.Limit(time=0.100))
    msg = getDataPackage(result.move.uci(),board)

    board.push(result.move)
    info = engine.analyse(board, chess.engine.Limit(time=0.100))

    return board,result.move.uci(),info,msg

#SOLO PARA TEST
def playStockFish_hand(board,engine):

    move =[]

    while move not in board.legal_moves:

        #while not valid_format:
        #if len(msg) == 4 and msg[0] in board_rows and msg[1] in board_cols and msg[2] in board_rows and msg[3] in board_cols:
        msg = input("Select a move: ")

        try:
            move = chess.Move.from_uci(msg)
        except:
            print("Please enter a valid move format. \n")
        else:
            if move not in board.legal_moves:
                print("Please select a legal move. \n")

    msg = getDataPackage(move.uci(),board)

    board.push(move)
    info = engine.analyse(board, chess.engine.Limit(time=0.100))

    return board,move.uci(),info,msg

def notLegal(str_board, board, engine):

    legal_move = False

    brd = chess.Board(str_board)
    print("\n")
    print(brd,"\n")
    input("NOT LEGAL! Please make a legal move\n")

    info = engine.analyse(board, chess.engine.Limit(time=0.100))

    return legal_move, info

def checkPromotion(move,lbl_next,lbl_prev):

    check = False
    prom = ''
    wpcs = ["B","K","N","Q","R"]
    bpcs = ["b","k","n","q","r"]

    if len(move) == 4 and move[3] == '8' and lbl_prev == 'P' and lbl_next in wpcs:
            prom = move + bpcs[wpcs.index(lbl_next)]
            check = True
    elif len(move) == 4 and move[3] == '1' and lbl_prev == 'p' and lbl_next in bpcs:
            prom = move + lbl_next
            check = True
    else:
        prom = move
        check = False

    return chess.Move.from_uci(prom), check


def playUser(board,engine,str_board, legal_move, grid):

    move =[]

    mv, fen_legal = FENBoard_FindMove(str_board, board)

    fen_previous = board.fen()
    fen_next = str_board

    print("First try:", mv, fen_legal)

    if mv not in board.legal_moves or not mv:

        move =[]
        mv, lbl, occ, castling = Board2UCIMove(fen_next, fen_previous)

        if occ > 2:
            legal_move, info = notLegal(str_board, board, engine)
            return board,'',info, legal_move


        print(chess.Board(str_board),"\n")

        if occ == 2:
            if  ('e1K.' in  castling) and ('f1.R' in  castling) and ('g1.K' in  castling) and ('h1R.' in  castling):
                info = engine.analyse(board, chess.engine.Limit(time=0.100))
                legal_move = True
                move.append(chess.Move.from_uci('e1g1'))
                return board,move,info, legal_move
            elif  ('e1K.' in  castling) and ('d1.R' in  castling) and ('c1.K' in  castling) and ('a1R.' in  castling):
                info = engine.analyse(board, chess.engine.Limit(time=0.100))
                legal_move = True
                move.append(chess.Move.from_uci('e1c1'))
                return board,move,info, legal_move

        i = 0
        brd_prev = chess.Board(fen_previous)

        for candidate in mv:

            brd = chess.Board(fen_previous)
            brd.push(candidate)

            msg = candidate.uci()
            mput = ord(msg[2]) - 96 + 8*(int(msg[3],10) - 1) - 1  #Change values from 1 to 64
            mpick = ord(msg[0]) - 96 + 8*(int(msg[1],10) - 1) - 1  #Change values from 1 to 64


            lbl_next = str(brd.piece_at(mput))
            lbl_prev = str(brd_prev.piece_at(mput))
            lbl_pick = str(brd_prev.piece_at(mpick))

            candidate, check = checkPromotion(candidate.uci(),lbl[i], lbl_pick)

            if candidate not in board.legal_moves:
                i += 1
                continue

            else:

                if lbl[i] != lbl_next:

                    if check == True:
                        brd = chess.Board(fen_previous)
                        brd.push(candidate)
                        move.append(candidate)
                        i += 1

                    else:
                        id = len(board_cols)-int(board_cols.index(msg[2]))-1
                        place = (id-math.floor(id/8)*8)+(int(msg[3])-1)*8
                        print(grid[place].top3)
                        if lbl_next in grid[place].top3:
                            move.append(candidate)
                            i += 1
                        else:
                            i += 1
                            continue

                else:
                    move.append(candidate)
                    i += 1


    else:

        legal_move = True
        move.append(mv)

    if len(move) == 0:
        legal_move, info = notLegal(str_board, board, engine)
        return board,'',info, legal_move

    info = engine.analyse(board, chess.engine.Limit(time=0.100))
    legal_move = True

    return board,move,info, legal_move

def getDataPackage(move,board):

    mpick = ord(move[0]) - 96 + 8*(int(move[1],10) - 1) #Change values from 1 to 64
    mput = ord(move[2]) - 96 + 8*(int(move[3],10) - 1)  #Change values from 1 to 64

                                                #Check if there is a piece in objective position
    if board.piece_at(mput-1):                  #-1 is for the Offset in the MELFA Robot Plt Function
        piece = '1'
    else:
        piece = '0'

    #Build DataPackage for the MELFA Robot
    msg = str(mpick) + ',' + str(mput) + ',' + piece + ',' #Only left EndGame

    return msg
