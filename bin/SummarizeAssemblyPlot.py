#!/usr/bin/env python3

import glob
import pandas as pd
import matplotlib.pyplot as plt

# Find all depth files in the current directory
depth_files = sorted(glob.glob('*.depth.csv'))

for depth_file in depth_files:
    filename = depth_file.split('.')[0]  # Base filename (before .depth.csv)

    # Read depth file (tab-separated, columns: '', position, coverage)
    df = pd.read_csv(depth_file, sep='\t', names=['', 'position', 'coverage'])

    # Plot coverage vs. position
    plt.plot(df['position'], df['coverage'])
    plt.xlabel('Position')
    plt.ylabel('Coverage')
    plt.title(filename)

    # Save plot as PNG
    plt.savefig(f'{filename}.png', dpi=200)
    plt.close()

