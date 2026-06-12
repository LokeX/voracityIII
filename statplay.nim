import sugar
import tables
import play
import game
import times
import algorithm
import os
import stat
import strutils
import sequtils
import misc

proc getParams:seq[int] =
  for prm in commandLineParams():
    try: result.add prm.parseInt
    except:discard
    if result.len == 2:
      break

proc setSettings(prms:openArray[int]):tuple[nrOfGames,nrOfPlayers:int] =
  (result.nrOfGames,result.nrOfPlayers) = (100,6)
  if prms.len == 1:
    result.nrOfGames = prms[0]
  elif prms.len > 1: (result.nrOfGames,result.nrOfPlayers) = (prms[0],prms[1])

proc toStr(cashedCards:CountTable[string]):string =
  result.add "Cashed cards:\n"
  let cashedCards:CashedCards = cashedCards.pairs.toSeq
  for (title,count) in cashedCards.sorted (a,b) => b.count - a.count:
    result.add title&": "&($count)&"\n"

proc addVisits(visitsCount:var Visits,addVisits:Visits) =
  for i in 1..60:
    visitsCount[i] += addVisits[i]

proc toStr(visitsCounts:Visits):string =
  result.add "Square visits:\n"
  result.add(
    toSeq(1..60)
    .mapIt((it,board[it].name,visitsCounts[it]))
    .sortedByIt(it[2])
    .mapIt(it[1]&" Nr. "&($it[0])&": "&($it[2]))
    .join "\n"
  )

proc statsStr(nrOfGames,turnCount:int,time:float):string =
  result.add "Time: "&timeFmt(cpuTime()-time)&"\n"
  result.add "Games: "&($nrOfGames)&"\n"
  result.add "Turns: "&($turnCount)&"\n"
  result.add "avgTurns: "
  result.add formatFloat(float(turnCount)/float(nrOfGames),ffDecimal,2)&"\n"

proc setNrOfComputerPlayers(nrOfPlayers:int) =
  for i in 0..playerKinds.high:
    if i < nrOfPlayers:
      playerKinds[i] = Computer
    else: playerKinds[i] = None


const
  fileName = "dat\\statlog.txt"

let
  time = cpuTime()
  settings = getParams().setSettings()

var
  turnCount = 0
  visitsCounts:Visits
  cashedCards:CountTable[string]

initGame()
setNrOfComputerPlayers settings.nrOfPlayers
verbose = commandLineParams().anyIt it.toLower == "-v"
statGame = true

for gameNr in 1..settings.nrOfGames:
  setupGame()
  startGame()
  echo "game nr: ",gameNr
  while not gameWon:
      aiTakeTurn()
  if recordStats:
    turnCount += turnReport.turnNr
    recordTurnReport()
    visitsCounts.addVisits reportedVisitsCount()
    cashedCards.merge reportedCashedCards()

if recordStats:
  let
    cards = cashedCards.toStr()
    visits = visitsCounts.toStr()
    stats = statsStr(settings.nrOfGames,turnCount,time)
  writeFile(fileName,cards&visits&stats)
  echo cards
  echo visits
  echo stats
  echo "Wrote to file: "&fileName
