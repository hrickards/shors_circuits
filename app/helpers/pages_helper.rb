Quantum::App.helpers do
  # http://stackoverflow.com/questions/3705898
  def nav_link(text, path)
    active = request.path_info =~ /^#{path}$/
    active = (yield request.path_info) if block_given?
    class_name = active ? 'active' : nil

    content_tag(:li, :class => class_name) do
      link_to text, path
    end
  end
end
