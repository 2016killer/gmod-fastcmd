local cl_fcmd_notify = CreateClientConVar('cl_fcmd_notify', '1', true, false)
local phrase = language.GetPhrase

function FcmdProgress(...)
	if cl_fcmd_notify:GetBool() then
		local text = ''
		for _, v in ipairs({...}) do
			text = text .. phrase(v) .. ' '
		end
		notification.AddProgress('fcmd_notify_progress', text)
		timer.Simple(0.5, function()
			notification.Kill('fcmd_notify_progress')
		end)
	end
end

function FcmdHelp(...)
	if cl_fcmd_notify:GetBool() then
		surface.PlaySound('NPC.ButtonBlip1')
		local text = ''
		for _, v in ipairs({...}) do
			text = text .. phrase(v) .. ' '
		end
		notification.AddLegacy(text, NOTIFY_HINT, 5)
	end
end

function FcmdError(...)
	surface.PlaySound('Buttons.snd10')
	if cl_fcmd_notify:GetBool() then
		local text = ''
		for _, v in ipairs({...}) do
			text = text .. phrase(v) .. ' '
		end
		notification.AddLegacy(text, NOTIFY_ERROR, 5)
	end
end

function FcmdWarn(...)
	surface.PlaySound('Buttons.snd8')
	if cl_fcmd_notify:GetBool() then
		local text = ''
		for _, v in ipairs({...}) do
			text = text .. phrase(v) .. ' '
		end
		notification.AddLegacy(text, NOTIFY_GENERIC, 5)
	end
end

