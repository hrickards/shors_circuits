#!/usr/bin/python
# Import the necessary libraries. Main one is sympy, which does all the
# heavy lifting.
from sympy import Matrix, eye, sqrt, latex, I
from sympy.physics.quantum import TensorProduct
from numpy import binary_repr
from sympy.parsing.sympy_parser import parse_expr
import pipes, json, sys, urllib, re, itertools

# Parse a string into a sympy expression, allowing i for the imaginary unit
def custom_parse_expr(expr):
    return parse_expr(expr).subs('i', I)

# Parse a matrix (given as an array of arrays of strings) into a sympy matrix
def parse_matrix(matrix):
    # Iterate over rows
    for i in range(len(matrix)):
        # Iterate over elements in row
        for j in range(len(matrix[i])):
            # Parse an expression like "1/sqrt(2)", and turn it into a sympy
            # value
            matrix[i][j] = custom_parse_expr(matrix[i][j])
    
    # Return a 'sympified' version of the matrix
    return Matrix(matrix)

# Parse a string containing kets into it's state vector
# size = number of qubits referenced in ket_string
def parse_ket_string(ket_string, size):
    # kets = "1/sqrt(2)|00> - 1/sqrt(2)|11>"
    # kets = ["1/sqrt(2)", "|00>", "- 1/sqrt(2)", "|11>"]
    # Split on a regular expression, then strip whitespace and remove blanks
    kets = re.split("(\|\d+>)", ket_string)
    kets = map(lambda ket: ket.strip(), kets)
    kets = filter(lambda ket: len(ket) > 0, kets)

    # Initialise a state array of the right length containing all 0s
    state_array = [0] * (2 ** size)

    # To store the coefficient of the ket (e.g. 1/sqrt(2)) in
    coeff = ""
    # For each ket in kets
    for ket in kets:
        # Match to see if we can find the actual ket part (e.g. |00>)
        match = re.match("\|(\d+)>", ket)

        # If that part's not present, then this is just a coefficient
        if match == None:
            coeff = ket
        # Otherwise an actual ket part is present that we need to parse
        else:
            # If coeff doesn't contain a proper coefficient, append a 1 to
            # the end so we can multiply it easil. e.g. +|00> needs to become
            # +1|00>
            if coeff == "" or coeff == "-" or coeff == "+": coeff += "1"
            
            # Parse the coefficient
            parsed_coeff = custom_parse_expr(coeff)

            # Take the numeric part inside the ket, e.g. 00 inside |00>
            # and parse it from a binary to a decimal integer, giving us
            # the relevant index inside the state vector. e.g. |11> is
            # the 3rd location because 11b = 3d
            index = int(match.groups(0)[0], 2)

            # Add on the coefficient to the relevant location inside the
            # state vector
            state_array[index] += parsed_coeff

            # Reset coefficient
            coeff = ""

    # If an incorrect state string has been passed, just use |00...000>
    # instead
    if all(map(lambda val: val == 0, state_array)):
        state_array[0] = 1

    # Return the state_array in vector form
    return Matrix(state_array)

# Turn a list
# e.g. [(0.5,0), (0.5,0), (1, 1), (1, 1), (1, 6)]
# into probabilities
# e.g. {0: 0.25, 1: 0.5, 2: 0.25}
def conditional_list_to_probabilities(lis):
    # Calculate a list of all latter-parts of the tuples
    latters = set(map(lambda element: element[1], lis))

    sum_probabilities = {}
    # For each unique latter
    for latter in latters:
        # Find a list of all elements corresponding to that latter
        formers = filter(lambda x: x[1] == latter, lis)
        # Sum the probability for that latter
        sum_probabilities[latter] = sum(map(lambda x: x[0], formers))

    # Sum sum_probabilities
    sum_sum_probabilities = sum(sum_probabilities.values())

    probabilities = {}
    # For each unique latter:
    for latter in latters:
        # Calculate probability as (self sum probabilities)/(total sum prob)
        probabilities[latter] = sum_probabilities[latter]/sum_sum_probabilities

    return probabilities

# Calls str on all keys
# Turns a value v to [str(v), float(v)]
def format_probabilities(h1):
    h2 = {}
    for key in h1.keys():
        v = h1[key].simplify()
        sys.stderr.write(str(v))
        h2[str(key)] = [str(v), float(v)]
    return h2

# Given a state tuple (state, probability, ...), nicely format it
# into a value suitable for returning to the frontend
# size = number of qubits
def format_state(state_array, size):
    # Get the values from the state tuple
    state = state_array[0]
    probability = state_array[1]

    return {
            'state_string': format_state_string(state, size),
            'state_latex': format_state_latex(state, size),
            'probability_string': str(probability),
            'probability_latex': urllib.quote(latex(probability))
            }

# Given a state, return a human-readable string version of it
# size = number of qubits
def format_state_string(state, size):
    # Parts contains elements like "(1/2)|00>"
    parts = []
    # Iterate over every possible ket (|0...0> to |1...1>)
    for i in range(len(state)):
        # Generate label e.g. "|00>" by formatting i as a binary number
        # padded to size
        label  = "|%s>" % binary_repr(i, size)
        # Generate coefficient. e.g. "1/2"
        coefficient = "(%s)" % str(state[i])

        # Don't need coefficient if it equals 1
        if state[i] == 1: parts.append(label)
        # And don't need state if coefficient equals 0
        elif state[i] != 0: parts.append(coefficient + label)

    # Join all the parts together
    state_string = " + ".join(parts)

    # Replace any ... + (- ... with just ... - ...
    return state_string.replace("+ (-", "- (")

# Given a state, return a formatted string version of it containing latex code
# size = number of qubits
def format_state_latex(state, size):
    # Parts contains elements like "(\frac{1}{2})\ket{00}"
    parts = []
    # Iterate over every possible ket (|0...0> to |1...1>)
    for i in range(len(state)):
        # Generate label e.g. "\ket{00}" by formatting i as a binary number
        # padded to size
        label  = "\\ket{%s}" % binary_repr(i, size)
        # Generate coefficient. e.g. "\frac{1}{2}"
        coefficient = "(%s)" % latex(state[i])

        # Don't need coefficient if it equals 1
        if state[i] == 1: parts.append(label)
        # And don't need state if coefficient equals 0
        elif state[i] != 0: parts.append(coefficient + label)

    # Join all the parts together
    state_string = " + ".join(parts)

    # Replace any ... + (- ... with just ... - ...
    state_string = state_string.replace("+ (-", "- (")

    # Format to be URL-ready
    return urllib.quote(state_string)

# Class representing an operator
class Operator:
    # Create a new instance by parsing the passed data
    def __init__(self, data):
        # Save a parsed version of the matrix, and the id
        self.matrix = parse_matrix(data['matrix'])
        self.id = data['id']

# Class representing a controlled gate --- a specific type of operator
class Controlled(Operator):
    # Create a new instance by parsing the passed data
    def __init__(self, data):
        # Save the values, matrices & id fields of the operator
        self.values = data['values']
        self.id = data['id']
        
        self.matrices = {}
        # For each value => matrix
        for (value, matrix) in data['matrices'].iteritems():
            # Parse both, and store in self.matrices
            value = custom_parse_expr(value)
            matrix = parse_matrix(matrix)
            self.matrices[value] = matrix


# Class representing a simulation
class QuantumSimulation:
    # register_size = length of the register
    # gates = list of gates used & their details
    # measurements = list of measurements used & their details
    # controlled_gates = list of controlled_gates used & their details
    # circuit = circuit to simulate
    # input_register = initial state of the circuit
    def __init__(self, options):
        # Save everything for later, parsing the operator lists and
        # input register
        self.register_size = options['register_size']
        self.gates = map(Operator, options['gates'])
        self.measurements = map(Operator, options['measurements'])
        self.controlled_gates = map(Controlled, options['controlled_gates'])
        self.circuit = options['circuit']
        self.input_register = parse_ket_string(
                options['input_register'],
                self.register_size
        )



    # Simulate the circuit
    def simulate(self):
        # Obtain the results of running the circuit
        results = self.run_fragment(
                # Circuit
                self.circuit,
                # Initial state triple:
                # - Register state is just self.input_register
                # - Definitely in this state, so probability is 1
                # - No measurements have been made yet, so {}
                [(self.input_register, 1, {})]
        )

        # Take the last result, which we can extract measurements from
        last_result = results[-1]
        # From the measurements dictionary of the first state in the last
        # result, take a list of all measurements
        measurements = last_result[0][2].keys()
        # Create a new dictionary to store measurement probabilities in
        self.probabilities = {}
        # For each measurement
        for measurement in measurements:
            # Take the measurement outcomes for that measurement from each
            # state, keeping with it the probability of that state
            outcomes = map(
                    lambda state: (state[1], state[2][measurement]),
                    last_result
            )
            # Calculate and store the probabilities of those outcomes from
            # the number of times they occur in the list multiplied by
            # their probability
            # format_probabilities formats both keys and values appropriately
            self.probabilities[measurement] = format_probabilities(
                    conditional_list_to_probabilities(outcomes)
            )

        # Create a new dictionary to store simulation results in
        self.results = {}
        for (i, states) in enumerate(results):
            # states = ith lot of states
            # oid = the 'oid' value of the operator instance the results were 
            # after. -1 if before any operators (start of circuit)
            oid = self.get_oid(i)
            # Format and store the states
            self.results[oid] = map(
                    lambda state: format_state(state, self.register_size),
                    states
            )

    # Returns the "oid" value of the (i-1)th operator, or -1 if we're at i=0
    # See self.simulate() for usage
    def get_oid(self, i):
        if i < 1: return -1
        else: return self.circuit[i-1]["oid"]


    # Run a fragment of the circuit
    # Fragment is specified in circuit
    # The input state tuples are specified in input_states
    def run_fragment(self, circuit, input_states):
        # If there are no operators in the circuit, we don't need to run it
        if len(circuit) == 0: return [input_states]

        # As we may be branching out, we want our own copy of circuit to modify
        circuit = list(circuit)
        # Pop off the next operator (technically operator instance) to run
        op = circuit.pop(0)

        # The functions to run dependeing on the type of operator present
        new_register_functions = {
                'gate': self.apply_gate,
                'measurement': self.apply_measurement,
                'controlled': self.apply_controlled
        }

        # states will contain the new list of states after we've run op
        states = []
        # For each input state tuple
        for (input_register, probability, measurements) in input_states:
            # Obtain a list of state tuples present after running op
            new_states = new_register_functions[op['operator_type']](
                    op,
                    input_register,
                    measurements
            )

            # For each state tuple
            for i in range(len(new_states)):
                new_state = list(new_states[i])
                # Multiply the probability of the state by the probability
                # that we're even in this input state tuple
                new_state[1] *= probability
                # Save new_state back into new_states
                new_states[i] = tuple(new_state)

            # Append new_states onto states
            states += new_states

        # Call ourselves to simulate the next circuit operator
        # (We've already popped off op from circuit)
        new_states_list = self.run_fragment(circuit, states)

        # Insert input_states at the start of the list
        new_states_list.insert(0, input_states)

        return new_states_list

    # Apply a gate
    # moutputs = measurement outputs
    def apply_gate(self, op, input_register, moutputs):
        # Find the operator of the gate instance we're running
        gate = self.find_gate(op['operator_id'])

        # Number of lines before the lines we're running on
        before = op['lines'][0]
        # Number of lines after the lines we're running on
        after = self.register_size - op['lines'][-1] - 1
        # Obtain an overall matrix by Kronecking together (matrix tensor
        # product) an identity on (before) lines, the matrix we want to run
        # and an identity on (after) lines
        matrix = TensorProduct(eye(2**before), gate.matrix, eye(2**after))

        # The only thing running the gate affects is the state, which is just
        # |phi'> = M|phi>
        return [(matrix * input_register, 1, moutputs)]

    # Apply a measurement
    # moutputs = measurement outputs
    def apply_measurement(self, op, input_register, moutputs):
        # Find the operator of the measurement instance we're running
        measurement = self.find_measurement(op['operator_id'])

        # Using the same principle as in apply_gate, obtain a matrix we can
        # run on all lines
        before = op['lines'][0]
        after = self.register_size - op['lines'][-1] - 1
        matrix = TensorProduct(eye(2**before), measurement.matrix, eye(2**after))

        # To contain the possible states the system could fall into after the
        # measurement
        states = []
        # For each triple in the eigensystem
        # Eigenvalue, duplicity (not needed here), eigenvectors
        for val, dup, vecs in matrix.eigenvects():
            # For each vector in the eigenvector basis
            for vec in vecs:
                # Obtain a projection operator P = x*x^T
                p = vec * vec.T

                # Probability of this outcome Pr = |phi>^T * P * |phi>
                # [0] because we want the value of a 1x1 matrix
                probability = (input_register.T * p * input_register)[0]
                # Don't need to consider this outcome anymore if it
                # won't happen
                if probability == 0: continue

                # Calculate the new register |phi'> = P*|phi> / sqrt(Pr)
                register = p * input_register / sqrt(probability)

                # Copy the measurement outputs as we're branching so don't
                # want to affect other branches
                moutputs = dict(moutputs)
                # Store the outcome that's just happened in the measurement
                # outputs
                moutputs[op['oid']] = val

                # Add the state tuple into states
                state = (register, probability, moutputs)
                states.append(state)

        return states

    # Apply a controlled gate
    # moutputs = measurement outputs
    def apply_controlled(self, op, input_register, moutputs):
        # Find the operator of the controlled gate instance we're running
        gate = self.find_controlled_gate(op['operator_id'])

        # Find the value that was measured by the measurement we're
        # conditional upon
        # We need the second line because the sympified value may be different
        # from the moutputs value. This will affect array indexing, but ==
        # will still find them equal
        value = moutputs[op['measurement_id']]
        value = filter(lambda val: val == value, gate.values)[0]
        # Find the matrix corresponding to that value
        # TODO Do we need both the parse_expr.str and the filter expression?
        small_matrix = gate.matrices[custom_parse_expr(str(value))]

        # Use the same logic as in apply_gate and apply_measurement to tensor
        # together a large matrix we can apply to all lines
        before = op['lines'][0]
        after = self.register_size - op['lines'][-1] - 1
        matrix = TensorProduct(eye(2**before), small_matrix, eye(2**after))

        # Now just apply the gate like in apply_gate
        return ([(matrix * input_register, 1, moutputs)])

    # Find a gate with operator id oid
    def find_gate(self, oid):
        return self.find_operator(oid, self.gates)

    # Find a measurement with operator id oid
    def find_measurement(self, oid):
        return self.find_operator(oid, self.measurements)

    # Find a controlled gate with operator id oid
    def find_controlled_gate(self, oid):
        return self.find_operator(oid, self.controlled_gates)

    # Find an operator with operator id iod in list lis
    def find_operator(self, oid, lis):
        return filter(lambda op: op.id == oid, lis)[0]


# If the file's being run, rather than loaded as a library
if __name__ == "__main__":
    # Lots of json data about the circuit should be passed as a command-line
    # argument
    # register_size, gates, measurements, controlled_gates, circuit and
    # input_register need to be in data
    data = json.loads(sys.argv[1])

    # Initialize a new simulation using this data
    sim = QuantumSimulation(data)
    # Run the simulation
    sim.simulate()

    # Print out a JSONified version of the results
    print pipes.quote(json.dumps({
        'results': sim.results,
        'probabilities': sim.probabilities
    }))
