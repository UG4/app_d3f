--------------------------------------------------------------------------------
--   Lua - Script to perform a henry problem (new style)
--------------------------------------------------------------------------------

PrintBuildConfiguration()
ug_load_script("../d3f_util.lua") 



local args ={
   ProblemID = util.GetParam("--problem", "SALTPOOL3D"),  -- SALTPOOL2D, SALTPOOL3D, DEBUG3D
   NumRefs = util.GetParamNumber("--num-refs", 2),
   CpuType = util.GetParamNumber("--cpu", 2),
   LinearSolverType = util.GetParam("--solver", "bicgstab"),
   SmootherType = util.GetParam("--smoother", "sgs"),
   TimeSteppingType = util.GetParam("--time-stepping", "limex"), -- adaptive
}

print ("CMD LINE: args.NumRefs="..args.NumRefs)

args.limex ={  
   limexScheideggerDamping = util.GetParamNumber("--limex-scheidegger-damping", 0.0),
   limexPartialVeloMask = util.GetParamNumber("--limex-partial-velocity", 1),
   limexNumStages = util.GetParamNumber("--limex-num-stages", 2),
   limexTol = util.GetParamNumber("--limex-tol", 1e-3),
   limexMatrixCache = (not util.HasParamOption("--limex-disable-matrix-cache")),
   
   limexDebugLevel = (util.GetParamNumber("--limex-debug-level", 0))
}

local TestCase1={ -- Johannsen, Habilitationsschrift, S.99
 
  smf = 0.26,  -- salt mass fraction 0..smf..0.26
  Vs = 8.64*1e-4,  -- m
  
  L=0.2,      -- m
  chi=8*1e-3, -- m 
  
  -- Frischwasserzufuhr:
  T3=8412,      -- Dauer [s]
  Q3=1.89*1e-6, -- Zuflussrate [m**3/s]
 
  n=0.372,  -- porosity
 
  Dmol=10*1e-10,  -- m**2/s
  K=10*1e-10,  -- m**2
  alphaL= 1.2*1e-3,  -- m
  alphaT= 0.12*1e-3, -- m
 

  mu0 = 1.002*1e-3
}

local testcase = TestCase1




function HydrostaticPressure2D(x,z,t) return -9.81 * (z-0.1)*998.2 end

function ConcentrationStart2D(x, z, t)
  
  local zmid = -0.1+0.06-- testcase.Vs/(testcase.n*testcase.L*testcase.L)
  local dmix = testcase.chi
  local smf = 0.01/0.26 --testcase.omegamax
  
  if (z <= zmid - dmix*0.5)  then return 1.0*smf 
  elseif (z < zmid + dmix*0.5) then return (0.5 - (z - zmid)/dmix)*smf
  end

  return 0.0*smf
end


problem = {}


--[[
---- This is the problem setting. It contains all relevant informations on the
---- problem that is to be solved. 
----
---- Using the {}-brackets subsections for problem parameters are grouped.
--]]

problem["SALTPOOL2D"] = 
{ 
	-- Constants
	-- PureWaterDensity = 998.2/rho0,   -- [ kg m^{-3} ]
	-- PureBrineDensity = 1197.2/rho0,   -- [ kg m^{-3} ]
      
	-- MinViscosity = 1.002e-3/rho0,
	-- MaxViscosity = 1.990e-3/rho0,

	-- The domain specific setup
	domain = 
	{
		dim = 2,
		grid = "grids/saltpool2d.ugx",
		numRefs = 3,
		numPreRefs = 0,
	},

	-- The density-driven-flow setup
	flow = 
	{
		type = "haline",
		cmp = {"c", "p"},
		
		gravity = -9.81,   
		density =           
    { "linear",        -- density function ["const", "linear", "ideal"]
      min = 998.2,        -- [ kg m^{-3} ] 
      max = 1197.2        -- [ kg m^{-3} ]
    },  
    density0 = 1000.0,        -- characteristic density (for LIMEX) 
      
    viscosity = 
    { "real",         -- viscosity function ["const", "linear", "real"] 
      min = 1.002e-3,       -- [ kg m^{-3} ] 
      max = 1.990e-3,     -- [ kg m^{-3} ]
      brine_max = 0.26 --testcase.omegamax, -- was: 0.26    
    },
    viscosity0 = 1.00e-3,     -- characteristic viscosity (for LIMEX) 
    
    porosity 		 =  0.372,		-- [ 1 ]
		diffusion		 =  1.0e-9,  -- [m*m/s]
		permeability =  1.0e-9,   -- [m*m]
		alphaL			 = testcase.alphaL,
		alphaT			 = testcase.alphaT,

		upwind 		= "partial",	-- no, partial, full 
		boussinesq	= false,		-- true, false
		
	
  initial = 
  {
       { cmp = "c", value = "ConcentrationStart2D" },
       { cmp = "p", value = "HydrostaticPressure2D" },
  },


  boundary = 
  {
  -- { type = "level", cmp = "c", bnd = "TOP", value = "UpperBoundaryPressure2d" },
  -- { type = "level", cmp = "p", bnd = "INFLOW", value = 0.0 },
  
   { type = "level", cmp = "c", bnd = "INFLOW", value = 0.0 },
   { type = "level", cmp = "p", bnd = "OUTFLOW", value = 0.0 },
   -- ATTENTION: Order matters 
 --  { type = "out", cmp = "c", bnd = "TOP,OUTFLOW"},
  },

  source =
  {
    --{ type="source", value=0.0,  dim=0,  x0=MakeVec(-0.14, 0.097), subset = "INFLOW", rate=1e-6},  -- point source
    --{ type="sink", dim=0, x0=MakeVec(0.14, 0.097), subset = "OUTFLOW",  rate=1e-6},                -- point source
    { point={-0.14, 0.1}, params = {testcase.Q3, 0.0}},  -- INFLOW point source
    { point={0.14, 0.1}, params = {-testcase.Q3, 0.0}},  -- INFLOW point source
    --{ point={0.14, 0.097}, params = {1e-6, "INFLOW"}},  -- point source
    --{ dim=0, type="sink", subset = "OUTFLOW", rate="0.0"}                                        -- point sink
  },
		adaptive =true
	},

	
    
	  
	 -- solver for (consitent) initial data 
  solver0 =
  {
    newton = 
    {
      iteration   = 100,  -- maximum number of iterations
      absolut     = 5e-10,  -- absolut value of defect to be reached; usually 1e-7 - 1e-9
      reduction   = 1e-6,-- reduction factor of defect to be reached; usually 1e-6 - 1e-8
      
      linesearch    = true, -- enables line search (required for hard problems)
    },
    
    linear = 
    {
      type = "superlu",    -- linear solver type ["bicgstab", "cg", "linear"]
      iteration   = 30, -- number of iterations
      absolut     = 5e-12, -- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be larger than in newton section)
      reduction   = 1e-8, -- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be larger than in newton section)
    }
  },
    
	-- solver for transient problem
	solver =
	{
	  type = "newton",
		
		convCheck = {
      type    = "standard",
			iterations	 	= 10,	-- maximum number of iterations
			absolute			= 5e-10,	-- absolut value of defect to be reached; usually 1e-7 - 1e-9
			reduction		= 1e-6,-- reduction factor of defect to be reached; usually 1e-6 - 1e-8
			verbose = true,
			linesearch		= true, -- enables line search (required for hard problems)
		},
		
		linSolver = 
		{
			type = "superlu",		-- linear solver type ["bicgstab", "cg", "linear"]
			precond = 
			{	
				type 		= "gmg", -- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
				smoother 	= "egs", -- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
				cycle		= "V",	-- gmg-cycle ["V", "F", "W"]
				presmooth	= 2,	-- number presmoothing steps
				postsmooth 	= 2,	-- number postsmoothing steps
				rap		= false, -- comutes RAP-product instead of assembling if true 
				baselevel	= 0, 	-- gmg - baselevel
				
			},
			--[[
			iteration	 	= 30,	-- number of iterations
			absolut			= 5e-12, -- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be larger than in newton section)
			reduction		= 1e-8, -- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be larger than in newton section)
	--]]
		}
	},
	
	time = 
	{
		control	= "prescribed",
		control = "limex",
		start 	= 0.0,		-- [s] start time point
		stop	= testcase.T3,	-- [s] end time point  -- 10,000 years
		dt	= testcase.T3/1e+2,	-- [s] initial time step
		dtmin	= testcase.T3/1e+8,	-- [s] minimal time step
		dtmax	= testcase.T3/10,	-- [s] maximal time step  -- 100.0 years
		dtred	= 0.5,		-- [1] reduction factor for time step
		tol 	= 1e-1
	},
	
	output = 
	{
		vtkname = "Saltpool2D",    -- name of vtk file
		freq = 1,				-- prints every x timesteps
		{file = "Saltpool2D_BreakThrough.txt", type = "value", data = "c",  point={0.14, 0.1}},
		{file = "Saltpool2D_FluxFluid.txt", type = "flux", data = "q",  boundary="TOP", inner="BASSIN"},
	}
} 

function HydrostaticPressure3D(x, y, z, t) return -9.81 * (z-0.1)*998.2 end
function ConcentrationStart3D(x, y, z, t)
  
  local zmid = -0.1+0.06-- testcase.Vs/(testcase.n*testcase.L*testcase.L)
  local dmix = testcase.chi
  local smf = 0.01/0.26 -- salt mass fraction
  
  if (z <= zmid - dmix*0.5)  then return 1.0*smf 
  elseif (z < zmid + dmix*0.5) then return (0.5 - (z - zmid)/dmix)*smf
  end

  return 0.0*smf
end

function ConcentrationStart3DTest(x, y, z, t)
  
  local zmid = 0.0-- testcase.Vs/(testcase.n*testcase.L*testcase.L)
  local dmix = testcase.chi
  local smf = 0.1/0.26 --testcase.omegamax
 
  return smf*math.exp(-z*z/0.001)
end




problem["SALTPOOL3D"]  = 
{ 

  point_block =true,

  -- The domain specific setup
  domain = 
  {
    dim = 3,
    grid = "grids/saltpool3d.ugx",
    numRefs = args.NumRefs,
    numPreRefs = 0,
  },

  -- The density-driven-flow setup
  flow = 
  {
    type = "haline",
    cmp = {"c", "p"},
    adaptive =true,
    compute_initial_p = true,
    
    gravity = -9.81,   
    density =           
    { "linear",        -- density function ["const", "linear", "ideal"]
      min = 998.2,        -- [ kg m^{-3} ] 
      max = 1197.2        -- [ kg m^{-3} ]
    },  
    density0 = 1000.0,        -- characteristic density (for LIMEX) 
      
    viscosity = 
    { "real",         -- viscosity function ["const", "linear", "real"] 
      min = 1.002e-3,       -- [ kg m^{-3} ] 
      max = 1.990e-3,     -- [ kg m^{-3} ]
      brine_max = 0.26 -- testcase.omegamax, -- was: 0.26    
    },
    viscosity0 = 1.00e-3,     -- characteristic viscosity (for LIMEX) 
    
    porosity     =  0.372,    -- [ 1 ]
    diffusion      = 1.0e-9,
    permeability =  1.0e-9,
    alphaL       = testcase.alphaL,
    alphaT       = testcase.alphaT,

    upwind    = "partial",  -- no, partial, full 
    boussinesq  = false,    -- true, false
    
    
    
    initial = 
  {
       { cmp = "c", value = "ConcentrationStart3D" },
       { cmp = "p", value = "HydrostaticPressure3D" },
  },


  boundary = 
  {
  -- { type = "level", cmp = "c", bnd = "TOP", value = "UpperBoundaryPressure2d" },
  -- { type = "level", cmp = "p", bnd = "INFLOW", value = 0.0 },
   { type = "level", cmp = "c", bnd = "INFLOW", value = 0.0 },
   { type = "level", cmp = "p", bnd = "INFLOW", value = 0.0 },
  -- { type = "level", cmp = "p", bnd = "OUTFLOW", value = 0.0 },
  -- { type = "out", cmp = "c", bnd = "TOP,OUTFLOW"},  -- outflow has wrong gravity ??? 
  },

  source =
  {
  
   { point={-0.1, -0.1, 0.1}, params = {testcase.Q3, 0.0}},  -- INFLOW point source
   { point={0.1, 0.1, 0.1}, params = {-testcase.Q3, 0.0}},  -- OUTFLOW point sink (equivalent to outflow)
  },
  },
  
 
  
        
    
  -- solver for transient problem
  solver =
  {
    type = "newton",
    lineSearch  = {name = "standard" }, -- enables line search (required for hard problems)
    convCheck = {
      type    = "standard",
      iterations    = 10, -- maximum number of iterations
      absolute      = 5e-10,  -- absolut value of defect to be reached; usually 1e-7 - 1e-9
      reduction   = 1e-6,-- reduction factor of defect to be reached; usually 1e-6 - 1e-8
      verbose = true,
     
    },
    
    linSolver = 
    {
      type = args.LinearSolverType,   -- linear solver type ["bicgstab", "cg", "linear", "superlu"]
      precond = 
      { 
        type    = "gmg", -- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
        smoother  = "ilu", -- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
        baseSolver= "superlu",
        cycle   = "V",  -- gmg-cycle ["V", "F", "W"]
        preSmooth = 2,  -- number presmoothing steps
        postSmooth  = 2,  -- number postsmoothing steps
        rap   = false, -- comutes RAP-product instead of assembling if true 
        baselevel = 0,  -- gmg - baselevel
        
      },
      --[[
      iteration   = 30, -- number of iterations
      absolut     = 5e-12, -- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be larger than in newton section)
      reduction   = 1e-8, -- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be larger than in newton section)
  --]]
    }
   },
  
  time = 
  {
    control = args.TimeSteppingType,   -- "limex", "adaptive"
    start   = 0.0,    -- [s] start time point
    stop  = testcase.T3,  -- [s] end time point  
    dt  = testcase.T3/1e+2, -- [s] initial time step {100steps}
    dtmin = testcase.T3/1e+7, -- [s] minimal time step
    dtmax = testcase.T3/10, -- [s] maximal time step  
    dtred = 0.5,    -- [1] reduction factor for time step
    tol   =  args.limex.limexTol,
    rhoSafetyOPT = 0.8,
    
    
    limexDesc = {     -- limex specific (used, iff 'control  == "limex"')
     nstages = args.limex.limexNumStages,
     steps = {1,2,3,4,5,6},
     tol   = args.limex.limexTol,
     rhoSafetyOPT = 0.8,
    -- makeConsistent = true, -- obsolete, now performed by startstep
     
     partialVeloMaskOPT = args.limex.limexPartialVeloMask,
     dampScheideggerOPT = args.limex.limexScheideggerDamping,
     
    debugOPT = false, -- WAS: true
    
    },  -- limexDesc
  },
  
  output = 
  {
    vtkname = "saltpool3d_limex",    -- name of vtk file
    freq = 1,       -- prints every x timesteps
    
    { file = "Saltpool3D_BreakThrough.txt", type = "value", data = "c",  point={0.1, 0.1, 0.1}},
    { file = "Saltpool3D_FluxFluid.txt", type = "flux", data = "q",  boundary="TOP", inner="BASSIN"},
    
  }
} 



-- DEBUG example for bug in ideal density (+ consistent gravity)
problem["DEBUG3D"]  = 
{ 
 
  type = "haline",
  cmp = {"c", "p"},
  compute_initial_p = true,
  point_block =true,
  
  -- The domain specific setup
  domain = 
  {
    dim = 3,
    grid = "grids/saltpool3d.ugx",
    numRefs = 2,
    numPreRefs = 0,
  },

  -- The density-driven-flow setup
  flow = 
  {

    type = "haline",
    cmp = {"c", "p"},
    adaptive =true,
    
    gravity = -9.81,   
    density =           
    { "ideal",        -- density function ["const", "linear", "ideal"]
      min = 998.2,        -- [ kg m^{-3} ] 
      max = 1197.2        -- [ kg m^{-3} ]
    },  
    density0 = 1000.0,        -- characteristic density (for LIMEX) 
      
    viscosity = 
    { "real",         -- viscosity function ["const", "linear", "real"] 
      min = 1.002e-3,       -- [ kg m^{-3} ] 
      max = 1.990e-3,     -- [ kg m^{-3} ]
      brine_max = 0.26 -- testcase.omegamax, -- was: 0.26    
    },
    viscosity0 = 1.00e-3,     -- characteristic viscosity (for LIMEX) 
    
    porosity     =  0.372,    -- [ 1 ]
    diffusion      = 1.0e-9,
    permeability =  1.0e-9,
    alphaL       = testcase.alphaL,
    alphaT       = testcase.alphaT,

    upwind    = "partial",  -- no, partial, full 
    boussinesq  = false,    -- true, false
    
    
    
    initial = 
  {
       { cmp = "c", value = "ConcentrationStart3DTest" },
       { cmp = "p", value = "HydrostaticPressure3D" },
  },


  boundary = 
  {
    { type = "level", cmp = "c", bnd = "TOP, INFLOW, OUTFLOW,FIX", value = 0.0 },
   { type = "level", cmp = "p", bnd = "INFLOW, OUTFLOW,FIX", value = 0.0 },
  },

  source =
  {
  -- { point={-0.099, -0.099, 0.099}, params = {testcase.Q3, 0.0}},  -- INFLOW point source
  -- { point={0.1, 0.1, 0.1}, params = {-testcase.Q3, 0.0}},  -- OUTFLOW point sink (equivalent to outflow)
  },
  },
  
    
  -- solver for transient problem
  solver =
  {
    type = "newton",
    lineSearch  = {name = "standard" }, -- enables line search (required for hard problems)
    convCheck = {
      type    = "standard",
      iterations    = 10, -- maximum number of iterations
      absolute      = 9e-10,  -- absolut value of defect to be reached; usually 1e-7 - 1e-9
      reduction   = 1e-6,-- reduction factor of defect to be reached; usually 1e-6 - 1e-8
      verbose = true,
     
    },
    
    linSolver = 
    {
      type = "superlu",   -- linear solver type ["bicgstab", "cg", "linear", "superlu"]
      precond = 
      { 
        type    = "gmg", -- preconditioner ["gmg", "ilu", "ilut", "jac", "gs", "sgs"]
        smoother  = "ilu", -- gmg-smoother ["ilu", "ilut", "jac", "gs", "sgs"]
        baseSolver= "superlu",
        cycle   = "V",  -- gmg-cycle ["V", "F", "W"]
        preSmooth = 2,  -- number presmoothing steps
        postSmooth  = 2,  -- number postsmoothing steps
        rap   = false, -- comutes RAP-product instead of assembling if true 
        baselevel = 0,  -- gmg - baselevel
        
      },
      --[[
      iteration   = 30, -- number of iterations
      absolut     = 5e-12, -- absolut value of defact to be reached; usually 1e-8 - 1e-10 (must be larger than in newton section)
      reduction   = 1e-8, -- reduction factor of defect to be reached; usually 1e-7 - 1e-8 (must be larger than in newton section)
  --]]
    }
   },
  
  time = 
  {
    control = "limex", --control = "limex", "prescribed", "adaptive"
 
    start   = 0.0,    -- [s] start time point
    stop  = testcase.T3,  -- [s] end time point  -- 10,000 years
    dt  = testcase.T3/100, -- [s] initial time step 100 for 0.1
     dtmin = testcase.T3/1e+7, -- [s] minimal time step
    dtmax = testcase.T3/10, -- [s] maximal time step  
    dtred = 0.5,    -- [1] reduction factor for time step
    tol   = 1e-1
  },
  
  output = 
  {
    vtkname = "saltpool3d_limex",    -- name of vtk file
    freq = 1,       -- prints every x timesteps
    
    { file = "Saltpool3D_BreakThrough.txt", type = "value", data = "c",  point={0.1, 0.1, 0.1}},
    { file = "Saltpool3D_FluxFluid.txt", type = "flux", data = "q",  boundary="TOP", inner="BASSIN"},
    
  }
} 



-- invoke the solution process
util.d3f.solve(problem[args.ProblemID]);

