import tables
import play
import game
import times
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

proc settingsFromParams:tuple[nrOfGames,nrOfPlayers:int] =
  let prms = getParams()
  (result.nrOfGames,result.nrOfPlayers) = (100,6)
  if prms.len == 1:
    result.nrOfGames = prms[0]
  elif prms.len > 1: (result.nrOfGames,result.nrOfPlayers) = (prms[0],prms[1])

proc addVisits(visitsCount:var Visits,addVisits:Visits) =
  for i in 1..60: visitsCount[i] += addVisits[i]

proc statsToStr(nrOfGames,turnCount:int,time:float):string =
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
  gameSettings = settingsFromParams()

var
  turnCount = 0
  visitsCounts:Visits
  cashedCards:CountTable[string]

initGame()
setNrOfComputerPlayers gameSettings.nrOfPlayers
statGame = true

for gameNr in 1..gameSettings.nrOfGames:
  echo "game nr: ",gameNr
  setupGame()
  startGame()
  while not gameWon:
      aiTakeTurn()
  echo "game won : ",turnPlayer.cash," cash, in ",turn.nr," turns"
  if recordStats:
    turnCount += turn.nr
    visitsCounts.addVisits reportedVisitsCount()
    cashedCards.merge reportedCashedCards()

if recordStats:
  let
    cards = cashedCards.pairs.toSeq.toStr()
    visits = visitsCounts.toStr()
    stats = statsToStr(gameSettings.nrOfGames,turnCount,time)
  writeFile(fileName,cards&visits&stats)
  echo cards
  echo visits
  echo stats
  echo "Wrote to file: "&fileName

echo ""
echo "Stat - parameter usage:"
echo "1st param containing a number = nrOfGames   (default = 100)"
echo "2nd param containing a number = nrOfPlayers (default = 6)"
echo "-v = Verbose: print each turn played - in detail"

