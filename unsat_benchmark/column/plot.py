import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np
import os


plt.style.use('dark_background')

fig, ax = plt.subplots()
fig1, ax1 = plt.subplots()
fig2, ax2 = plt.subplots()
plots = [ ax, ax1, ax2]
figs = [fig, fig1, fig2]
tests = [range(11,15), range(15,18), range(18,21)]
ncolors = len(plt.rcParams['axes.prop_cycle'])
print(plots)

# Create a plot
#plt.figure(figsize=(11, 15))

colors = [color['color'] for color in list(mpl.rcParams['axes.prop_cycle'])]
colors = colors[1]

current_color = 0
# Read and plot each Tracer<i>.txt file
for k in range(len(plots)):
    for i in tests[k]:
        filename = f"SC{i}Tracer"
        if os.path.exists(filename):
            time = []
            value = []
            with open(filename, 'r') as f:
                skip = 2
                for line in f:
                    if skip > 0:
                        skip = skip - 1
                        continue
                    if line.strip():  # skip empty lines
                        t, v = map(float, line.strip().split())
                        time.append(t)
                        value.append(v)
            plots[k].plot(time, value, label=f'SC {i}')#, color = colors[current_color])
        else:
            print(f"Warning: {filename} not found.")

            
    ax = plots[k]
    ax.set_xlabel("Time")
    ax.set_ylabel("Value")
    ax.set_title("Tracer Values Over Time")
    ax.legend(loc='upper right', fontsize='small', ncol=2)
    ax.grid(True)

# Customize plot


# Show the plot
plt.show()
