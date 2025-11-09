import sys
import vtk

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Wrong number of arguments. Run: diffvtu <test path> <expected path> <absolute error> <relative error>")
        sys.exit(1)

    max_distance = 0.01  # Maximum interpolation distance for sampled points as a fraction of the bounds diagonal.
    abs_error = float(sys.argv[3])
    rel_error = float(sys.argv[4])
    epsilon = sys.float_info.epsilon

    grids = []

    reader = vtk.vtkXMLUnstructuredGridReader()
    reader.SetFileName(sys.argv[1])
    reader.Update()
    grids.append(reader.GetOutput())

    reader = vtk.vtkXMLUnstructuredGridReader()
    reader.SetFileName(sys.argv[2])
    reader.Update()
    grids.append(reader.GetOutput())

    if grids[0].GetBounds() != grids[1].GetBounds():
        print(f"Different grid bounds for {sys.argv[1]} and {sys.argv[2]}: {grids[0].GetBounds()} != {grids[1].GetBounds()}")

    scalar_names = set()
    j = 0
    while True:
        name = grids[0].GetPointData().GetArrayName(j)
        if name == None:
            break

        scalar_names.add(name)
        j += 1

    other_scalar_names = set()
    j = 0
    while True:
        name = grids[1].GetPointData().GetArrayName(j)
        if name == None:
            break

        other_scalar_names.add(name)
        j += 1

    if scalar_names != other_scalar_names:
        print(f"Different scalar names for {sys.argv[1]} and {sys.argv[2]}: {scalar_names} != {other_scalar_names}")
        sys.exit(1)

    different = False
    for name in scalar_names:
        grids[0].GetPointData().SetActiveScalars(name)
        grids[1].GetPointData().SetActiveScalars(name)

        # Convert both grids into image data for comparison
        shepard = vtk.vtkShepardMethod()
        shepard.SetInputData(grids[0])
        shepard.SetSampleDimensions(10, 10, 10)  # TODO Set samples from user input?
        shepard.SetModelBounds(grids[0].GetBounds())
        shepard.SetMaximumDistance(max_distance)
        shepard.Update()
        img0 = shepard.GetOutput()
        data0 = img0.GetPointData().GetScalars(name)

        shepard = vtk.vtkShepardMethod()
        shepard.SetInputData(grids[1])
        shepard.SetSampleDimensions(10, 10, 10)
        shepard.SetModelBounds(grids[1].GetBounds())
        shepard.SetMaximumDistance(max_distance)
        shepard.Update()
        img1 = shepard.GetOutput()
        data1 = img1.GetPointData().GetScalars(name)

        for i in range(data0.GetNumberOfValues()):
            v0 = data0.GetValue(i)
            v1 = data1.GetValue(i)
            if abs(v0 - v1) > abs_error and abs(v0 - v1) / max(epsilon, abs(v1)) > rel_error:
                different = True
                p = img0.GetPoint(i)
                print(f"Difference for {sys.argv[1]} and {sys.argv[2]} in scalar \"{name}\" at {p}: {v0} != {v1}")
                sys.exit(1)
