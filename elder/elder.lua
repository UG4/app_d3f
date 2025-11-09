--------------------------------------------------------------------------------
--   Lua - Script to perform the elder problem (new style)
--------------------------------------------------------------------------------

PrintBuildConfiguration()
ug_load_script("../d3f_util.lua") 

function ConcentrationStart(x, y, t, si)
	if y == 150 then
		if x > 150 and x < 450 then
		return 1.0
		end
	end
	return 0.0
end

function PressureStart(x, y, t, si)
	return 9810 * (150 - y)
end

function ConcentrationDirichletBnd(x, y, t)
	if y == 150 then
		if x > 150 and x < 450 then
			return true, 1.0
		end
	end
	if y == 0.0 then
		return true, 0.0
	end

	return false, 0.0
end

function PressureDirichletBnd(x, y, t)
	if y == 150 then
		if x == 0.0 or x == 600 then
			return true, 9810 * (150 - y)
		end
	end
	
	return false, 0.0
end


--[[
---- This is the problem setting. It contains all relevant informations on the
---- problem that is to be solved. 
----
---- Using the {}-brackets subsections for problem parameters are grouped.
--]]
problem = 
{ 
	-- The domain specific setup
	domain = 
	{
		dim = 2,
		grid = "grids/elder_quads_8x2.ugx", -- "grids/elder_hex_8x8x2.ugx" for 3d
		numRefs = 2,
		numPreRefs = 0,
	},

	-- The density-driven-flow setup
	flow = 
	{
		type = "haline",
		cmp = {"c", "p"},
		
		gravity = -9.81,            -- [ m s^{-2}�] ("standard", "no" or numeric value)	
		density = 					
		{	"linear", 				-- density function ["const", "linear", "ideal"]
			min = 1000,				-- [ kg m^{-3} ] 
			max = 1200				-- [ kg m^{-3} ]
		},	
		
		viscosity = 
		{	"const",				-- viscosity function ["const", "linear", "real"] 
			min = 1e-3,				-- [ kg m^{-3} ] 
			max = 1e-3,			-- [ kg m^{-3} ]
			brine_max = 0.26		
		},
		
		diffusion		= 3.565e-6,
		alphaL			= 0,
		alphaT			= 0,

		upwind 		= "partial",	-- no, partial, full 
		boussinesq	= true,		-- true, false

		porosity 		=  0.1,			-- [ 1 ]
		permeability 	=  4.845e-13,
		
		initial = 
		{
			{ cmp = "c", value = "ConcentrationStart" },
			{ cmp = "p", value = "PressureStart" },		
		},
		
		boundary = 
		{
			natural = "noflux",
			
			{ cmp = "c", type = "level", bnd = "Boundary", value = "ConcentrationDirichletBnd" },
			{ cmp = "p", type = "level", bnd = "Boundary", value = "PressureDirichletBnd" },
		},
		
		source = 
		{
		}	
	},
	
	solver =
	{
		type = "newton",
		lineSearch = {			   		-- ["standard", "none"]
			type = "standard",
			maxSteps		= 30,		-- maximum number of line search steps
			lambdaStart		= 1,		-- start value for scaling parameter
			lambdaReduce	= 0.5,		-- reduction factor for scaling parameter
			acceptBest 		= true,		-- check for best solution if true
			checkAll		= false		-- check all maxSteps steps if true 
		},

		convCheck = {
			type		= "standard",
			iterations	= 100,			-- number of iterations
			absolute	= 5e-8,			-- absolut value of defact to be reached; usually 1e-6 - 1e-9
			reduction	= 1e-20,		-- reduction factor of defect to be reached; usually 1e-6 - 1e-7
			verbose		= true			-- print convergence rates if true
		},
		
		linSolver =
		{
			type = "bicgstab",			-- linear solver type ["bicgstab", "cg", "linear"]
			precond = 
			{	
				type 		= "gmg",	-- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
				smoother 	= "ilu",	-- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
				cycle		= "V",		-- gmg-cycle ["V", "F", "W"]
				preSmooth	= 3,		-- number presmoothing steps
				postSmooth 	= 3,		-- number postsmoothing steps
				rap			= false,	-- comutes RAP-product instead of assembling if true 
				baseLevel	= 0,		-- gmg - baselevel
				
			},
			convCheck = {
				type		= "standard",
				iterations	= 60,		-- number of iterations
				absolute	= 1e-10,	-- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be stricter / less than in newton section)
				reduction	= 1e-3,		-- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be stricter / less than in newton section)
				verbose		= true,		-- print convergence rates if true
			}
		}
	},
	
	time = 
	{
		control	= "prescribed",
		start 	= 0.0,			-- [s]  start time point
		stop	= 3.1536e8,		-- [s]  end time point
		dt		= 3.1536e6,		-- [s]  initial time step
		dtmin	= 3.1536e3,		-- [s]  minimal time step
		dtmax	= 3.1536e6,		-- [s]  maximal time step
		dtred	= 0.1,			-- [1]  reduction factor for time step
		tol 	= 1e-2,
		
	},
	
	output = 
	{
		freq	= 1, 			-- prints every x timesteps
		binary 	= true,			-- format for vtk file
		vtkname = "Elder",		-- name of vtk file
        vtktimes = {1e5},
        {file = "out.dat",              type = "value", data="p",       point = {159, 65} },
		
	}
} 

-- invoke the solution process
util.d3f.solve(problem);

-- get last output line
result = ""
file = io.open("out.dat", "r")
line = file:read("*line")
while line ~= nil do
        result = line
        line = file:read("*line")
end
file:close()

-- check if result matches known solution
epsilon = 1e-1
expected = 859010.741998625
result = tonumber(string.match(result, "\t(.*)"))
if math.abs(result - expected) > epsilon then
        error("result does not match expected value!")
end

print("test successful!")
