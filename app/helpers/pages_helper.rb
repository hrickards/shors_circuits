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

  # gist potomak/1600856
  def flash_class(level)
    case level
    when :notice then "info"
    when :error then "danger"
    when :alert then "warning"
    end
  end
end
