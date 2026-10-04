import matplotlib.pyplot as plt
import pandas as pd
import csv


def main(show, save):
    df = pd.read_csv("DATA/frequencies.txt")
    #df.info()
    print(df.head())
    print(df.info())

    x = df["headway_secs"]

    fig, ax = plt.subplots()
    ax.eventplot(x)

    if save: fig.savefig("OUTPUT/IMAGES/freq-eventplt.png")
    if show: plt.show()


if __name__ == "__main__":
    show = True
    save = True
    main(show, save)