object @circuit

attributes :operators, :lines, :initial_state, :name
# TODO Better syntax?
code(:iterations) { @iterations }
code(:can_modify_name) { @can_modify_name }
