#!/usr/bin/python
from quantum_simulation import QuantumSimulation
circuit = [
        {'id': 1, 'oid': 1, 'operator_type': 'gate', 'operator_id': 1, 'lines': [0]},
        {'id': 5, 'oid': 5, 'operator_type': 'measurement', 'operator_id': 1, 'lines': [0]},
        {'id': 6, 'oid': 6, 'operator_type': 'controlled', 'operator_id': 1, 'lines': [1], 'measurement_id': 5},
        {'id': 7, 'oid': 7, 'operator_type': 'measurement', 'operator_id': 1, 'lines': [1]}
]

sim = QuantumSimulation(2)
results = sim.run_circuit(circuit, "1/sqrt(2)|00>-1/sqrt(2)|00>-|01>")
for position, states in sorted(results.iteritems(), key=lambda x: x[0]):
    print
    print "================="
    print "Position %d" % position
    print "================="
    for state in states:
        print "%s wp %s" % (state['state_string'], state['probability_string'])
