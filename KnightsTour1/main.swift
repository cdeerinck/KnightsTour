//
//  main.swift
//  KnightsTour1
//
//  Created by Chuck Deerinck on 2/28/20.
//  Copyright © 2020 Chuck Deerinck. All rights reserved.
//

import Foundation
/*  The board is n (high) x m (wide) in size with the top left at postion 0.
    So a 3 x 4 board would look like this  0  1  2  3
                                           4  5  6  7
    A given cell is cell=row*m+col         8  9 10 11
    The reverse is row=Int(cell/m)
                   col=cell % m
*/
var n:Int = 8
var m:Int = 8

struct Step {
    var cell:Int
    var possible:[Int]
}

func cell2RowCol(_ cell:Int) -> (row:Int, col:Int) {
    return (Int(cell/m),cell%m)
}

func rowCol2Cell(_ row:Int, _ col:Int) -> Int {
    return row*m+col
}

func addCell2Array(_ row:Int, _ col:Int, _ moves: inout [Int]) {
    if row < 0 || row >= n || col < 0 || col >= m {
        return
    }
    moves.append(rowCol2Cell(row, col))
}

func knightMoves(_ cell:Int) -> [Int] {
    var moves:[Int] = []
    let (row,col) = cell2RowCol(cell)
    addCell2Array(row-2,col-1, &moves)
    addCell2Array(row-2,col+1, &moves)
    addCell2Array(row-1,col-2, &moves)
    addCell2Array(row-1,col+2, &moves)
    addCell2Array(row+1,col-2, &moves)
    addCell2Array(row+1,col+2, &moves)
    addCell2Array(row+2,col-1, &moves)
    addCell2Array(row+2,col+1, &moves)
    return moves
}

func hasHope(_ board:[Int:[Int]]) -> Bool {
    return board.filter{$0.value.count==0}.count == 0
}

func removeCell(_ cell:Int, from board:[Int:[Int]]) -> (Bool, [Int:[Int]]?) {
    //print("Removing cell \(cell)")
    //If after doing this move:
    //  if any cell has no valid moves, the board has no hope.
    //  if the board has more than one cell with only a single hop to it, the board has no hope either.
    var newBoard = board
    var singletonCount = 0
    if let hops = board[cell] {
        for hop in hops {
            newBoard[hop] = board[hop]!.filter{$0 != cell}.sorted(by: {$0<$1}) //If the explicit unwrap here fails, the board was invalid.
            if newBoard[hop]!.count == 0 && newBoard.count > 2 { return (false, nil) }
            if newBoard[hop]!.count == 1 {
                if singletonCount > 3 {
                    return (false, nil)
                } else {
                    singletonCount += 1
                }
            }
        }
        newBoard.removeValue(forKey: cell)
        return (true, newBoard)
    }
    return (false, nil) //This should never occur.  It means we have tried to move to a cell not in the board.
}

func addCell(_ cell:Int, to board:[Int:[Int]], with emptyBoard:[Int:[Int]]) -> [Int:[Int]] {
    //print("Adding cell \(cell)")
    var newBoard = board
    if let potentialCells = emptyBoard[cell] {
        for oneCell in potentialCells {
            if board[oneCell] != nil { // This means oneCell has not been moved to
                newBoard[oneCell]!.append(cell)
                if newBoard[cell] != nil {
                    newBoard[cell]!.append(oneCell)
                } else {
                    newBoard[cell] = [oneCell]
                }
                newBoard[oneCell]!.sort()
            }
        }
    }
    return newBoard
}

var emptyBoard:[Int:[Int]] = [:]
var board:[Int:[Int]] = [:]
var moves:[Step] = []
var nextMoves:[Int] = []
var hope = true
var newBoard:[Int:[Int]]?

func stepTo(_ cell:Int) -> Int {
    //print("Stepping in to \(cell)")
    moves.append(Step(cell: cell, possible: board[cell]!)) //Explicit assumes we are stepping into a valid cell with moves
    let (hope, newBoard) = removeCell(cell, from: board)
    if hope {
        board = newBoard!
        if board.count == 0 {
            print("*** Solution ***")
            dumpMoves(true)
            print()
            exit(0)
        }
        return moves[moves.count-1].possible.remove(at: 0)
    }
    return stepOut(cell)
}

func stepOut(_ cell:Int) -> Int {
    //print("Stepping out of \(cell)")
    let x = moves.remove(at: moves.count-1)
    if board[cell] == nil {
        board = addCell(x.cell, to: board, with: emptyBoard)
    }
    if moves.count == 0 {
        print("No solutions possible.")
        exit(0)
    }
    if moves[moves.count-1].possible.count == 0 {
        return stepOut(moves[moves.count-1].cell)
    } else {
        return moves[moves.count-1].possible.remove(at: moves[moves.count-1].possible.count-1)
    }
}

func nextMove(cell:Int, move:Int?, board:[Int:[Int]]) -> Int? { // Return nil if there is no next move from that cell
    let potential = board[cell]
    if move == nil { return potential?.first }
    if let idx = potential?.firstIndex(of: move!) {
        return potential?[idx+1]
    }
    return nil
}

func dumpBoard() {
    for cell in board.sorted(by: {$0.key < $1.key } ) {
        print(cell.key, terminator:" --> ")
        for otherCell in cell.value {
            print (otherCell, terminator: " ")
        }
        print()
    }
}

func dumpMoves(_ short:Bool = false) {
    for move in moves {
        if !short {
            print(move.cell, terminator:" -> ")
            for possible in move.possible {
                print(possible, terminator:" ")
            }
            print()
        } else {
            print(move.cell, terminator:" ")
        }

    }
}

let argc = CommandLine.argc

if argc == 3 {
    n = Int(CommandLine.arguments[1])!
    m = Int(CommandLine.arguments[2])!

}
print("Board of size: \(n) by \(m).")
let limit = n*m

/*
 A board is a dictionary of the cells, with the values of all possible moves from each cell.
 If a cell has already be visited, it is removed from the board.
 If any cell has no solutions, the board can no longer be solved.

 To track a given "position", you need a board, and an array of the cells moved in order to get there.
 */


//Build the empty board of a given size
for cell in 0..<limit {
    emptyBoard[cell] = knightMoves(cell)
}
board = emptyBoard

//print(emptyBoard.sorted(by: {$0.key < $1.key } ))
//print(board.sorted(by: {$0.key < $1.key } ))

/*
 Start with empty
 try a move (x) from cell (c)
 if ok, proceed with next move
 else subtract move(x), and select next move (x+1) from cell (c)
 */
var next:Int = 0
while board.count > 0 {
    next = stepTo(next)
}
