-- EQFoli 2023.12.05
-- Script to purchase shit.
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
local luaName = 'brellsboomerang'
local teamSelected = ''
local loopState = {
	[0] = "start",
	[1] = "requestMission",
	[2] = "travelMission",
	[3] = "startEvent",
	[4] = "doEvent",
	[5] = "waitingForRepop"
}

local currentState = 0
local groupSize = 0
local groupLeader = mq.TLO.Group.Leader
local groupLeaderID = mq.TLO.Group.Leader.ID
local questGiver = 'Gilbot the Magnificent'
local myID = mq.TLO.Me.ID

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
        mq.delay(5000, function ()
            return mq.TLO.Window('ConfirmationDialogBox').Open()
        end)
        if (mq.TLO.Window('ConfirmationDialogBox').Open()) then
            mq.TLO.Window('ConfirmationDialogBox/Yes_Button').LeftMouseUp()
        end

        -- Wait a bit to make sure campfire gone
        mq.delay(5000, function ()
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
        mq.delay(5000, function ()
            return mq.TLO.Me.Fellowship.Campfire()
        end)
        mq.delay(1000)
        
        mq.TLO.Window('FellowshipWnd').DoClose()
        if mq.TLO.Me.Fellowship.Campfire() then
            Write.Info('\a-gWe got a fire going.')
        else
            Write.Warn('\a-gEnd of campfire function but no campfire.  Continuing but you\'ll have to wait to get kicked.')
        end

        mq.delay(1000)
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
				mq.cmdf('/squelch /dge /nav spawn id %s', groupLeaderID)
				mq.delay(10000)
			end
		else
			Write.Info('\a-gEveryone is present. Lets continue.')
		end	
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

local function DoBoomerang()
	local areWeReady = true
	-- load necessary plugins
	mq.cmd('/squelch /dgga /plugin mq2dannet')
	mq.cmd('/squelch /dgga /plugin mq2nav')
	mq.cmd('/squelch /autoinventory')
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
	checkInvisAndAct()

	--Check to see if we're close to the npc. If not, move to it.
	if mq.TLO.SpawnCount('magnificent radius 50')() > 0 then
		local closeToNPC = true
	else
		mq.cmdf('/squelch /dgga /nav locyx 169 417 -23')
	end
		if myID ~= groupLeaderID then
			mq.delay(26000)
		end
		if myID == groupLeaderID then
			mq.cmdf('/squelch /tar magnificent')
			mq.delay(2000)
			mq.cmdf('/squelch /say crazy')
			mq.delay(2000)
			mq.cmdf('/squelch /say specific')
			-- Setting up campfire.
			mq.delay(4000)
			-- Settings monsters, me first, then loop through group.
			mq.cmdf('/notify TaskTemplateSelectWnd TaskTemplateSelectListRequired listselect 1')
			--mq.cmdf('/squelch /lua stop brellsboomerang')
			mq.delay(2000)
			mq.cmdf('/squelch /notify TaskTemplateSelectWnd TaskTemplateSelectAcceptButton LeftMouseUp')
			-- Loop to get others to choose.
			i = 1
			-- Since template 1 is defined as groupleaders, we start at two for the remaining team.
			y = 2
			gSize = groupSize - 1
			for i=1,gSize do
				gMemberName = mq.TLO.Group.Member(i).CleanName()
				mq.delay(2000)
				Write.Info('\a-gAssigning monster to %s', gMemberName)
				mq.cmdf('/squelch /dex %s /notify TaskTemplateSelectWnd TaskTemplateSelectListRequired listselect %s', gMemberName, y)
				mq.delay(2000)
				mq.cmdf('/squelch /dex %s /notify TaskTemplateSelectWnd TaskTemplateSelectAcceptButton LeftMouseUp', gMemberName)
				y = y + 1
			end
			Write.Info('\a-gChecking and creating Fellowship Campfire.')
			campFire()
			mq.delay(10000)
		end
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(5000)
	end

	if loopState[currentState] == "travelMission" then
		Write.Info('\a-gMoving to instance.')
		checkInvisAndAct()
		mq.cmdf('/squelch /nav locyx -239 -567')
		mq.delay(30000)
		-- Syncing up group.
		if myID ~= groupLeaderID then
			mq.delay(5000)
		end
		if myID == groupLeaderID then
			mq.delay(1000)
		end
		mq.cmdf('/squelch /doortarget')
		-- Making sure we actually get the group to click the door.
		mq.cmdf('/squelch /click left door')
		mq.cmdf('/squelch /click left door')
		mq.cmdf('/squelch /click left door')
		mq.delay(30000)
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(5000)
	end


	if loopState[currentState] == "startEvent" then
		Write.Info('\a-gGroupleader starting event.')
		if myID == groupLeaderID then
			mq.cmdf('/squelch /target Gilbot')
			mq.cmdf('/squelch /nav target')
			mq.delay(2000)
			mq.cmdf('/squelch /say start')
		end
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(5000)
	end

	if loopState[currentState] == "doEvent" then
		Write.Info('\a-gRunning brellsboomerang.mac -- do not interfere. Will campfire once done and restart within 40 minutes.')
		mq.cmdf('/squelch /mac boomerang')
		mq.delay(900000)
		mq.cmdf('/squelch /makemevisible')
		mq.delay(1000)
		mq.cmdf('/squelch /casting "Fellowship Registration Insignia"')
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState+1])
		currentState = currentState + 1
		mq.delay(1000)
	end
	
	if loopState[currentState] == "waitingForRepop" then
		Write.Info('\a-gWe are currently idling. Repop in about 25 minutes. Will run in 30 mins.')
		mq.delay(1800000)
		-- Updating state
		Write.Info('\a-gNext up: %s=>%s', loopState[currentState], loopState[currentState-5])
		currentState = currentState - 5
		mq.delay(1000)	
	end
		
end

while DoLoop do
	--pause_script()
	mq.doevents()
	DoBoomerang()
	mq.delay('5s')
end