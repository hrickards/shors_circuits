#!/usr/bin/python
# Import code for parsing a matrix into a sympy object
from quantum_simulation import parse_matrix
from sympy import latex
import json, sys, pipes, urllib

# If the file's being run, rather than loaded as a library
if __name__ == "__main__":
    # Load the matrix from json passed as cli argument
    matrix = parse_matrix(json.loads(sys.argv[1])['matrix'])

    # Generate latex for the matix, using the pmatrix matrix env.
    tex = latex(matrix).replace("smallmatrix", "pmatrix").rpartition("\\right]")[0].partition("\\left[")[2]

    # Print out a JSONified version of the latex for the matrix
    # in a URL encoded version
    print pipes.quote(json.dumps({
        'matrix': urllib.quote(tex)
    }))
