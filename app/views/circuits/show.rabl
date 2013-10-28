object @circuit

attributes :operators, :lines, :initial_state, :name, :world_readable, :world_editable
# TODO Better syntax?
code(:iterations) { @iterations }
code(:can_change_settings) { @can_change_settings }
