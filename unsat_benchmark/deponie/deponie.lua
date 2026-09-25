PrintBuildConfiguration()
ug_load_script("ug_util.lua") -- this also loads d3f_util.lua, which is located in plugins/d3f/lua/d3f_util.lua


myParams  ={}
myParams.fixedTracer = true
myParams.fromCP = util.GetParamNumber ("-fromCP", 0, "id of the checkpoint")
if (myParams.fromCP > 0) then
	print ("Restarting from checkpoint "..myParams.fromCP)
	myParams.fixedTracer = false
end


myParams.path = util.GetParam ("--path", ".", "path for output files")
myParams.cp_steps = 100 -- do check points every 100 steps.
myParams.cp_name= myParams.path .. "/CP_Unsaturated"
myParams.testcase = util.GetParamNumber ("--case", 1, "testcase number")
myParams.freq = util.GetParamNumber ("--freq", 10, "output frequency")


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

-----------------------------------------
-- Parameters --
-----------------------------------------
YearInSeconds 	= 3.15576e+7 -- seconds
--local grid_name = "20250130_2d_Deponie_V1_4.ugx"
--local grid_name = "20241218_2d_Deponie_V1_3_2.ugx"

local myTracerConc = 1.0 -- 1.0 for regular runs, 0.0 for computing the initial pressure field (to avoid tracer transport during the initial pressure computation)

local grid_name = "rectangles11.ugx"
local test_case = myParams.testcase

diffu			= 1e-9
d_long			= 0.1
d_trans			= d_long*0.1
Kd_Tracer		= 0
poro			= 0.2
-- 

cases = {
	[1] = { diffu = 1e-9, d_long = 0.1, d_trans = 0.01, Kd_Tracer = 0, poro = 0.2, upwind = "partial" },
	[2] = { diffu = 1e-9, d_long = 1.0, d_trans = 0.1, Kd_Tracer = 1e-5, poro = 0.2, upwind = "partial"  },
	[3] = { diffu = 1e-9, d_long = 1.0, d_trans = 0.1, Kd_Tracer = 1e-4, poro = 0.2, upwind = "partial"  },

	[4] = { diffu = 1e-9, d_long = 0.1, d_trans = 0.01, Kd_Tracer = 0, poro = 0.2, upwind = "full" },
	[5] = { diffu = 1e-9, d_long = 1.0, d_trans = 0.1, Kd_Tracer = 1e-5, poro = 0.2, upwind = "full"  },
	[6] = { diffu = 1e-9, d_long = 1.0, d_trans = 0.1, Kd_Tracer = 1e-4, poro = 0.2, upwind = "full"  },

	--[2] = { diffu = 1e-9, d_long = 0.1, d_trans = 0.01, Kd_Tracer = 1e-5, poro = 0.2 },
	--[3] = { diffu = 1e-9, d_long = 0.1, d_trans = 0.01, Kd_Tracer = 1e-4, poro = 0.2 },
	--[4] = { diffu = 1e-9, d_long = 1.0, d_trans = 0.1, Kd_Tracer = 0, poro = 0.2 },
	--[5] = { diffu = 1e-9, d_long = 10.0, d_trans = 1.0, Kd_Tracer = 0, poro = 0.2 },
	
}	

poro = cases[test_case].poro
diffu = cases[test_case].diffu
d_long = cases[test_case].d_long
d_trans = cases[test_case].d_trans
Kd_Tracer = cases[test_case].Kd_Tracer
upwindmethod	= cases[test_case].upwind

density 		= 1000
viscosity		= 1e-3
cp_steps		=  10 --3650000000 --600

--T_steps			= 120000
T_stop			= 6.1536e9 --100 Jahre --T_steps*86400
deltaT			= 1 --T_stop/T_steps
deltaT_min		= 1e-6
deltaT_max		= YearInSeconds/12 --(YearInSeconds/12)
dt_start		= 86400 --0,1 Tage --864000
freqoutput		= 10
--flow_vel		= 3e-8 	--m/s, wird für RB umgerechnet in kg/s
--rock_dens		= 2500

refs 			= 1		--refinement steps
prefs 			= 0 	--pre-refinement steps
lnslvty			= "gmg"
lnslvsmth		= "ilu"
preSmth			= 2
postSmth		= 2
newton_conv_abs = 1e-9
newton_conv_red = 1e-7
linSol_conv_abs	= 1e-10
linSol_conv_rel	= 1e-8
print("starting testcase "..test_case.." with parameters:")
print("diffu   - "..diffu)
print("kd      - "..Kd_Tracer)
print("d_long  - "..d_long)
print("d_trans - "..d_trans)


-----------------------------------------
-- Functions
-----------------------------------------
-- hydrodynamic pressure
function HydroPressuredepth_South(x,y,t) if(y<21) then return -(y -21)*9810 end return math.max(-(y -21)*9810, -(y -21)*9810) end
-- hydrodynamic pressure
function HydroPressuredepth_0(x,y,t) if(y<40) then return -(y -40)*9810 end return math.max(-(y -40)*9810, -(y -40)*9810) end

y0_right = 14
y0_left = 21.25 + 14
barrier_left = y0_left + 6
barrier_right = y0_right + 6
function unsaturatedHydroPressure(x,y,t)
	local x_left = 0
	local x_right = 850--53.125--850
	local vadose = y0_left + x * (y0_right - y0_left)/(x_right - x_left)
	if(y < vadose) then return -9810 * (y - vadose)
	else return math.max(-(y -vadose)*9810, -(y -vadose)*9810)
	
	end

end

local vadose_above_barrier = 42

function unsaturatedHydroPressure0(x,y,t)
	local x_left = 0
	local x_right = 850--53.125--850
	local vadose = y0_left + x * (y0_right - y0_left)/(x_right - x_left)
	local above_barrier = barrier_left + x * (barrier_right - barrier_left)/(x_right - x_left)
	if(y < vadose) then return -9810 * (y - vadose)  end
	if (y > above_barrier and y < vadose_above_barrier) then return  -(y -vadose_above_barrier)*9810 end ---981.375 end 
	--if (y > above_barrier) then return  -1000 end ---981.375 end 
	--if(y < above_barrier and y > vadose) then return -9810 * (y - vadose)  end
	return -1795
	--return math.max(-(y -vadose)*9810, -1795.0)-- -981.375
end


local use_unsaturated_model = true
if (use_unsaturated_model) then
	myInitialP = unsaturatedHydroPressure
else 
	myInitialP = unsaturatedHydroPressure -- check if this is correct, maybe it should be unsaturatedHydroPressure
end

function HydroPressuredepth_Left(x,y,t) if y < y0_left then return true, -9810 * (y - y0_left) 
else return false, -1 end end
function HydroPressuredepth_Right(x,y,t) if y < y0_right then return true, -9810 * (y - y0_right) 
else return false, -1 end end

--function TracerSource(_,_,t)
--	if t<=86400 then s0=3.39e-06 else s0=0 end
--	return s0
--end

--function initial_Tracer(x,y,t)
--	if y>=40 then return 1 end
--	if y<40 then return 0 end
--end

function initial_Tracer(x,y,t)
	local y_grenze = -0.025 * (x-50) + 41.5 --42.793
    if y >= y_grenze then return myTracerConc
    else return 0.0
    end
end

-----------------------------------------
-- d3f Problem
-----------------------------------------
problem = 
{ 
	-- The domain specific setup
	domain = 
	{--refType = "a",
		dim = 2,
		grid = grid_name, -- ("Ordner/File.ugx")
		numRefs = 2, -- 2
		numPreRefs = prefs,
		--anisotropy = {
		--	type = 			"directional",
		--	dir = 			MakeVec(0,  1),
		--	maxAnisoRefs =	1,
		--	minEdgeRatio = 	0.6 -- minEdgeRatio>1 guarantees that all horizontal edges are refined
		--},
		
	},
	

	-- The density-driven-flow setup
	flow = 
	{
		compute_initial_p = nil,--‚{true, time = 1e8 },--true,
		type = "haline",
		cmp = {"c", "p"},
		adaptive = false,
		gravity 		= 	-9.81,            -- [ m s^{-2}Ê] ("standard", "no" or numeric value)	
		density 		= 	1000,					
		viscosity 		= 	1.00e-3,
		porosity 		=  	poro, --0.2,
		diffusion		= 	diffu,
		permeability 	=  	1.019e-12,
		alphaL			= 	d_long,
		alphaT			= 	d_trans,
		upwind 			= 	"partial",	-- no, partial, full 
		boussinesq		= 	true,		-- true (no/less salt), false (with salt)/Einheiten Ausgabe Problem
		
		unsat = {
			-- descriptor for van genuchten model - Ksat has to be set to 1.0 for now...
			parameter = {
				{ uid = "@unsat",
				  type = "vanGenuchten",
				  thetaS = 1.0, thetaR =0.2,
				  alpha = 1.4e-4, 
				  n = 3.0, 
				  m = 1.0 - 1.0 / 3.0, 
				  Ksat= 1.0
				},
			},

		},

		{
			subset = { "Deponie" },
			porosity = poro,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3E-12

		},
		{
			subset = { "GeolBarriere" },
			porosity = poro,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3E-16 --e-16

		},
		{
			subset = { "Entw" },
			porosity = poro,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3E-11

		},
		{
			subset = { "GWL" },
			porosity = poro,
			saturation = { type = "RichardsSaturation", value = "@unsat" },
			conductivity = { type = "RichardsConductivity", value = "@unsat" },
			permeability = 1.3E-12

		},

		
		
		initial = 
		{
			{ cmp = "p", value = "myInitialP" },				
			{ cmp = "c", value = 0 },
		},

		boundary = 
		{
			natural = "noflux",
			{ cmp = "p", type = "flux", bnd = "Recharge", 	value = 2.5e-1*1000/YearInSeconds}, -- 0,25 m/a recharge
			{ cmp = "p", type = "flux", bnd = "Recharge2", 	value = 2.5e-1*1000/YearInSeconds}, -- 0,25 m/a recharge
			{ cmp = "p", type = "level", bnd = "Inflow", 	value = "HydroPressuredepth_Left"},
			{ cmp = "p", type = "level", bnd = "Outflow", 	value = "HydroPressuredepth_Right"},
		
		},
	},

transport =
	{
        {
        cmp = "Tracer",
        rockdensity 	= 1800, --kg/m3
		diffusion 		= diffu,
        Kd 				= Kd_Tracer, --0.0,
		porosity		= poro,
		
        
		initial = "initial_Tracer", 
		
		boundary = nil,  -- will be set below if fixedTracer is true or false.
			
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
			reduction	= 1e-12,	--12	-- reduction factor of defect to be reached; usually 1e-6 - 1e-7
			verbose		= true			-- print convergence rates if true
		},


		
		linSolver =
		{
			type = "bicgstab",			-- linear solver type ["bicgstab", "cg", "linear"]
			precond =
			{	
				type 		= "gmg",	-- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
				smoother 	=  "ilu",--{name = "ilu", ordering = { name = "Lex", dir = "+x-y" }
				--},	-- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
				cycle		= "V",		-- gmg-cycle ["V", "F", "W"]
				preSmooth	= 3,		-- number presmoothing steps
				postSmooth 	= 3,		-- number postsmoothing steps
				rap			= true,	-- comutes RAP-product instead of assembling if true
				baseLevel	= 0,		-- gmg - baselevel
				
			},
			convCheck = {
				type		= "standard",
				iterations	= 50,		-- number of iterations
				absolute	= 1e-12,	-- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be stricter / less than in newton section)
				reduction	= 1e-8,	--12	-- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be stricter / less than in newton section)
				verbose		= true,		-- print convergence rates if true
			}
		}
	},
	time = 
	{
		control				= "limex",
		start 				= 0.0,					-- [s] start time point
		stop				= T_stop,				-- [s] end time point  -- 10,000 years
		dt					= 1e5,				-- [s] initial time step
		dtmin				= 1e-5,			-- [s] minimal time step
		dtmax				= deltaT_max,			-- [s] maximal time step  -- 100.0 years
		dtred				= 0.5,					-- [1] reduction factor for time step
		
		 -- startstep 			= {dt = 1e+6},
		checkpoint_steps 	= myParams.cp_steps,
		checkpoint_name 	= myParams.cp_name,
		limexDesc = {
     		nstages = 2,
     		steps = {1,2,3,4},
     		tol   = 1e-2,
     		debugOPT = false,
     --spacesOPT = "Scaled_GridFunction"
	 		dampScheideggerOPT = 0.0,
	 		partialVeloMaskOPT = 1,
			conservative = false
    },
	},
	

	flux =
    {
		--{name = "Recharge",			bnd = "Recharge", 		file="Recharge.dat"},
		--{name = "Inflow",			bnd = "Inflow", 		file="Inflow.dat"},
		--{name = "Outflow",			bnd = "Outflow", 		file="Outflow.dat"},		
		--{name = "Recharge_Tracer",	bnd = "Recharge", 		file="Recharge_Tracer.dat", cmp = "Tracer"},
		--{name = "Inflow_Tracer",	bnd = "Inflow", 		file="Inflow_Tracer.dat", cmp = "Tracer"},
		--{name = "Outflow_Tracer",	bnd = "Outflow", 		file="Outflow_Tracer.dat", cmp = "Tracer"},
    },
	
	output = 
	{
		--vtkname 				= file_name,	-- name of vtk file
        write_pvd 				= true,
        write_processwise_pvd 	= true,
		binary 					= true,
		freq					= 1,
		--vtktimes 				=  generate_time_table( 0, 1e9, 1e9/200.0),
			
		{
			file = myParams.path .. "/test", 
			type = "vtk", 
			data = {
				{"gradp", "gradp"},
				-- {"effS", "eff Saturation"},
				{"c", "Salzmassenbruch"},
				{"p", "Druck"},
				{"Tracer", "Tracer"},
		 		{"q", "q"}, 
		 		{"scalarK", "Conductivity"},
		  		{"K", "K"},
	    		{"S", "Saturation"} 
	    	}
		},
		--{file = "Output_Recharge_BC_flux.dat",		type = "flux", 		data = "q", boundary="Recharge", 	inner= "Deponie, GWL"},
		--{file = "Output_Inflow_BC_flux.dat",		type = "flux", 		data = "q", boundary="Inflow", 	inner= "GWL"},
		--{file = "Output_Outflow_BC_flux.dat", 		type = "flux", 		data = "q", boundary="Outflow", 	inner= "GWL"},
		--{file = "Tracer_Integral_all.dat", 			type = "integral", 	data = "Tracer"},
		--{file = "Tracer_Integral_Deponie.dat", 		type = "integral", 	data = "Tracer", subsets="Deponie"},
		--{file = "Tracer_Integral_Entw.dat",			type = "integral", 	data = "Tracer", subsets="Entw"},
		--{file = "Tracer_Integral_GeolBarriere.dat",	type = "integral", 	data = "Tracer", subsets="GeolBarriere"},
		--{file = "Tracer_Integral_GWL.dat", 			type = "integral", 	data = "Tracer", subsets="GWL"},
		{file = myParams.path .. "/Tracer_P1.dat", 		type = "value", data="Tracer", 	point = {200, 37.25} },
		{file = myParams.path .. "/Tracer_P2.dat", 		type = "value", data="Tracer", 	point = {200, 36.25} },
		{file = myParams.path .. "/Tracer_P3.dat", 		type = "value", data="Tracer", 	point = {440, 21.6} },
		{file = myParams.path .. "/Tracer_P4.dat", 		type = "value", data="Tracer", 	point = {707, 14} },
		--{file = "Tracer_X190Y36.dat", 		type = "value", data="Tracer", 	point = {190, 36.25} },
		--{file = "Tracer_X200Y36.dat", 		type = "value", data="Tracer", 	point = {200, 36.25} },
		--{file = "Tracer_X200Y37.dat", 		type = "value", data="Tracer", 	point = {200, 37.25} },
		--{file = "Tracer_X350Y31.dat", 		type = "value", data="Tracer", 	point = {350, 31.5} },
		--{file = "Tracer_X840Y14.dat", 		type = "value", data="Tracer", 	point = {840, 14} },
		--{file = "Tracer_X850Y14.dat", 		type = "value", data="Tracer", 	point = {850, 15} },
	}
}


if myParams.fixedTracer then
	-- Fix tracer by Dirchlet b.c (this allows to restart from a check-point later on.)
	
	 problem.transport[1].boundary = {
		-- Fix in all subsets.
		-- Upper parts of the domain are fixed to myTracerConc.
		{ cmp = "Tracer", type = "level", 	bnd = "Deponie", value = myTracerConc},
		{ cmp = "Tracer", type = "level", 	bnd = "Entw", value = myTracerConc},
		{ cmp = "Tracer", type = "level", 	bnd = "Recharge2", value = myTracerConc},	-- top of Deponie.
		-- Lower parts of the domain are fixed to 0.0.
		{ cmp = "Tracer", type = "level", 	bnd = "GWL", value = 0.0},
		{ cmp = "Tracer", type = "level", 	bnd = "GeolBarriere", value = 0.0},	
		{ cmp = "Tracer", type = "level", 	bnd = "Recharge", value = 0.0},	
		{ cmp = "Tracer", type = "level", 	bnd = "Inflow", value = 0.0},	
		{ cmp = "Tracer", type = "level", 	bnd = "Outflow", value = 0.0},	
		
	}
		
	problem.time.limexDesc.tol = 1e-2 -- 1% tolerance for the time stepper


else
	-- For the normal simulation, we use a Neumann boundary condition for the tracer at the recharge boundary and an outflow boundary condition at the outflow boundary.
	problem.transport[1].boundary = 
	{
		{ cmp = "Tracer", type = "out", 	bnd = "Outflow"},	-- outflow boundary condition for tracer	
		{ cmp = "Tracer", type = "flux", 	bnd = "Recharge", value = 0}, -- no influx of tracer at recharge boundary
		{ cmp = "Tracer", type = "flux", 	bnd = "Recharge2", value = 0}, -- no influx of tracer at recharge boundary
	}
end
print ("problem.transport[1].boundary:")
print (problem.transport[1].boundary)


-- invoke the solution process
util.d3f.solve(problem);