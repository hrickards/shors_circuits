Quantum::App.helpers do
  # http://stackoverflow.com/questions/3705898
  def nav_link(text, path, inexact=false)
    regex = inexact ? /^#{path}/ : /^#{path}$/
    class_name = (request.path_info=~regex) ? 'active' : nil

    content_tag(:li, :class => class_name) do
      link_to text, path
    end
  end
end
