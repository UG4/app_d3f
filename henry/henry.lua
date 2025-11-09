--------------------------------------------------------------------------------
--   Lua - Script to perform a henry problem (new style)
--------------------------------------------------------------------------------

PrintBuildConfiguration()
ug_load_script("../d3f_util.lua") 

function HydroPressure(x,y,t) return -10055.25 * y end
function Spec1Start(x, y, t)
	if y >= -0.5 then return 0
	else return 1 
	end
end

function Source(_,_,t) 
	return -0.001, 0
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
		grid = "grids/henry_fract.ugx",
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
			max = 1025				-- [ kg m^{-3} ]
		},	
		
		viscosity = 
		{	"linear",				-- viscosity function ["const", "linear", "real"] 
			min = 1e-3,				-- [ kg m^{-3} ] 
			max = 1.5e-3,			-- [ kg m^{-3} ]
			brine_max = 0.0357		
		},
		
		diffusion		= 18.8571e-6,
		alphaL			= 0,
		alphaT			= 0,

		upwind 		= "partial",	-- no, partial, full 
		boussinesq	= false,		-- true, false

		porosity 		=  0.35,			-- [ 1 ]
		permeability 	=  1.019368e-9,
--[[		{
			subset 			= {"Fracture"},
			porosity 		=  0.7,		-- [ 1 ]
			permeability 	=  1.019368e-6,			
		},
		datatable = 
		{
			{	"subset", 		"porosity", 	"permeability"	},
			{	"Fracture", 	0.7,			1.019368e-6		}
		
		},
--]]	
		
		initial = 
		{
			{ cmp = "c", value = 0.0 },
			{ cmp = "p", value = "HydroPressure" },		
		},
		
		boundary = 
		{
			natural = "noflux",
			
			{ cmp = "c", type = "level", bnd = "Inflow", value = 0.0 },
			{ cmp = "c", type = "level", bnd = "Sea", value = 1.0 },
			{ cmp = "p", type = "level", bnd = "Sea", value = "HydroPressure" },	
			
			{ cmp = "p", type = "flux", bnd = "Inflow", inner = "Medium", value = 3.3e-2 }
		},
		
		source = 
		{
			--{ point = {0.1, -0.2}, params = { 0.0001, 1} },
			--{ point = {0.1, -0.5}, params = {-0.0001, 0} },
			--{ line = { {0.40012, -0.50012}, {0.80012, -0.50012} }, params = {0.001, 1}, }
			--{ line = { {0.40012, -0.20012}, {0.80012, -0.20012} }, func = Source }
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

--[[
		convCheck = {
			type		= "composite",
			iterations	= 100,			-- number of iterations
			absolute	= 5e-8,			-- absolut value of defact to be reached; usually 1e-6 - 1e-9
			reduction	= 1e-20,		-- reduction factor of defect to be reached; usually 1e-6 - 1e-7
			verbose		= true,			-- print convergence rates if true
			
			sub = 
			{
				{cmp = "c", absolute = 1e-6, relative = 1e-30},
				{cmp = "p", absolute = 1e-5, relative = 1e-40},
			}
		},
--]]
		
		linSolver =
		{
			type = "bicgstab",			-- linear solver type ["bicgstab", "cg", "linear"]
			precond = 
			{	
				type 		= "gmg",	  -- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
				smoother 	= "ilu",	-- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
				cycle		= "V",		  -- gmg-cycle ["V", "F", "W"]
				preSmooth	= 3,		  -- number presmoothing steps
				postSmooth 	= 3,		-- number postsmoothing steps
				rap			= false,	  -- computes RAP-product instead of assembling if true 
				baseLevel	= 0,		  -- gmg - baselevel
				
			},
			convCheck = {
				type		= "standard",
				iterations	= 30,		-- number of iterations
				absolute	= 0.5e-10,	-- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be stricter / less than in newton section)
				reduction	= 1e-3,		-- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be stricter / less than in newton section)
				verbose		= true,		-- print convergence rates if true
			}
		}
	},
	
	time = 
	{
		control	= "prescribed", --["prescribed", "limex"]
		start 	= 0.0,		-- [s]  start time point
		stop	= 200,		-- [s]  end time point
		dt		= 10,		-- [s]  initial time step
		dtmin	= 0.01,		-- [s]  minimal time step
		dtmax	= 10,		-- [s]  maximal time step
		dtred	= 0.1,		-- [1]  reduction factor for time step
		

    -- limex specific (used, iff 'control  == "limex"')
    -- TODO: deactivate line-search!
    limexDesc = {
     nstages = 3,
     steps = {1,2,3,4},
     tol   = 1e-2,
    },
   
		
	},
	
	output = 
	{
		freq	= 1, 			-- prints every x timesteps
		binary 	= true,			-- format for vtk file
		vtkname = "Henry",		-- name of vtk file
		
		{file = "VtkFile1", type = "vtk", data = "c"},
		{file = "VtkFile2", type = "vtk", data = {"c", "p"}},
		{file = "VtkFile3", type = "vtk", data = {{"c", "Salzmassenbruch"}, {"p", "Druck"}, {"(c*c-0.5*p)^2", "KomboData"} }},

		{file = "Integral1", type = "integral", data = "c", 				sep= ";"},
		{file = "Integral2", type = "integral", data = "(c*c-1e-6*p)^2", 	sep = "; ", subsets="Inflow"},

		{file = "Flux1", type = "flux", data = "gradc", 				boundary="Inflow", inner="Medium"},
		{file = "Flux2", type = "flux", data  = "q" , 					boundary="Inflow", inner="Medium"},
		{file = "Flux3", type = "flux", data  = "-1*K/mu*(gradp-rho*q)",boundary="Inflow", inner="Medium"},
		
		{file = "PositionFile1", type = "value", data  = "c", point = {0.5, -0.5} },
		{file = "PositionFile2", type = "value", data  = "p", point = {{0.5, -0.5}, {1, -0.5}, {0.75, -0.5}} },	
			
	}
} 

-- deactivate line-search for limex
if (problem.time.control == "limex") then
    print ("WARNING: Deactivating line-search for LIMEX scheme!")
    problem.solver.lineSearch = "none"
end
-- invoke the solution process
util.d3f.solve(problem);

