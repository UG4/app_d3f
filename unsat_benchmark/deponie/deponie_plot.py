import argparse

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot tracer data and optionally restrict the x-axis to an interval of length T."
    )
    parser.add_argument(
        "T",
        nargs="?",
        type=float,
        help="Optional length of the x-axis interval to plot. If omitted, all x-values are shown.",
    )
    parser.add_argument(
        "--T",
        dest="T_flag",
        type=float,
        help="Optional alias for the x-axis interval length.",
    )
    parser.add_argument(
        "--png",
        action="store_true",
        help="Save the plot as a PNG file without opening a browser.",
    )
    parser.add_argument(
        "--pdf",
        action="store_true",
        help="Save the plot as a PDF file without opening a browser.",
    )
    parser.add_argument(
        "--screen",
        action="store_true",
        help="Render the plot in screen mode using Plotly with Kaleido as the default renderer.",
    )
    parser.add_argument(
        "--output",
        default="tracer_data.pdf",
        help="Output file name for the exported image (default: tracer_data.pdf).",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    interval_length = args.T_flag if args.T_flag is not None else args.T

    if args.screen:
        try:
            import kaleido  # noqa: F401
            import plotly.graph_objects as go
        except ModuleNotFoundError:
            print(
                "Screen mode requires the optional 'plotly' and 'kaleido' packages. "
                "Install them with 'pip install plotly kaleido'."
            )
            return

        fig = go.Figure()
        for i in range(1, 5):
            filename = f"Tracer_P{i}.dat"
            data = np.loadtxt(filename, usecols=(0, 1))
            x = data[:, 0]
            y = data[:, 1]

            if interval_length is not None:
                mask = (x >= 0) & (x <= interval_length)
                x = x[mask]
                y = y[mask]

            colors = {
                1: "blue",
                2: "orange",
                3: "lightgrey",
                4: "darkgrey",
            }

            fig.add_trace(
                go.Scatter(
                    x=x,
                    y=y,
                    mode="lines",
                    name=f"Tracer {i}",
                    line=dict(color=colors.get(i, "black")),
                )
            )

        fig.update_layout(
            title="Tracer Data",
            xaxis_title="Time [s]",
            yaxis_title="Concentration ",
            template="plotly_white",
            hovermode="x unified",
        )

        if interval_length is not None:
            fig.update_xaxes(range=[0, interval_length])

        fig.show()
        return

    fig, ax = plt.subplots()

    for i in range(1, 5):
        filename = f"Tracer_P{i}.dat"

        data = np.loadtxt(filename, usecols=(0, 1))
        x = data[:, 0]
        y = data[:, 1]

        if interval_length is not None:
            mask = (x >= 0) & (x <= interval_length)
            x = x[mask]
            y = y[mask]

        colors = {
            1: "blue",
            2: "orange",
            3: "lightgrey",
            4: "darkgrey",
        }

        ax.plot(x, y, label=f"Tracer {i}", color=colors.get(i, "black"))

    ax.set_title("Tracer Data")
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.grid(True, alpha=0.3)
    ax.legend()

    if interval_length is not None:
        ax.set_xlim(0, interval_length)

    export_format = None
    if args.pdf:
        export_format = "pdf"
    elif args.png:
        export_format = "png"
    else:
        export_format = "png"

    output_path = args.output
    if output_path.lower().endswith(f".{export_format}"):
        pass
    else:
        output_path = f"{output_path}.{export_format}"

    try:
        fig.savefig(output_path, format=export_format, dpi=200, bbox_inches="tight")
        print(f"Saved {export_format.upper()} to {output_path}")
    except Exception as exc:
        print(f"Failed to save {export_format.upper()}: {exc}")


if __name__ == "__main__":
    main()
