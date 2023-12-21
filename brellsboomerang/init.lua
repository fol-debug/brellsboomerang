-- EQFoli 2023.12.05
-- Brells Boomerang
-- COMMENT
-- COMMENT
-- COMMENT
-- COMMENT

local mq = require('mq')

-- Scriber Write format purloined.
local Write = require('brellsboomerang.Write')

Write.prefix = 'brellsboomerang'
Write.loglevel = 'info'

local DoLoop = true
local DoLoopZonedOut = true
local luaName = 'brellsboomerang'
local teamSelected = ''
local loopState = {
	[0] = "start",
	[1] = "requestMission",
	[2] = "travelMission",
	[3] = "startEvent",
	[4] = "doEvent",
	[5] = "zonedOut",
	[6] = "waitingForRepop"
}

local currentState = 0
local groupSize = 0
local groupLeader = mq.TLO.Group.Leader
local groupLeaderID = mq.TLO.Group.Leader.ID
local questGiver = 'Gilbot the Magnificent'
local myID = mq.TLO.Me.ID

local function callback(line, arg1, arg2, arg3)
	COOLDOWN = arg3
	NOTIMER = arg1
end

local function callbackCombat(line, arg1)
	ENDED = arg1
end

local function checkCooldown()
	mq.cmd('/tasktimer')
	mq.delay('5s')
	mq.doevents()
end

mq.event("tasktimer", "'Brell's Arena - Boomerang Brawl!' replay timer: #1#d:#2#h:#3#m remaining.", callback)
mq.event("eventend", "The results of the contest are as #1", callbackCombat)
-- mq.event("notimer", "#1 currently have any task timers.", callback)

local function checkTeam()
	local yellow = mq.TLO.FindItemCount('Yellow Boomerang')() -- Yellow Boomerang
	local blue = mq.TLO.FindItemCount('Blue Boomerang')() -- Blue Boomerang
	local red = mq.TLO.FindItemCount('Red Boomerang')() -- Red Boomerang
	if yellow == 1 and blue == 1 then
		TEAMCOLOR = 'Red'
		MOBLEVEL1 = 86
		MOBLEVEL2 = 84
	elseif yellow == 1 and red == 1 then
		TEAMCOLOR = 'Blue'
		MOBLEVEL1 = 86
		MOBLEVEL2 = 89
	elseif blue == 1 and red == 1 then
		TEAMCOLOR = 'Yellow'
		MOBLEVEL1 = 89
		MOBLEVEL2 = 84
	end
end

local function checkforPowderKeg()
	local checkid = mq.TLO.NearestSpawn(string.format('race "powder keg"')).ID()
	--print(mq.TLO.NearestSpawn(string.format('race "powder keg"')).ID())
	--print(checkid)
	local distance = mq.TLO.NearestSpawn(string.format('race "powder keg"')).Distance()
	local y = mq.TLO.NearestSpawn(string.format('race "powder keg"')).Y()
	local x = mq.TLO.NearestSpawn(string.format('race "powder keg"')).X()
	if (checkid and distance ~= nil and distance<50) then
		mq.cmd('/squelch /nav pause')
		mq.cmdf('/squelch /face fast nolook loc %s, %s', y, x)
		print('Barrel Detected')
		mq.cmd('/squelch /keypress back hold')
		mq.delay(500)
		mq.cmd('/squelch /keypress back')
		if math.random(1,2) == 1 then
			mq.cmdf('/squelch /keypress STRAFE_LEFT hold')
			mq.delay(500)
			mq.cmdf('/squelch /keypress STRAFE_LEFT')
		else
			mq.cmdf('/squelch /keypress STRAFE_RIGHT hold')
			mq.delay(500)
			mq.cmdf('/squelch /keypress STRAFE_RIGHT')
		end
		mq.cmd('/squelch /nav pause')
	end
end

local function AmIFeigned()
	if(mq.TLO.Me.Feigning() == 1) then
		Write.Info('\a-gStunned and feigned. Standing when ready.')
		mq.delay('3s')
		mq.cmd('/stand')
	end
end

local function isCombatNavActive()
	while mq.TLO.Navigation.Active() do
		mq.cmd('/stand')
		AmIFeigned()
		checkforPowderKeg()
		mq.delay(10)
	end
end

local function isNPC(spawn)
    return spawn.Type() == 'NPC'
end

local function NPCLevel(spawn)
	return spawn.Level()
end

local function NPCId(spawn)
	return spawn.ID()
end

local function isempty(s)
	return s == nil or s == ''
  end

local function combatRoutine(TEAMCOLOR, MOBLEVEL)
	-- used for testing MOBLEVEL = 50
	COMBATACTIVE = true
	mq.cmd('/target clear')
	checkCooldown()

    local allSpawns = mq.getAllSpawns()
    for k, v in pairs(allSpawns) do
        if(isNPC(v) == true) then
        	local spawnMaster = mq.TLO.Spawn('BRADiscusController')()
        	--local spawnMaster = null
        	--print(spawnMaster)
	        while spawnMaster ~= NULL do
                AmIFeigned()
                if(TEAMCOLOR == 'Red') then
                    AmIFeigned()
                    if(NPCLevel(v) == MOBLEVEL1) then
                        --print(NPCLevel(v))
                        --print(NPCId(v))
                        mq.cmdf('/squelch /target id %s', NPCId(v))
                        mq.cmdf('/squelch /nav spawn id %s | dist=30', NPCId(v))
                        AmIFeigned()
                        isCombatNavActive()
                        --mq.cmdf('/squelch /nav stop')
                        mq.delay('1s')
                        mq.cmdf('/squelch /face fast nolook')
                        if mq.TLO.FindItem('Yellow Boomerang').TimerReady() == 0 then
                            mq.cmdf('/squelch /cast item "Yellow Boomerang"')
                        else
                            mq.delay('1s')
                            mq.cmdf('/squelch /cast item "Yellow Boomerang"')
                        end
                        AmIFeigned()
                    elseif(NPCLevel(v) == MOBLEVEL2) then
                        --print(NPCLevel(v))
                        --print(NPCId(v))
                        mq.cmdf('/squelch /target id %s', NPCId(v))
                        mq.cmdf('/squelch /nav spawn id %s | dist=30', NPCId(v))
                        AmIFeigned()
                        isCombatNavActive()
                        --mq.cmdf('/squelch /nav stop')
                        mq.delay('1s')
                        mq.cmdf('/squelch /face fast nolook')
                        if mq.TLO.FindItem('Blue Boomerang').TimerReady() == 0 then
                            mq.cmdf('/squelch /cast item "Blue Boomerang"')
                        else
                            mq.delay('1s')
                            mq.cmdf('/squelch /cast item "Blue Boomerang"')
                        end
                        AmIFeigned()
                    end
                elseif(TEAMCOLOR == 'Blue') then
                    AmIFeigned()
                    if(NPCLevel(v) == MOBLEVEL1) then
                        AmIFeigned()
                        --print(NPCLevel(v))
                        --print(NPCId(v))
                        mq.cmdf('/squelch /target id %s', NPCId(v))
                        mq.cmdf('/squelch /nav spawn id %s | dist=30', NPCId(v))
                        AmIFeigned()
                        isCombatNavActive()
                        --mq.cmdf('/squelch /nav stop')
                        mq.delay('1s')
                        mq.cmdf('/squelch /face fast nolook')
                        if mq.TLO.FindItem('Yellow Boomerang').TimerReady() == 0 then
                            mq.cmdf('/squelch /cast item "Yellow Boomerang"')
                        else
                            mq.delay('1s')
                            mq.cmdf('/squelch /cast item "Yellow Boomerang"')
                        end
                        AmIFeigned()
                    elseif(NPCLevel(v) == MOBLEVEL2) then
                        AmIFeigned()
                        --print(NPCLevel(v))
                        --print(NPCId(v))
                        mq.cmdf('/squelch /target id %s', NPCId(v))
                        mq.cmdf('/squelch /nav spawn id %s | dist=30', NPCId(v))
                        AmIFeigned()
                        isCombatNavActive()
                        --mq.cmdf('/squelch /nav stop')
                        mq.delay('1s')
                        mq.cmdf('/squelch /face fast nolook')
                        if mq.TLO.FindItem('Red Boomerang').TimerReady() == 0 then
                            mq.cmdf('/squelch /cast item "Red Boomerang"')
                        else
                            mq.delay('1s')
                            mq.cmdf('/squelch /cast item "Red Boomerang"')
                        end
                        AmIFeigned()
                    end
                else
                    AmIFeigned()
                    if(NPCLevel(v) == MOBLEVEL1) then
                        AmIFeigned()
                        --print(NPCLevel(v))
                        --print(NPCId(v))
                        mq.cmdf('/squelch /target id %s', NPCId(v))
                        mq.cmdf('/squelch /nav spawn id %s | dist=30', NPCId(v))
                        AmIFeigned()
                        isCombatNavActive()
                        --mq.cmdf('/squelch /nav stop')
                        mq.delay('1s')
                        mq.cmdf('/squelch /face fast nolook')
                        if mq.TLO.FindItem('Red Boomerang').TimerReady() == 0 then
                            mq.cmdf('/squelch /cast item "Red Boomerang"')
                        else
                            mq.delay('1s')
                            mq.cmdf('/squelch /cast item "Red Boomerang"')
                        end
                        AmIFeigned()
                    elseif(NPCLevel(v) == MOBLEVEL2) then
                        AmIFeigned()
                        --print(NPCLevel(v))
                        --print(NPCId(v))
                        mq.cmdf('/squelch /target id %s', NPCId(v))
                        mq.cmdf('/squelch /nav spawn id %s | dist=30', NPCId(v))
                        AmIFeigned()
                        isCombatNavActive()
                        --mq.cmdf('/squelch /nav stop')
                        mq.delay('1s')
                        mq.cmdf('/squelch /face fast nolook')
                        if mq.TLO.FindItem('Blue Boomerang').TimerReady() == 0 then
                            mq.cmdf('/squelch /cast item "Blue Boomerang"')
                        else
                            mq.delay('1s')
                            mq.cmdf('/squelch /cast item "Blue Boomerang"')
                        end
                        AmIFeigned()
                end
            end
        end
    end
end
print('Combat Done')
end

local function doBoomerangCombat()
	checkTeam()
	Write.Info('\a-gOk, you are on team %s, lets fight!', TEAMCOLOR)
	combatRoutine(TEAMCOLOR, MOBLEVEL)
end

-- Purloined from Easy.lua and PriceOfKnowledge.lua
local function campFire()

    -- Destroy our current campfire if we have one and I'm not dead.
    if mq.TLO.Me.Fellowship.Campfire() == true and not mq.TLO.Me.Hovering() then

        -- Open fellowship window.
        if (not mq.TLO.Window('FellowshipWnd').Open()) then mq.TLO.Window('FellowshipWnd').DoOpen() end
        mq.delay(1000)

        -- Pick the campfire tab
        mq.TLO.Window('FellowshipWnd/FP_Subwindows').SetCurrentTab(2)
        mq.delay(1000)

        -- Click destroy campsite.
        mq.TLO.Window('FellowshipWnd/FP_Subwindows/FP_DestroyCampsite').LeftMouseUp()
        mq.delay(3000, function ()
            return mq.TLO.Window('ConfirmationDialogBox').Open()
        end)
        if (mq.TLO.Window('ConfirmationDialogBox').Open()) then
            mq.TLO.Window('ConfirmationDialogBox/Yes_Button').LeftMouseUp()
        end

        -- Wait a bit to make sure campfire gone
        mq.delay(3000, function ()
            return not mq.TLO.Me.Fellowship.Campfire()
        end)
    end

    -- We shouldn't have any campfire, and not be dead, and 2 more fellowship members close
    if mq.TLO.Me.Fellowship.Campfire() == false and not mq.TLO.Me.Hovering() and mq.TLO.SpawnCount('radius 50 fellowship')() > 2 then
        
        -- open the fellowship window if it isn't already
        if (not mq.TLO.Window('FellowshipWnd').Open()) then mq.TLO.Window('FellowshipWnd').DoOpen() end
        mq.delay(1000)

        -- Pick the campfire tab
        mq.TLO.Window('FellowshipWnd/FP_Subwindows').SetCurrentTab(2)
        mq.delay(1000)

        -- Click refresh list.
        mq.TLO.Window('FellowshipWnd/FP_Subwindows/FP_RefreshList').LeftMouseUp()
        mq.delay(1000)

        -- Pick the first item in list
        mq.TLO.Window('FellowshipWnd/FP_Subwindows/FP_CampsiteKitList').Select(1)
        mq.delay(1000)
        
        -- Click create camp
        mq.TLO.Window('FellowshipWnd/FP_Subwindows/FP_CreateCampsite').LeftMouseUp()
        mq.delay(3000, function ()
            return mq.TLO.Me.Fellowship.Campfire()
        end)
        mq.delay(1000)
        
        mq.TLO.Window('FellowshipWnd').DoClose()
        if mq.TLO.Me.Fellowship.Campfire() then
            Write.Info('\a-gWe got a fire going.')
        else
            Write.Warn('\a-gEnd of campfire function but no campfire.  Continuing but you\'ll have to wait to get kicked.')
        end

        mq.delay(500)
    end
end

local function checkGroup()
    --
	local myID = mq.TLO.Me.ID
	local groupLeaderID = mq.TLO.Group.Leader.ID
	groupSize = mq.TLO.Group()+1
	if groupSize < 3 then
		Write.Info('\a-gToo few members. Minimum amount of members for this missions is 3. Get some more friends!')
		mq.cmdf('/squelch /dgga /lua stop %s', luaName)
	end
	if groupSize >= 3 then
		Write.Info('\a-gAwww yiss, enough members. Lets check if they are present.')
		if mq.TLO.SpawnCount('group radius 100')() < groupSize then
			Write.Info('\a-gAll members of group are not present. Lets get them here.')
			if myID == groupLeaderID then
				mq.cmdf('/squelch /dgga /nav spawn id %s', groupLeaderID)
				mq.delay(10000)
			end
		else
			Write.Info('\a-gEveryone is present. Lets continue.')
		end	
	end
end

local function checkGroupStatus()
    --
	local myID = mq.TLO.Me.ID
	local groupLeaderID = mq.TLO.Group.Leader.ID
	groupSize = mq.TLO.Group()+1
	if mq.TLO.SpawnCount('group radius 100')() < groupSize then
		Write.Info('\a-gAll members of group are not present. Lets get them here.')
		if myID == groupLeaderID then
			mq.cmdf('/squelch /dgga /nav spawn id %s', groupLeaderID)
			mq.delay(10000)
		end
	else
		Write.Info('\a-gEveryone is present. Lets head back to Campfire.')
	end
end

-- Thanks Sic!
local function checkInvis()
	-- 
	local invisStatus = mq.TLO.Me.Invis()
	if invisStatus then
		local invis = 0
		if mq.TLO.Me.Invis(1)() then
			invis = invis + 1
		end

		if mq.TLO.Me.Invis(2)() then
			invis = invis + 2
		end

		if invis == 3 then
			-- both invis types; green
			PlayerInvisStatus = 1
		elseif invis == 2 then
			-- ivu; blue
			PlayerInvisStatus = 0
		elseif invis == 1 then
			-- regular invis; pink
			PlayerInvisStatus = 1
		end
	end
end

local function checkIfMacroRunning()
	while mq.TLO.Macro() == "boomerang.mac" do
		Write.Info('\a-gMacro is still running. Checking every 2 minutes.')
		mq.delay('2m')
	end
end

local function isInstanceOnCooldown()
	checkCooldown()
	if(COOLDOWN) then
		CD = tonumber(COOLDOWN)
	elseif(isempty(COOLDOWN)) then
		CD = 0
	end
	while tonumber(CD) > 0 do
		--print(CD)
		local coolinminutes = tonumber(CD) + 5
		Write.Info('\a-gInstance is currently cooling down. %s minutes remaining. Going in %s minutes. Updating every 3 minutes.', CD, coolinminutes)
		mq.delay('3m')
		CD = CD - 3
	end
	--if(NOTIMER) then
	--	print('No tasktimers. Good. We will go immediately.')
	--	mq.delay('10s')
	--else
	print('Continuing in 5 minutes. Strap in.')
	mq.delay('5m')
	--end
end

local function checkInvisAndAct()
	local playerName = mq.TLO.Me.Name()
	checkInvis()
	if PlayerInvisStatus == nil then
		Write.Info('\a-gYou are not invis. Will check for Cloudy Pots. If none are available, LUA will end.')
		if mq.TLO.FindItemCount('Cloudy Potion')() == 0 then
			mq.cmdf('/dgt all %s is missing Cloudy Potions. Ending LUA.', playerName)
			mq.delay(5000)
			mq.cmdf('/squelch /dgga /lua stop %s', luaName)
		else
			mq.cmd('/squelch /casting "Cloudy Potion"')
			Write.Info('\a-gInvis up.')
		end
	end
end

local function isNavActive()
	while mq.TLO.Navigation.Active() do
		mq.delay(100)
	end
end

local function DoBoomerang()
	local areWeReady = true
	-- load necessary plugins
	mq.cmd('/squelch /dgga /plugin mq2dannet')
	mq.cmd('/squelch /dgga /plugin mq2nav')
	mq.cmd('/squelch /autoinventory')
	mq.cmd('/squelch /dgga /plugin mq2status')
	mq.delay(1000)
	Write.Info('\a-gWelcome to Boomerang Hell! Please be advised that we expect you to have Cloudy Potions available.')


    -- Updating state
	Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
	currentState = currentState+1
	mq.delay(5000)

	if loopState[currentState] == "requestMission" then
	--Check to see if we're in the correct zone.
	if mq.TLO.Zone.ID() == 480 then
		local correctZone = true
		Write.Info('\a-gCorrect zone. Next step; locate correct NPC.')
		mq.delay(5000)
	else
		Write.Info('\a-gWrong zone. Go to Brells Rest. Exiting LUA.')
		mq.delay(5000)
		mq.cmdf('/squelch /dgga /lua stop %s', luaName)
	end

	--check group
	checkGroup()
	-- remove afk
	mq.cmdf('/squelch /dgga /afk off')

	--Check to see if we're close to the npc. If not, move to it.
	if mq.TLO.SpawnCount('magnificent radius 50')() > 0 then
		local closeToNPC = true
		mq.cmdf('/squelch /dgga /nav locyx 169 417 -23')
	else
		mq.cmdf('/squelch /dgga /nav locyx 169 417 -23')
	end
	-- checking cooldown of task, waiting if on cooldown
	mq.doevents()
	isInstanceOnCooldown()
		if myID ~= groupLeaderID then
			mq.delay('10s')
		end
		if myID == groupLeaderID then
			mq.cmdf('/squelch /tar magnificent')
			mq.delay('1s')
			mq.cmdf('/squelch /say crazy')
			mq.delay('1s')
			mq.cmdf('/squelch /say specific')
			-- Setting up campfire.
			mq.delay('2s')
			-- Settings monsters, me first, then loop through group.
			mq.cmdf('/notify TaskTemplateSelectWnd TaskTemplateSelectListRequired listselect 1')
			mq.delay('1s')
			mq.cmdf('/squelch /notify TaskTemplateSelectWnd TaskTemplateSelectAcceptButton LeftMouseUp')
			-- Loop to get others to choose.
			i = 1
			-- Since template 1 is defined as groupleaders, we start at two for the remaining team.
			y = 2
			gSize = groupSize - 1
			for i=1,gSize do
				gMemberName = mq.TLO.Group.Member(i).CleanName()
				mq.delay('1s')
				Write.Info('\a-gAssigning monster to %s', gMemberName)
				mq.cmdf('/squelch /dex %s /notify TaskTemplateSelectWnd TaskTemplateSelectListRequired listselect %s', gMemberName, y)
				mq.delay('1s')
				mq.cmdf('/squelch /dex %s /notify TaskTemplateSelectWnd TaskTemplateSelectAcceptButton LeftMouseUp', gMemberName)
				y = y + 1
			end
			Write.Info('\a-gChecking and creating Fellowship Campfire.')
			campFire()
		end
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(2000)
	end

	if loopState[currentState] == "travelMission" then
		Write.Info('\a-gMoving to instance.')
		checkInvisAndAct()
		-- moveto #1
		mq.cmdf('/squelch /nav locyx -20 260')
		isNavActive()
		-- moveto #2
		mq.cmdf('/squelch /nav locyx -187 229')
		isNavActive()
		-- moveto #3
		mq.cmdf('/squelch /nav locyx -135 18')
		isNavActive()
		-- moveto #4
		mq.cmdf('/squelch /nav locyx -156 -244')
		isNavActive()
		-- moveto #5 - door
		mq.cmdf('/squelch /nav locyx -239 -567')
		isNavActive()


		-- Syncing up group.
		if myID ~= groupLeaderID then
			mq.delay(5000)
		end
		if myID == groupLeaderID then
			mq.delay(1000)
		end
		mq.cmdf('/squelch /doortarget')
		-- Click door and enter.
		mq.cmdf('/squelch /click left door')
		mq.cmdf('/squelch /click left door')
		mq.cmdf('/squelch /click left door')
		-- Wait for zonein
		mq.delay(30000)
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(5000)
	end


	if loopState[currentState] == "startEvent" then
		if mq.TLO.Zone.ID() == 492 then
			Write.Info('\a-gGroupleader starting event.')
			if myID == groupLeaderID then
				mq.cmdf('/squelch /nav spawn npc Gilbot')
				isNavActive()
				mq.cmdf('/squelch /tar Gilbot')			
				mq.cmdf('/squelch /say start')
			end
		elseif mq.TLO.Zone.ID() ~= 492 then
			Write.Info('\a-gSomething has gone wrong. We are in the wrong zone for some reason. Exiting LUA and killing task.')
			mq.delay(5000)
			mq.cmdf('/squelch /dgga /lua stop %s', luaName)
			mq.cmdf('/squelch /dgga /taskquit')
		end

		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(2000)
	end

	if loopState[currentState] == "doEvent" then
		Write.Info('\a-gRunning combat routine.')
		if mq.TLO.Zone.ID() == 492 then
			doBoomerangCombat()
		else
			Write.Info('\a-gNot in the correct zone. Whats going on?')
		end
		-- Quitting task and zoning out
		mq.cmdf('/taskquit')
		Write.Info('\a-gInstance ending. Waiting for port out.')
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(1000)
	end

	if loopState[currentState] == "zonedOut" then
		-- Check to see if we have zoned out.
		while DoLoopZonedOut do
			if mq.TLO.Zone.ID() == 480 then
				DoLoopZonedOut = false
			end
		end
		if mq.TLO.Zone.ID() == 480 then
			local correctZone = true
			Write.Info('\a-gCorrect zone. Next step; make sure we end macro, remove invis, and cast Insignia.')
			checkGroupStatus()
			if mq.TLO.Me.Fellowship.Campfire() == false then
				mq.delay('1s')
				-- nav back to camp, but first, check invisstatus
				checkInvisAndAct()
				mq.delay('5s')
				-- moveto #1
				mq.cmdf('/squelch /nav locyx -156 -244')
				isNavActive()
				-- moveto #2
				mq.cmdf('/squelch /nav locyx -135 18')
				isNavActive()
				-- moveto #3
				mq.cmdf('/squelch /nav locyx -187 229')
				isNavActive()					
				-- moveto #4
				mq.cmdf('/squelch /nav locyx -20 260')
				isNavActive()
				-- moveto camp
				mq.cmdf('/squelch /nav locyx 169 417 -23')
				isNavActive()
			else
				mq.delay('1s')
				mq.cmdf('/squelch /makemevisible')
				mq.delay('1s')
				mq.cmdf('/squelch /casting "Fellowship Registration Insignia"')
			end
			mq.delay('2m')
		else
			Write.Info('\a-gSomething has gone wrong. Either dead/LD or plain missing. Ending LUA.')
			mq.delay(5000)
			mq.cmdf('/squelch /dgga /lua stop %s', luaName)
		end
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(1000)
	end
	
	if loopState[currentState] == "waitingForRepop" then
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState-5])
		currentState = 0
		mq.delay(1000)
	end
		
end

local function test()
    local spawnMaster = mq.TLO.Spawn('gilbot')()
    --local spawnMaster = null
    --print(spawnMaster)
    while spawnMaster ~= NULL do
        print(spawnMaster)
        print('test')
        mq.delay('3s')
    end
end

while DoLoop do
	--pause_script()
	mq.doevents()
	DoBoomerang()
	--test()
	mq.delay('5s')
end