local SoundManager = {muted = false, volume = 1, pitch = 1}

function SoundManager.getActualX() return 0 end
function SoundManager.getActualY() return 0 end
function SoundManager.getActualPitch() return SoundManager.pitch end
function SoundManager.getActualVolume()
	if SoundManager.muted then return 0
	else return SoundManager.volume end
end

return SoundManager