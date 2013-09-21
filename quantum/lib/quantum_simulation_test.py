#!/usr/bin/python
from quantum_simulation import QuantumSimulation

# circuit = [
#         {'id': 1, 'oid': 1, 'operatorType': 'gate', 'operatorId': 1, 'lines': [0]},
#         {'id': 2, 'oid': 2, 'operatorType': 'measurement', 'operatorId': 1, 'lines': [0]},
#         {'id': 3, 'oid': 3, 'operatorType': 'gate', 'operatorId': 1, 'lines': [1]}
# ]

circuit = [
        {'id': 1, 'oid': 1, 'operatorType': 'gate', 'operatorId': 1, 'lines': [0]},
        {'id': 5, 'oid': 5, 'operatorType': 'measurement', 'operatorId': 1, 'lines': [0]},
        {'id': 6, 'oid': 6, 'operatorType': 'controlled', 'operatorId': 1, 'lines': [1], 'measurementId': 5},
        {'id': 7, 'oid': 7, 'operatorType': 'measurement', 'operatorId': 1, 'lines': [1], 'measurementId': 5}
]

sim = QuantumSimulation(2)
results = sim.run_circuit(circuit, [1,0,0,0])
for position, states in sorted(results.iteritems(), key=lambda x: x[0]):
    print
    print "================="
    print "Position %d" % position
    print "================="
    for state in states:
        print "%s wp %s" % (state['stateString'], state['probabilityString'])
