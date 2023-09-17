MINER = "mekanism:digital_miner"
CABLE = "mekanism:ultimate_logistical_transporter"
PORTER = "mekanism:quantum_entangloporter"
PICK = "minecraft:diamond_pickaxe"
MODEM = "computercraft:wireless_modem_advanced"

xHome = 1207
yHome = 70
zHome = -481

file = fs.open("quarry.status", "r")

function findItem(name)
    for slot=1,16 do
        data = turtle.getItemDetail(slot)
        if data then
            if data.name == name then
                return slot
            end
        end
    end
    return 17
end

function placeMiner()
    file = fs.open("quarry.status","w")
    file.writeLine("building")

    slotMiner = findItem(MINER)
    turtle.select(slotMiner)
    turtle.placeUp()
    
    turtle.turnRight()
    turtle.forward()
    turtle.forward()
    
    slotPorter = findItem(PORTER)
    turtle.select(slotPorter)
    turtle.placeUp()
    turtle.turnLeft()
    turtle.forward()
    
    slotCable = findItem(CABLE)
    turtle.select(slotCable)
    turtle.placeUp()
    turtle.forward()
    turtle.placeUp()
    turtle.turnLeft()
    turtle.forward()
    turtle.placeUp()
    turtle.forward()
    turtle.up()
    turtle.placeUp()
    turtle.down()
    turtle.placeUp()
    turtle.turnLeft()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.turnRight()

    file.close()
end

function breakMiner()
    file = fs.open("quarry.status","w")
    file.writeLine("breaking")

    equipPickaxe()
    
    turtle.digUp()
    turtle.turnRight()
    turtle.forward()
    turtle.forward()
    turtle.turnLeft()
    turtle.digUp()
    turtle.forward()
    turtle.digUp()
    turtle.forward()
    turtle.digUp()
    turtle.turnLeft()
    turtle.forward()
    turtle.digUp()
    turtle.forward()
    turtle.digUp()
    turtle.up()
    turtle.digUp()
    turtle.down()
    turtle.turnLeft()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.turnRight()
    
    equipModem()
    
    file.close()
end

function equipPickaxe()
    slot = findItem(PICK)
    if slot == 17 then
        -- assume pickaxe is already equipped
        return   
    end
    
    turtle.select(slot)
    turtle.equipRight()
end

function equipModem()
    slot = findItem(MODEM)
    
    if slot == 17 then
        return
    end
    
    turtle.select(slot)
    turtle.equipRight()
end

function startMiner()
    miner = peripheral.wrap("top")
    miner.start()
end

function waitForMiner()
    file = fs.open("quarry.status","w")
    file.writeLine("waiting")
    file.close()
    miner = peripheral.wrap("top")
    while miner.getToMine() > 0 do
        os.sleep(10)
    end
end

function move(count, startVal)
    file = fs.open("quarry.status","w")
    file.writeLine("moving")
    for i=1,tonumber(count) do
        suc = turtle.forward()
        fail = fail or suc
        startVal = startVal + 1
        file.writeLine(startVal)
    end
    file.close()
    return fail
end

function home()
    
    x1, y1, z1 = gps.locate(5)
    turtle.forward()
    x2, y2, z2 = gps.locate(5)
    dx = x2 - x1
    dz = z2 - z1
    
    xDelta = xHome - x2
    yDelta = yHome - y2
    zDelta = zHome - z2
    
    if (dx == 1) then
        if (xDelta < 0) then
            turtle.turnRight()
            turtle.turnRight()
        end
    end
    if (dx == -1) then
        if (xDelta > 0) then
            turtle.turnRight()
            turtle.turnRight()
        end
    end
    if (dz == 1) then
        if (xDelta > 0) then
            turtle.turnLeft()
        elseif(xDelta < 0) then
            turtle.turnRight()
        end
    end
    if (dz == -1) then
        if (xDelta > 0) then
            turtle.turnRight()
        elseif(xDelta < 0) then
            turtle.turnLeft()
        end
    end
    
    for i=1, math.abs(xDelta) do
        turtle.forward()
    end
    
    if (xDelta > 0) then
        if (zDelta > 0) then
            turtle.turnRight()
        elseif(zDelta < 0) then
            turtle.turnLeft()
        end
    elseif(xDelta < 0) then
        if (zDelta > 0) then
            turtle.turnLeft()
        elseif(zDelta < 0) then
            turtle.turnRight()
        end
    end
    
    for i=1,math.abs(zDelta) do
        turtle.forward()
    end 
    
    for i=1,math.abs(yDelta) do
        if (yDelta > 0) then
            turtle.up()
        else
            turtle.down()
        end
    end
end



function handleModem()
    while true do
        modem = peripheral.wrap("right")
        miner = peripheral.wrap("top")
        modem.open(1)
        local event, mS, sCh, rCh, msg, d = os.pullEvent("modem_message")
        
        
        cmd = msg[1]
        if (cmd == "home") then
            homing = true
            return
        elseif (cmd == "setHome") then
            xHome = msg[2]
            yHome = msg[3]
            zHome = msg[4]
        elseif (cmd == "setSilk") then
            miner.stop()
            miner.reset()
            miner.setSilkTouch(msg[2])
            miner.start()
        elseif (cmd == "addFilter") then
            miner.stop()
            miner.reset()
            miner.addFilter(msg[2])
            miner.start()
        elseif (cmd == "removeFilter") then
            miner.stop()
            miner.reset()
            miner.removeFilter(msg[2])
            miner.start()
        elseif (cmd == "getPos") then
            x, y, z = gps.locate(5)
            coords = {x, y, z}
            modem.transmit(99, 1, coords)
        end
    end
end

function panic(message)

end


-- If miner is not yet built -> build miner
line = file.readLine()
if (line == "moving") then
    -- Find out how much steps already have been taken
    newLine = file.readLine()
    if (newLine == nil) then
        movesTaken = 0
    end

    while (newLine) do
        movesTaken = tonumber(newLine)
        newLine = file.readLine()
    end

    move(32 - movesTaken, movesTaken)
    placeMiner()
end

if (line == "building" or line == "breaking") then
    panic(line)
end


while true do
    startMiner()
    parallel.waitForAny(waitForMiner, handleModem)
    waitForMiner()
    breakMiner()
    if (homing) then
        home()
        break
    end
    
    move(32, 0)
    placeMiner()
end
