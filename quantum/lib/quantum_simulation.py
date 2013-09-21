#!/usr/bin/python
from sympy import Matrix, eye, sqrt, latex
from sympy.physics.quantum import TensorProduct
from numpy import binary_repr
import pipes
import json
import sys, urllib

GATES = [
    {'id': 1, 'name': 'Hadamard', 'matrix': 1/sqrt(2) * Matrix([[1,1],[1,-1]])},
    {'id': 2, 'name': 'CNOT', 'matrix': Matrix([[1,0,0,0],[0,1,0,0],[0,0,0,1],[0,0,1,0]])},
    {'id': 3, 'name': 'Z', 'matrix': Matrix([[1,0],[0,-1]])}
]
MEASUREMENTS = [
    {'id': 1, 'name': 'Standard basis', 'matrix': Matrix([[1,0],[0,-1]])}
]
CONTROLLED_GATES = [
    {'id': 1, 'name': 'G', 'values': [-1, 1], 'matrices': {
        -1: 1/sqrt(2) * Matrix([[1,1],[1,-1]]),
        1: eye(2)
    }}
]

# TODO Clean this up, rather than bunging a staticmethod onto everything
class QuantumSimulation:
    def __init__(self, register_size):
        self.register_size = register_size

    def run_circuit(self, circuit, input_register):
        self.states = {-1: [[input_register, 1]]}
        circuit.sort(key=lambda x: x['id'])
        self.circuit = list(circuit)

        results = self.run_fragment(circuit, [(Matrix(input_register), 1, {})])
        results = {self.get_oid(i): map(self.format_state, states) for i, states in enumerate(results)}
        return results

    def get_oid(self, i):
        if i < 1:
            return -1
        else:
            return self.circuit[i-1]["oid"]

    def format_state(self, stateArray):
        state = stateArray[0]
        probability = stateArray[1]

        return {
                'stateString': self.format_state_string(state),
                'stateLatex': self.format_state_latex(state),
                'probabilityString': str(probability),
                'probabilityLatex': urllib.quote(latex(probability))
                }

    def format_state_latex(self, state):
        states = []
        for i in range(len(state)):
            label = "\\ket{%s}" % binary_repr(i, self.register_size)
            coefficient = "(%s)" % latex(state[i])
            
            if state[i] == 1:
                states.append(label)
            elif state[i] != 0:
                states.append(coefficient + label)
        return urllib.quote(" + ".join(states).replace("+ (-", "- ("))

    def format_state_string(self, state):
        states = []
        for i in range(len(state)):
            label = "|%s>" % binary_repr(i, self.register_size)
            coefficient = "(%s)" % str(state[i])
            
            if state[i] == 1:
                states.append(label)
            elif state[i] != 0:
                states.append(coefficient + label)
        return " + ".join(states).replace("+ (-", "- (")

    def run_fragment(self, circuit, input_states):
        if len(circuit) == 0:
            return [input_states]
        else:
            circuit = list(circuit)

            op = circuit.pop(0)

            new_register_functions = {'gate': self.apply_gate, 'measurement': self.apply_measurement, 'controlled': self.apply_controlled}

            states = []
            for (input_register, probability, moutputs) in input_states:
                nstates = new_register_functions[op['operatorType']](op, input_register, moutputs)
                for i in range(len(nstates)):
                    nstate = list(nstates[i])
                    nstate[1] *= probability
                    nstates[i] = tuple(nstate)
                states += nstates

            new_statess = self.run_fragment(circuit, states)

            for i in range(len(new_statess[0])): new_statess[0][i] = new_statess[0][i][0:2]

            new_statess.insert(0, input_states)
            
            return new_statess

    def apply_gate(self, op, input_register, moutputs):
        gate = self.find_gate(op['operatorId'])

        before = op['lines'][0]
        after = self.register_size - op['lines'][-1] - 1
        matrix = TensorProduct(eye(2**before), gate['matrix'], eye(2**after))

        return [(matrix * input_register, 1, moutputs)]

    def apply_measurement(self, op, input_register, moutputs):
        measurement = self.find_measurement(op['operatorId'])

        before = op['lines'][0]
        after = self.register_size - op['lines'][-1] - 1
        matrix = TensorProduct(eye(2**before), measurement['matrix'], eye(2**after))

        states = []

        for val, dup, vecs in matrix.eigenvects():
            for vec in vecs:
                p = vec * vec.T
                probability = (input_register.T * p * input_register)[0]
                if probability == 0: continue
                register = p * input_register / sqrt(probability)

                moutputs = dict(moutputs)
                moutputs[op['oid']] = val

                state = (register, probability, moutputs)
                states.append(state)
        return states
            
    def apply_controlled(self, op, input_register, moutputs):
        gate = self.find_controlled_gate(op['operatorId'])
        value = moutputs[op['measurementId']]
        value = filter(lambda x: x == value, gate['values'])[0]
        smatrix = gate['matrices'][value]

        before = op['lines'][0]
        after = self.register_size - op['lines'][-1] - 1
        matrix = TensorProduct(eye(2**before), smatrix, eye(2**after))

        return ([(matrix * input_register, 1, moutputs)])

        #                 registers = self.run_fragment(circuit, register, measurement_outputs) #                 for i in range(len(registers)): registers[i][-1] = registers[i][-1] * probability
    def find_gate(self, oid):
        return filter(lambda o: o['id'] == oid, GATES)[0]

    def find_measurement(self, oid):
        return filter(lambda o: o['id'] == oid, MEASUREMENTS)[0]

    def find_controlled_gate(self, oid):
        return filter(lambda o: o['id'] == oid, CONTROLLED_GATES)[0]

if __name__ == "__main__":
    data = json.loads(sys.argv[1])

    sim = QuantumSimulation(data['register_size'])
    results = sim.run_circuit(data['circuit'], data['input_register'])

    print pipes.quote(json.dumps(results))
