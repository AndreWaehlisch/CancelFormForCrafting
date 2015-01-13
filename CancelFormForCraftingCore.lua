--only enable when player is druid
if ((select(2,UnitClass("player"))) ~= "DRUID") then
	return
end;

--setup locals
local userCombat = false;

--create and return new button
local function ReplaceButton(oldbuttonLink)
	local newbuttonLink = CreateFrame("Button",oldbuttonLink:GetName().."Cffc",oldbuttonLink:GetParent(),"SecureActionButtonTemplate, MagicButtonTemplate");

	--steal position and script handler from the old button
	newbuttonLink:SetAllPoints(oldbuttonLink);
	newbuttonLink:HookScript("OnClick",oldbuttonLink:GetScript("OnClick"));
	
	--always hide old button
	oldbuttonLink:HookScript("OnShow",function()
		if InCombatLockdown() or userCombat then
			return;
		end;
		
		oldbuttonLink:Hide();
		newbuttonLink:Show();
		
		if newbuttonLink:IsVisible() then
			if ( newbuttonLink:GetFrameLevel() <= TradeSkillFrame:GetFrameLevel() ) then
				newbuttonLink:SetFrameLevel(TradeSkillFrame:GetFrameLevel()+1);
			end;
		end;
	end);

	--set attributes to run a macro which does our protected stuff
	newbuttonLink:SetAttribute("type","macro");
	newbuttonLink:SetAttribute("macrotext",SLASH_CANCELFORM1);

	return newbuttonLink;
end;

--do our stuff when user opens trade skill window for first time
local ProfessionOpenedFrame = CreateFrame("Frame");
ProfessionOpenedFrame:RegisterEvent("TRADE_SKILL_SHOW");
ProfessionOpenedFrame:SetScript("OnEvent",function()
	--initialize when not in combat and trade skill window
	if ( not IsTradeSkillLinked() ) and ( not IsTradeSkillGuild() ) and ( TradeSkillCreateButton ) and ( TradeSkillCreateAllButton ) and ( not InCombatLockdown() ) then
		--save old buttons
		local OldOneButton, OldAllButton = TradeSkillCreateButton, TradeSkillCreateAllButton;

		--create new buttons
		local NewOneButton = ReplaceButton(OldOneButton);
		local NewAllButton = ReplaceButton(OldAllButton);

		--set label of AllButton (label of OneButton is set on-the-fly)
		NewAllButton:SetText(CREATE_ALL);
		
		--enable/disable and show/hide our buttons
		hooksecurefunc("TradeSkillFrame_SetSelection",function(id)
			if InCombatLockdown() or userCombat then
				return;
			end;
			
			OldOneButton:Hide();
			OldAllButton:Hide();
			
			if (select(3,GetTradeSkillInfo(id))) > 0 then
				NewOneButton:Enable();
				NewAllButton:Enable();
			else
				NewOneButton:Disable();
				NewAllButton:Disable();
			end
			
			if ( IsTradeSkillGuild() ) or ( IsTradeSkillLinked() ) then
				NewOneButton:Hide();
				NewAllButton:Hide();
			else
				local altverb = ( select(5,GetTradeSkillInfo(id)) );
				if altverb then
					NewAllButton:Hide();
				else
					NewAllButton:Show();
				end;
				
				NewOneButton:SetText(altverb or CREATE_PROFESSION);
				NewOneButton:Show();
			end;
			
			if NewOneButton:IsVisible() then
				if ( NewOneButton:GetFrameLevel() <= TradeSkillFrame:GetFrameLevel() ) then
					NewOneButton:SetFrameLevel(TradeSkillFrame:GetFrameLevel()+1);
				end;
			end;
			
			if NewAllButton:IsVisible() then
				if ( NewAllButton:GetFrameLevel() <= TradeSkillFrame:GetFrameLevel() ) then
					NewAllButton:SetFrameLevel(TradeSkillFrame:GetFrameLevel()+1);
				end;
			end;
		end);
		
		--on setup we have to run code above or click on Create(All)Button will not work until we change selection
		local tsIndex = GetTradeSkillSelectionIndex();
		if ( tsIndex == 0 ) then
			tsIndex = GetFirstTradeSkill();
		end;
		TradeSkillFrame_SetSelection(tsIndex);
		
		--when we enter combat our addon is disabled so we dont cause taint: show old buttons
		local CombatFrame = CreateFrame("Frame");
		CombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
		CombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		CombatFrame:SetScript("OnEvent",function(self,event)
			if event == "PLAYER_REGEN_DISABLED" then
				userCombat = true;
				NewOneButton:Hide();
				NewAllButton:Hide();
				OldOneButton:Show();
				if ( select(5,GetTradeSkillInfo(TradeSkillFrame.selectedSkill)) ) then
					OldAllButton:Hide();
				else
					OldAllButton:Show();
				end;
			else
				userCombat = false;
				TradeSkillFrame_SetSelection(TradeSkillFrame.selectedSkill);
			end;
		end);
		
		ProfessionOpenedFrame:UnregisterAllEvents();
	elseif InCombatLockdown() then
		if ( GetLocale() == "deDE" ) then
			print("CancelFormForCrafting: Konnte das Addon nicht aktivieren, weil du im Kampf bist. Um das Addon zu aktivieren, öffne ein Beruf-Fenster, sobald du nicht mehr im Kampf bist.");
		else
			print("CancelFormForCrafting: Could not enable addon because you are infight. To enable the addon reopen a profession window when out of combat.");
		end;
	end;
end);