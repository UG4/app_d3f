--------------------------------------------------------------------------------
--   Lua - Script to perform a henry problem (new style)
--------------------------------------------------------------------------------

PrintBuildConfiguration()
ug_load_script("../d3f_util.lua") 

local source = debug.getinfo(1, "S").source
local script_path = source:sub(2) -- remove '@'
local script_dir = script_path:match("(.*/)") or "./"

print("Executing code from ".. script_dir)

-- ug_load_script("ug_util.lua")

-- waterlevel = 5

--- function HydroPressure0(x,y,t) if( y >= 8) then return 1.0 else return -9810 * (y - 5) end end
-- function Hydropressure1(x,y,t) return -9810 * (y-5.1) end
-- function cstart(x,y,t)  if t > -1*3.15576e+7 then return 1.0 else return 0.0 end end 


-- Obsolete (as of now)
function generate_time_table(start_time, end_time, stepsize)
    local result = {}

    local t = start_time
    local tend = (end_time - start_time) / stepsize
    while t <= tend + 1e-10 do  -- small epsilon to include end_time due to float errors
        table.insert(result, t * stepsize)
        t = t + 1
    end
    return result
end


YearInSeconds 	= 3.15576e+7


function initial_Tracer(x,y,t)
local y_grenze = 8.0 --42.793
    if y >= y_grenze then
        return 1
    else
        return 0
    end
end


count  = 1. -- 1 for saturated, 11 for unsaturated

experiments = {
	{alphaL = 0, 		alphaT = 0,		diffusion = 0, 		kd = 0, 	endTime = 2.0e8},--SC1/11
	{alphaL = 0.1,		alphaT = 0.01,	diffusion = 0,		kd = 0, 	endTime = 2.5e8},--SC2/12
	{alphaL = 0,		alphaT = 0,		diffusion = 1e-9,	kd = 0, 	endTime = 2.5e8},--SC3/13
	{alphaL = 0,		alphaT = 0,		diffusion = 0,		kd = 1e-4, 	endTime = 4.5e8},--SC4/14
	{alphaL = 0.1,		alphaT = 0.01,	diffusion = 1e-9,	kd = 1e-5, 	endTime = 0.4e9},--SC5/15
	{alphaL = 0.1, 		alphaT = 0.01,	diffusion = 1e-9,	kd = 1e-4, 	endTime = 0.6e9},--SC6/16
	{alphaL = 0.1, 	alphaT = 0.01,	diffusion = 1e-9,	kd = 1e-3, 	endTime = 3e9},--SC7/17
	{alphaL = 1,		alphaT = 0.1,	diffusion = 1e-9,	kd = 1e-5, 	endTime = 8e+8},--SC8/18
	{alphaL = 1, 		alphaT = 0.1,	diffusion = 1e-9,	kd = 1e-4, 	endTime = 1e9},--SC9/19
	{alphaL = 1, 		alphaT = 0.1,	diffusion = 1e-9,	kd = 1e-3, 	endTime = 3e9},--SC10/20
}



-- deactivate line-search for limex
for sc, params in pairs(experiments) do

-- problem = require("config.lua")
problem=nil
if (count <=10) then 
	-- Fully saturated domain.
	problem=assert(loadfile(script_dir .."config-saturated.lua"))()
	-- problem=require("config-saturated")
else
	-- Partially saturated domain.
	problem=assert(loadfile(script_dir .."config-unsaturated.lua"))()
end

	if (problem.time.control == "limex") then
		print ("WARNING: Deactivating line-search for LIMEX scheme!")
		problem.solver.lineSearch = "none"
	end

	-- change name for saturated experiments i.e. SC 1 - 10
	filename = string.format("results/testSC%i", count)
	print(problem.output)
	for i, j in pairs(problem.output)do
		if type(j) == "table" then
			if j.file ~= nil then
			j.file = filename .. j.file end
		end
	end

	-- set parameters of SC
	print(filename)
	problem.flow.alphaL = params.alphaL
	problem.flow.alphaT = params.alphaT
	problem.flow.diffusion = params.diffusion
	for i, j in pairs(problem.transport)do
		if type(j) == "table" then
			j.Kd = params.kd
			j.diffusion = params.diffusion
		end
	end
	problem.time.stop = params.endTime
	if params.endTime > 1e9 then problem.time.dtmax = 1e6 end

	-- set saturated waterlevel

	-- solve saturated case
	print(problem)

	util.d3f.solve(problem);


	count = count + 1
end


-- invoke the solution process


