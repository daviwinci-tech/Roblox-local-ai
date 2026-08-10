--[[
    Diff.lua
    Pomocný modul pro generování porovnání kódu (Diff) pro schvalování změn uživatelem.
--]]

local Diff = {}

function Diff.generateLineDiff(oldSource, newSource)
	local oldLines = string.split(oldSource or "", "\n")
	local newLines = string.split(newSource or "", "\n")
	
	local output = {}
	local maxLines = math.max(#oldLines, #newLines)
	
	for i = 1, maxLines do
		local oldL = oldLines[i]
		local newL = newLines[i]
		
		if oldL == newL then
			table.insert(output, "  " .. (newL or ""))
		elseif oldL and not newL then
			table.insert(output, "- " .. oldL)
		elseif not oldL and newL then
			table.insert(output, "+ " .. newL)
		else
			table.insert(output, "- " .. oldL)
			table.insert(output, "+ " .. newL)
		end
	end
	
	return table.concat(output, "\n")
end

return Diff
