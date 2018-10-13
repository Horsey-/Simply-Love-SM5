local player = ...
local pn = ToEnumShortString(player)
local p = PlayerNumber:Reverse()[player]

local text_table, marquee_index

return Def.ActorFrame{
	Name="StepArtistAF_" .. pn,
	InitCommand=cmd(draworder,1),

	-- song and course changes
	OnCommand=cmd(queuecommand, "StepsHaveChanged"),
	CurrentSongChangedMessageCommand=cmd(queuecommand, "StepsHaveChanged"),
	CurrentCourseChangedMessageCommand=cmd(queuecommand, "StepsHaveChanged"),

	PlayerJoinedMessageCommand=function(self, params)
		if params.Player == player then
			self:queuecommand("Appear" .. pn)
		end
	end,
	PlayerUnjoinedMessageCommand=function(self, params)
		if params.Player == player then
			self:ease(0.5, 275):addy(scale(p,0,1,1,-1) * 30):diffusealpha(0)
		end
	end,

	-- depending on the value of pn, this will either become
	-- an AppearP1Command or an AppearP2Command when the screen initializes
	["Appear"..pn.."Command"]=function(self) self:visible(true):zoomy(0):sleep(0.2):accelerate(0.2):zoomy(1):decelerate(0.2):zoomy(0.6):accelerate(0.1):zoomy(1) end,

	InitCommand=function(self)
		self:visible( false ):halign( p )

		if player == PLAYER_1 then

			self:y(_screen.cy + 15)
			self:x( _screen.cx - (IsUsingWideScreen() and 356 or 320))

		elseif player == PLAYER_2 then

			self:y(_screen.cy + 126)
			self:x( _screen.cx - (IsUsingWideScreen() and 210 or 183))
		end

		if GAMESTATE:IsHumanPlayer(player) then
			self:queuecommand("Appear" .. pn)
		end
	end,

	-- colored background
	Def.ActorFrame{
			InitCommand=function(self)

				if player == PLAYER_1 then
					self:x((IsUsingWideScreen() and 96 or 87))
					self:rotationx(180)
					self:y(1.5)
				elseif player == PLAYER_2 then
					self:x((IsUsingWideScreen() and 76 or 86))
					self:rotationy(180)
					self:y(-1.5)
				end
		end,
			LoadActor("stepartistbubble")..{
				InitCommand=cmd(zoomto, (IsUsingWideScreen() and 195 or 175), _screen.h/15; diffuse, DifficultyIndexColor(1) ),
				StepsHaveChangedCommand=function(self)
					local StepsOrTrail = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)

					if StepsOrTrail then
						local difficulty = StepsOrTrail:GetDifficulty()
						self:diffuse( DifficultyColor(difficulty) )
					else
						self:diffuse( PlayerColor(player) )
					end
				end
			},
	},

	--STEPS label
	Def.BitmapText{
		Font="_miso",
		OnCommand=function(self)
				self:diffuse(0,0,0,1)
				self:horizalign(left)
				self:settext(Screen.String("STEPS"))
				self:maxwidth(40)
				if player == PLAYER_1 then
					self:x(3)
					self:y(-3)
				elseif player == PLAYER_2 then
					self:x(130)
					self:y(3)
				end
			end
	},

	--stepartist text
	Def.BitmapText{
		Font="_miso",
		InitCommand=function(self)
			self:diffuse(color("#1e282f"))
			self:maxwidth((IsUsingWideScreen() and 142 or 122))
				if player == PLAYER_1 then
					self:horizalign(left)
					self:x(46)
					self:y(-3)
				elseif player == PLAYER_2 then
					self:horizalign(right)
					self:x(126)
					self:y(3)
				end
		end,
		StepsHaveChangedCommand=function(self)

			local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
			local StepsOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSteps(player)

			-- always stop tweening when steps change in case a MarqueeCommand is queued
			self:stoptweening()

			-- clear the stepartist text, in case we're hovering over a group title
			self:settext("")

			if StepsOrCourse then
				text_table = GetStepsCredit(player)
				marquee_index = 0

				-- only queue a marquee if there are things in the text_table to display
				if #text_table > 0 then self:queuecommand("Marquee") end
			end
		end,
		MarqueeCommand=function(self)
			-- increment the marquee_index, and keep it in bounds
			marquee_index = (marquee_index % #text_table) + 1
			-- retrieve the text we want to display
			local text = text_table[marquee_index]

			-- set this BitmapText actor to display that text
			self:settext( text )

			-- account for the possibility that emojis shouldn't be diffused to Color.Black
			for i=1, text:utf8len() do
				if text:utf8sub(i,i):byte() >= 240 then
					self:AddAttribute(i-1, { Length=1, Diffuse={1,1,1,1} } )
				end
			end

			-- sleep 2 seconds before queueing the next Marquee command to do this again
			self:sleep(2):queuecommand("Marquee")
		end,
		OffCommand=function(self) self:stoptweening() end
	}
}
