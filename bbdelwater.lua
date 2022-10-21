local Terrain = workspace.Terrain
local processBlockSize = 640
local WATER = Enum.Material.Water
local AIR = Enum.Material.Air
local floor = math.floor

function isInRegion3(region, point)
    local relative = (point - region.CFrame.p) / region.Size
    return -0.5 <= relative.X and relative.X <= 0.5
       and -0.5 <= relative.Y and relative.Y <= 0.5
       and -0.5 <= relative.Z and relative.Z <= 0.5
end

local function round(num)
	return math.floor(num + .5)
end

local function getAlignedPosition(pos)
	local x = round(pos.X)
	x = x - x%4 + 2
	local y = round(pos.Y)
	y = y - y%4 + 2
	local z = round(pos.Z)
	z = z - z%4 + 2
	
	return Vector3.new(x,y,z)
end

local function comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function removeWater(voxelPos, worldSize)
	local functionStart = tick()
	voxelPos = getAlignedPosition(voxelPos)
	local material = nil
	local occupancy = nil
	
	local queue = {}
	local processed = {}
	table.insert(queue, voxelPos)
	
	local boundaryRegion = Region3.new(voxelPos-worldSize/2, voxelPos+worldSize/2)
	boundaryRegion:ExpandToGrid(4)
	local minPoint = boundaryRegion.CFrame.p-boundaryRegion.Size/2
	print("Starting")
	local partsProcessed = 0
	
	local regions = {}
	
	local start = getAlignedPosition(minPoint)
	local xOffset = 0
	local yOffset = 0
	local zOffset = 0
	local done = false
	repeat
		local startPos = start+Vector3.new(xOffset,yOffset,zOffset)
		local size = boundaryRegion.CFrame.p+boundaryRegion.Size/2-startPos
		local x,y,z = size.X, size.Y, size.Z
		if x > processBlockSize then
			x = processBlockSize
		end
		if y > processBlockSize then
			y = processBlockSize
		end
		if z > processBlockSize then
			z = processBlockSize
		end
		size = Vector3.new(x,y,z)
		local region = Region3.new(startPos, startPos+size)
		region = region:ExpandToGrid(4)
		table.insert(regions, region)
		zOffset = zOffset + processBlockSize
		if zOffset >= boundaryRegion.Size.Z then
			zOffset = 0
			yOffset = yOffset + processBlockSize
		end
		if yOffset >= boundaryRegion.Size.Y then
			yOffset = 0
			xOffset = xOffset + processBlockSize
		end
		if xOffset >= boundaryRegion.Size.X then
			done = true
		end
	until done
	
	print("Writing to ", #regions, " regions!")
	print("Removing water...")
	local totalRemoved = 0
	local totalProcessed = 0
	local totalVolume = worldSize.X*worldSize.Y*worldSize.Z
	local changed,materials,occupancy,size,matsX,occX,matsY,occY,p
	for index, region in pairs(regions) do
		changed = 0
		materials, occupancy = Terrain:ReadVoxels(region, 4)
		size = materials.Size
		for x = 1, size.X do
			matsX = materials[x] --Creating variables to reduce amount of searching
			occX = occupancy[x]
			for y = 1, size.Y do
				matsY = matsX[y]
				occY = occX[y]
				for z = 1, size.Z do
					totalProcessed = totalProcessed + 1
					if matsY[z] == WATER then
						matsY[z] = AIR
						occY[z] = 0
						changed = changed + 1
					end
				end
			end
		end
		
		if changed > 0 then --No need to write if there is no changes
			Terrain:WriteVoxels(region, 4, materials, occupancy)
		end
		if index%4 == 0 then
			print((floor(index/#regions*1000+0.5)/10).."% complete!")
			wait(0)
		end
		totalRemoved = totalRemoved + changed
	end
	
	print("Total time elapsed: ", (tick()-functionStart), " seconds!")
	print("Total water blocks removed: ", totalRemoved)
	print("Total cells processed: ", comma_value(totalProcessed))
	print("Region/Chunks: ", #regions)
	print("Total Volume: ", totalVolume, "cubic studs")
	print("Done processing")
end
removeWater(Vector3.new(0,0,0), Vector3.new(3000,2000,3000))
