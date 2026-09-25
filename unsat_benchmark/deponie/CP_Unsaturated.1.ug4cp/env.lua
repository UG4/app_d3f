function LoadTheCheckpoint()
cpenv = cpenv or {}
	cpenv["ugargv"] = 	cpenv["ugargv"] or {}
		cpenv["ugargv"][1] = "../../../bin/ugshell"
		cpenv["ugargv"][2] = "-ex"
		cpenv["ugargv"][3] = "deponie/deponie.lua"
		cpenv["ugargv"][4] = "-fromCP"
		cpenv["ugargv"][5] = 0
	cpenv["myData"] = 	cpenv["myData"] or {}
		cpenv["myData"]["currdt"] = 1000
		cpenv["myData"]["time"] = 1e-6
	cpenv["id"] = 6800
	cpenv["commandline"] = "../../../bin/ugshell -ex deponie/deponie.lua -fromCP 0 "
	cpenv["ugargc"] = 5
	cpenv["stdData"] = 	cpenv["stdData"] or {}
		cpenv["stdData"]["numCores"] = 6
return cpenv
end
