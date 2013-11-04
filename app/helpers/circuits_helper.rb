Quantum::App.helpers do
  # If url is /circuits/... redirect to /circuits
  # Else to url
  def parse_redirect(url)
    if url =~ /\/circuits\//
      return "/circuits"
    else
      return url
    end
  end
end
