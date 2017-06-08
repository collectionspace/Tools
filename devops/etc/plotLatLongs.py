import sys
import numpy as np
import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt

datatype = [('lat', np.float), ('long', np.float)]
filename = sys.argv[1]


def main():
    data = np.loadtxt(filename, dtype=[('lat', 'float'), ('long', 'float')])
    # data = numpy.memmap(filename, datatype, 'r')
    plt.plot(data['lat'], data['long'], 'r,')
    plt.grid(True)
    plt.title("Lat/Long offfsets")
    plt.xlabel("Lats")
    plt.ylabel("Longs")
    plt.savefig(sys.argv[2])


if __name__ == "__main__":
    main()  
