--[[
TheNexusAvenger
Entry for a subtitle in the subtitle window.
Modified to use Subtitle Engine for display by datguytml
--]]

local PLAYBACK_LOUDNESS_THRESHOLD = 50
local PLAYBACK_LOUDNESS_SILENCE_DELAY = 1

local RunService = game:GetService("RunService")
local Types = require(script.Parent.Parent:WaitForChild("LocalAudioSubtitlesTypes"))
local SubtitleEngine = require(game:GetService("ReplicatedStorage"):WaitForChild("SubtitleEngine"))

local SubtitleEntry = {}
SubtitleEntry.__index = SubtitleEntry

--[[
Creates a subtitle entry.
--]]
function SubtitleEntry.new(Message: string, Window: Types.SubtitleWindow, ReferenceSound: Sound?, SpeakerName: string?, Duration: number?): Types.SubtitleEntry
	--Create the object.
	local self = {
		Message = Message,
		SpeakerName = SpeakerName,
		Duration = Duration or 5,
		ReferenceSound = ReferenceSound,
		Multiple = 0,
		Window = Window,
		Visible = false,
		PlaybackLoudnessEvents = {},
		LastReferenceSoundAudible = {},
		SubtitleEngineActive = false,
	}
	setmetatable(self, SubtitleEntry)

	table.insert(Window.SubtitleEntries, self :: any)

	--Update the visibility based on the audio volume.
	if ReferenceSound then
		self:AddReferenceSound(ReferenceSound)
	else
		self:AddMultiple()
	end

	--Return the object.
	return self :: any
end

--[[
Gets the index of the subtitle.
--]]
function SubtitleEntry:GetIndex(): number
	for i, Entry in self.Window.SubtitleEntries do
		if Entry ~= self then continue end
		return i
	end
	return 0
end

--[[
Gets the visible index of the subtitle.
--]]
function SubtitleEntry:GetVisibleIndex(): number
	local CurrentIndex = 1
	for _, Entry in self.Window:GetVisibleEntries() do
		if Entry == self then
			return CurrentIndex
		end
		if Entry.Visible then
			CurrentIndex += 1
		end
	end
	return 0
end

--[[
Updates the position of the entry.
Not needed when using Subtitle Engine as it handles positioning.
--]]
function SubtitleEntry:UpdatePosition(): ()
	-- the game will implode without this.
end

--[[
Updates the text shown for the multiple.
--]]
function SubtitleEntry:UpdateMultipleText(): ()
	local CurrentMultiple = self.Multiple
	local Visible = (CurrentMultiple > 0)

	if Visible ~= self.Visible then
		if Visible then
			self.Visible = true
			self:ShowSubtitleEngine()
			self.Window:UpdateSize()
		else
			self.Visible = false
			self.Window:UpdateSize()
		end
	end
end

--[[
Shows the subtitle using Subtitle Engine.
--]]
function SubtitleEntry:ShowSubtitleEngine(): ()
	if self.SubtitleEngineActive then return end
	self.SubtitleEngineActive = true

	-- Build message
	local fullMessage = self.Message
	local typeDelayPerChar = (self.Duration * 0.5) / string.len(self.Message)

	if self.SpeakerName and self.SpeakerName ~= "" then
		-- Half of the "Duration" for the subtitle is spent with the typing animation. If you want to chaneg this, change the 0.5 to a value 0-1.
		typeDelayPerChar = (self.Duration * 0.5) / string.len(fullMessage)

		-- Configure profile, display subtitle (configuring the profile each time probably isn't the best way to do it, but I don't know the extraOptions. Feel free to make a PR!)
		SubtitleEngine.editProfile("Self", {extraWaitTime = self.Duration * 0.5}) -- If you configure the type speed, you'll need to change this to be the opposite
		SubtitleEngine.localSubtitle("Self", '<typeDelay = 0><b>'..self.SpeakerName..'</b>: </typeDelay><typeDelay = '..typeDelayPerChar..'>'..self.Message..'</typeDelay>')
	else
		-- No speaker version (less logic)
		SubtitleEngine.editProfile("Self", {extraWaitTime = self.Duration})
		SubtitleEngine.localSubtitle("Self", '<typeDelay = 0.03>'..self.Message..'</typeDelay>')
	end
end

--[[
Adds a multiple to the subtitle entry.
--]]
function SubtitleEntry:AddMultiple(): ()
	self.Multiple += 1
	self:UpdateMultipleText()
end

--[[
Removes a multiple to the subtitle entry.
--]]
function SubtitleEntry:RemoveMultiple(): ()
	self.Multiple += -1
	self:UpdateMultipleText()
end

--[[
Adds a sound to reference for managing the volume.
--]]
function SubtitleEntry:AddReferenceSound(ReferenceSound: Sound): ()
	local LastLoudnessTime = 0
	local LastAudible = false

	self.PlaybackLoudnessEvents[ReferenceSound] = RunService.Stepped:Connect(function()
		local NewAudible = LastAudible
		if NewAudible then
			if ReferenceSound.PlaybackLoudness >= PLAYBACK_LOUDNESS_THRESHOLD then
				LastLoudnessTime = tick()
			elseif tick() - LastLoudnessTime > PLAYBACK_LOUDNESS_SILENCE_DELAY then
				NewAudible = false
			end
		else
			if ReferenceSound.PlaybackLoudness >= PLAYBACK_LOUDNESS_THRESHOLD then
				LastLoudnessTime = tick()
				NewAudible = true
			end
		end

		if NewAudible ~= LastAudible then
			if NewAudible then
				self:AddMultiple()
			else
				self:RemoveMultiple()
			end
			LastAudible = NewAudible
			self.LastReferenceSoundAudible[ReferenceSound] = NewAudible
		end
	end)
end

--[[
Removes a sound to reference for managing the volume.
--]]
function SubtitleEntry:RemoveReferenceSound(ReferenceSound: Sound): ()
	if self.PlaybackLoudnessEvents[ReferenceSound] then
		self.PlaybackLoudnessEvents[ReferenceSound]:Disconnect()
		self.PlaybackLoudnessEvents[ReferenceSound] = nil
	end

	if self.LastReferenceSoundAudible[ReferenceSound] then
		self:RemoveMultiple()
	end
end

--[[
Destroys the entry.
--]]
function SubtitleEntry:Destroy(): ()
	self.Clearing = true
	self.Visible = false
	self.SubtitleEngineActive = false

	task.delay(0.25, function()
		table.remove(self.Window.SubtitleEntries, self:GetIndex())
		self.Window:UpdateSize()

		for _, Event in self.PlaybackLoudnessEvents do
			Event:Disconnect()
		end
		self.PlaybackLoudnessEvents = {}
	end)
end

return SubtitleEntry
