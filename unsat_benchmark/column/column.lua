--------------------------------------------------------------------------------
--   Lua - Script to perform a henry problem (new style)
--------------------------------------------------------------------------------

PrintBuildConfiguration()
ug_load_script("../d3f_util.lua") 
waterlevel = 5
function HydroPressure(x,y,t) return -9810 * (y - 5) end
function HydroPressure0(x,y,t) if( y >= 8) then return 1.0 else return -9810 * (y - 5) end end
function Hydropressure1(x,y,t) return -9810 * (y-5.1) end
function cstart(x,y,t)  if t > -1*3.15576e+7 then return 1.0 else return 0.0 end end 

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
function unsaturatedHydroPressure(x,y,t)
	local vadose = 5
	if(y < vadose) then return HydroPressure(x,y,t)
	else if (y < 8) then return -1795.0
	else return -2521.0
	end
	end

end
--[[
---- This is the problem setting. It contains all relevant informations on the
---- problem that is to be solved. 
----
---- Using the {}-brackets subsections for problem parameters are grouped.
--]]
YearInSeconds 	= 3.15576e+7


function initial_Tracer(x,y,t)
local y_grenze = 8.0 --42.793
    if y >= y_grenze then
        return 1
    else
        return 0
    end
end
count  = 19
experiments = {
	-- {alphaL = 0, 		alphaT = 0,		diffusion = 0, 		kd = 0, 	endTime = 2.0e8},--SC1/11
	-- {alphaL = 0.1,		alphaT = 0.01,	diffusion = 0,		kd = 0, 	endTime = 2.5e8},--SC2/12
	 --{alphaL = 0,		alphaT = 0,		diffusion = 1e-9,	kd = 0, 	endTime = 2.5e8},--SC3/13
	 --{alphaL = 0,		alphaT = 0,		diffusion = 0,		kd = 1e-4, 	endTime = 4.5e8},--SC4/14
	-- {alphaL = 0.1,		alphaT = 0.01,	diffusion = 1e-9,	kd = 1e-5, 	endTime = 0.4e9},--SC5/15
	-- {alphaL = 0.1, 	alphaT = 0.01,	diffusion = 1e-9,	kd = 1e-4, 	endTime = 0.6e9},--SC6/16
	 --{alphaL = 0.1, 	alphaT = 0.01,	diffusion = 1e-9,	kd = 1e-3, 	endTime = 3e9},--SC7/17
	 --{alphaL = 1,		alphaT = 0.1,	diffusion = 1e-9,	kd = 1e-5, 	endTime = 0.8e9},--SC8/18
	 {alphaL = 1, 		alphaT = 0.1,	diffusion = 1e-9,	kd = 1e-4, 	endTime = 1e9},--SC9/19
	 {alphaL = 1, 		alphaT = 0.1,	diffusion = 1e-9,	kd = 1e-3, 	endTime = 3e9},--SC10/20
}


-- deactivate line-search for limex
for sc, params in pairs(experiments) do

problem = 
{ 
	-- The domain specific setup
	domain = 
	{	
		refType = "a",
		dim = 2,
		grid = "grids/column2.ugx",
		numRefs = 8,
		numPreRefs = 0,
		anisotropy = {
			type = 			"directional",
			dir = 			MakeVec(1,  0),
			maxAnisoRefs =	8,
			minEdgeRatio = 	100000000 -- minEdgeRatio>1 guarantees that all horizontal edges are refined
		},
		balancer =
		{
			partitioner = {
				name = "staticBisection",
				clusteredSiblings = false
			},

			hierarchy = {
				name 						= "standard",
				minElemsPerProcPerLevel		= 8,
				maxRedistProcs				= 8,
			},
		}
	},


	-- The density-driven-flow setup
	flow = 
	{
		compute_initial_p = false,--{true, time = 1e7 } ,
		type = "haline",
		cmp = {"c", "p"},
		
		gravity = -9.81,            -- [ m s^{-2}�] ("standard", "no" or numeric value)
		density = 1000;


		viscosity = 1e-3,				-- [ kg m^{-3} ] 
		
		
		diffusion		= 0,
		alphaL			= 0,
		alphaT			= 0,

		upwind 		= "partial",	-- no, partial, full
		boussinesq	= true,		-- true, false

		-- description of unsaturated zone. zero pressure isosurface represents phreatic surface -
		-- separates saturated - and unsaturated zone
		unsat = {
			-- descriptor for van genuchten model - Ksat has to be set to 1.0 for now...
			parameter = {
				{ uid = "@unsat",
				  type = "vanGenuchten",
				  thetaS = 1.0, thetaR =0.2,
				  alpha = 1.4e-3, n = 3.0, Ksat= 1.0
				},
				{ 	uid = "@unsat0",
					 type = "vanGenuchten",
					 thetaS = 1.0, thetaR = 0.2,
					 alpha = 0.423/(9.81*1000), n = 2.06, KSat = 1.0}



			},



		},
		-- medium descriptors. saturation and conductivity has to reference uids of the
		-- soil retention models
		{
			subset = { "Aquifer" },
			porosity = 0.2,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3e-12

		},
		{
			subset = { "Deponie" },
			porosity = 0.2,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3e-11

		},
		{
			subset = { "Vadose" },
			porosity = 0.2,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3e-12

		},


		initial =
		{
			{ cmp = "c", value = 0.0 },
			{ cmp = "p", value = "unsaturatedHydroPressure" },
			--- 	we can use a rasterfile for initial groundwater table, similar to the free surface
			--- 	implementation.
			--- 	use it like this:
			---
			--- waterTableRasterFile = <your-initial-free-surface-file>.asc
			--
			--- 	this interpolates hydrostatic pressure across domain, where p = 0 at the height of the
			---		free surface
			--     	TODO: [should currently only work for c = 0] -> consider concentration dependent density
			--		in interpolation process...
		},
		
		boundary = 
		{
			natural = "noflux",
			{ cmp = "p", type = "flux", bnd = "Inflow", 	value = 2.5e2/YearInSeconds}, -- 0,25 m/a recharge
			--{ cmp = "p", type = "level", bnd = "Inflow", 	value = 1.5}, -- 0,25 m/a recharge
			
			{ cmp = "p", type = "level", bnd = "Bottom", value = "HydroPressure" },
			--{ cmp = "c", type = "level", bnd = "Inflow", value = 1.0 },
			{ cmp = "c", type = "level", bnd = "Bottom", value = 0 },

		},

		
	},
	transport =
	{
		rockdensity = 1800,  				-- [ kg / m^3 ]

		{
			cmp = "Tracer",
			diffusion		=0,                	-- [ m^2 / s ]
			Kd = 0.000,
			porosity = 0.2,                           -- [ m^3 / kg ]
			initial = "initial_Tracer", 
			boundary =
			{
				--{ type = "level", bnd = "Inflow", value = 0.0 },
				{ cmp = "Tracer", type = "out", 	bnd = "Bottom"},
				
			},

		},
	},
	
	solver =
	{
		type = "newton",
		lineSearch = {			   		-- ["standard", "none"]
			type = "standard",
			maxSteps		= 10,		-- maximum number of line search steps
			lambdaStart		= 1,		-- start value for scaling parameter
			lambdaReduce	= 0.5,		-- reduction factor for scaling parameter
			acceptBest 		= true,		-- check for best solution if true
			checkAll		= false		-- check all maxSteps steps if true 
		},

		convCheck = {
			type		= "standard",
			iterations	= 128,			-- number of iterations
			absolute	= 1e-12,			-- absolut value of defact to be reached; usually 1e-6 - 1e-9
			reduction	= 1e-9,	--12	-- reduction factor of defect to be reached; usually 1e-6 - 1e-7
			verbose		= true			-- print convergence rates if true
		},


		
		linSolver =
		{
			type = "bicgstab",			-- linear solver type ["bicgstab", "cg", "linear"]
			precond = 
			{	
				type 		= "gmg",	-- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
				smoother 	= {type = "ilu", overlap = true},	-- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
				cycle		= "V",		-- gmg-cycle ["V", "F", "W"]
				preSmooth	= 3,		-- number presmoothing steps
				postSmooth 	= 3,		-- number postsmoothing steps
				rap			= true,	-- comutes RAP-product instead of assembling if true
				baseLevel	= 2,		-- gmg - baselevel
				ordering = {
					   name = "Lex",
					   dir = "-y"
					 }
			},
			convCheck = {
				type		= "standard",
				iterations	= 30,		-- number of iterations
				absolute	= 0.5e-12,	-- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be stricter / less than in newton section)
				reduction	= 1e-9,	--12	-- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be stricter / less than in newton section)
				verbose		= true,		-- print convergence rates if true
			}
		}
	},
	-- limex time integration is supported
	time = 
	{
		control	= "limex",   --["prescribed", "limex"]
		start 	= 0.0,		-- [s]  start time point
		stop	= 3e9, --100 Jahre --T_steps*86400,		-- [s]  end time point
		dt		= 1e-6,		-- [s]  initial time step
		dtmin	= 1e-6,		-- [s]  minimal time step
		dtmax	= 1.25e6,		-- [s]  maximal time step
		dtred	= 0.2,		-- [1]  reduction factor for time step
		

    limexDesc = {
     nstages = 2,
     steps = {1,2,3,4},
     tol   = 1e-4,
	 dampScheideggerOPT = 0,
	partialVeloMaskOPT = 1.0,
    },
		
	},
	-- output supports the pressure dependent soil saturation and conductivities
	output = 
	{
		freq	= 100, 			-- prints every x timesteps
		binary 	= true,			-- format for vtk file
		vtkname = "unsat",		-- name of vtk file
		--vtktimes 				= generate_time_table( 0, 3e8, 3e8/300.0),
			
		

		{file = "vtk", type = "vtk", data = {
			-- {"effS", "eff Saturation"},
			{"c", "Salzmassenbruch"}, {"p", "Druck"},{"Tracer", "Tracer"},{"q", "q"}, {"scalarK", "Conductivity"},   {"S", "Saturation"},{"phi", "phi"}   }},
		{file = "Tracer", type = "value", data="Tracer", 	point = {0, 0} },
		{file = "q", type = "value", data="q", 	point = {0, 0} },

	}
}


	if (problem.time.control == "limex") then
		print ("WARNING: Deactivating line-search for LIMEX scheme!")
		problem.solver.lineSearch = "none"
	end

	-- change name for saturated experiments i.e. SC 1 - 10
	filename = string.format("results/testSC%i", count)
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


