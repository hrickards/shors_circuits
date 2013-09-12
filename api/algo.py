from sympy import Matrix, eye, sqrt, latex
from sympy.physics.quantum import TensorProduct
from numpy import binary_repr
import sys, urllib

def run_circuit(circuit, input_register, register_size):
    circuit.sort(key=lambda x: x['id'])
    states = run_fragment(circuit, Matrix(input_register), register_size, {})
    return map(lambda x: {'stateString':format_state_string(x[0], register_size), 'stateLatex':format_state_latex(x[0], register_size), 'probabilityString':str(x[1])}, states)

def format_state_latex(state, length):
    base = "http://localhost:4568/qcircuit/"
    states = []
    for i in range(len(state)):
        label = "\\ket{%s}" % binary_repr(i, length)
        coefficient = "(%s)" % latex(state[i])
        
        if state[i] == 1:
            states.append(label)
        elif state[i] != 0:
            states.append(coefficient + label)
    return base + urllib.quote(" + ".join(states).replace("+ (-", "- (")) + ".svg"


def format_state_string(state, length):
    states = []
    for i in range(len(state)):
        label = "|%s>" % binary_repr(i, length)
        coefficient = "(%s)" % str(state[i])
        
        if state[i] == 1:
            states.append(label)
        elif state[i] != 0:
            states.append(coefficient + label)
    return " + ".join(states).replace("+ (-", "- (")


def run_fragment(circuit, input_register, register_size, measurement_outputs):
    if len(circuit) == 0:
        return [[input_register, 1]]
    else:
        circuit = list(circuit)
        op = circuit.pop(0)

        if op['operatorType'] == 'gate':
            gate = find_gate(op['operatorId'])

            before = op['qubits'][0]
            after = register_size - op['qubits'][-1] - 1
            matrix = TensorProduct(eye(2**before), gate['matrix'], eye(2**after))

            print("Apply gate %s to qubits %s" % (gate['name'], ", ".join(map(str, op['qubits']))))

            register = matrix * input_register 

            return run_fragment(circuit, register, register_size, measurement_outputs)
        elif op['operatorType'] == 'measurement':
            measurement = find_measurement(op['operatorId'])
            before = op['qubits'][0]
            after = register_size - op['qubits'][-1] - 1
            matrix = TensorProduct(eye(2**before), measurement['matrix'], eye(2**after))

            print("Apply measurement %s to qubits %s" % (measurement['name'], ", ".join(map(str, op['qubits']))))

            all_registers = []

            for val, dup, vecs in matrix.eigenvects():
                for vec in vecs:
                    p = vec * vec.T
                    probability = (input_register.T * p * input_register)[0]
                    if probability == 0: continue
                    register = p * input_register / sqrt(probability)

                    measurement_outputs = dict(measurement_outputs)
                    measurement_outputs[op['id']] = val

                    registers = run_fragment(circuit, register, register_size, measurement_outputs)
                    for i in range(len(registers)):
                        registers[i][-1] = registers[i][-1] * probability

                    all_registers += registers
            
            return all_registers

        elif op['operatorType'] == 'controlled_gate':
            gate = find_controlled_gate(op['operatorId'])
            value = measurement_outputs[op['controlInput']]
            value = filter(lambda x: x == value, gate['values'])[0]
            smatrix = gate['matrices'][value]

            before = op['qubits'][0]
            after = register_size - op['qubits'][-1] - 1
            matrix = TensorProduct(eye(2**before), smatrix, eye(2**after))

            print("Apply controlled gate %s for %.2f to qubits %s" % (gate['name'], value, ", ".join(map(str, op['qubits']))))

            register = matrix * input_register 

            return run_fragment(circuit, register, register_size, measurement_outputs)
        else:
            raise Exception("Error: unknown operator %s" % str(op))

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

def find_gate(oid):
    return filter(lambda o: o['id'] == oid, GATES)[0]

def find_measurement(oid):
    return filter(lambda o: o['id'] == oid, MEASUREMENTS)[0]

def find_controlled_gate(oid):
    return filter(lambda o: o['id'] == oid, CONTROLLED_GATES)[0]

# circuit = [
#     {'id': 1, 'operatorType': 'gate', 'operatorId': 1, 'qubits': [0]},
#     {'id': 2, 'operatorType': 'gate', 'operatorId': 2, 'qubits': [0, 1]},
#     {'id': 3, 'operatorType': 'gate', 'operatorId': 3, 'qubits': [2]},
#     {'id': 4, 'operatorType': 'measurement', 'operatorId': 1, 'qubits': [0]},
#     {'id': 5, 'operatorType': 'controlled_gate', 'operatorId': 1, 'qubits': [1], 'controlInput': 4},
#     {'id': 6, 'operatorType': 'controlled_gate', 'operatorId': 1, 'qubits': [1], 'controlInput': 4},
#     {'id': 7, 'operatorType': 'measurement', 'operatorId': 1, 'qubits': [1]},
#     {'id': 8, 'operatorType': 'controlled_gate', 'operatorId': 1, 'qubits': [2], 'controlInput': 7}
# ]
# input_register = Matrix([1,0,0,0,0,0,0,0])

# circuit = [
    # {'id': 1, 'operatorType': 'gate', 'operatorId': 2, 'qubits': [0,1]},
    # {'id': 2, 'operatorType': 'gate', 'operatorId': 1, 'qubits': [0]},
    # {'id': 3, 'operatorType': 'measurement', 'operatorId': 1, 'qubits': [0]}
# ]
# input_register = Matrix([1,0,0,0])
# register_size = 2

# print(run_fragment(circuit, input_register, 2, {}))
