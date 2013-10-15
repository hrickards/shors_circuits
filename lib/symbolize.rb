class Hash
  # Based on http://www.dzone.com/snippets/recursively-symbolize-keys-0
  def recursively_symbolize_keys!
    self.symbolize_keys!
    self.values.each do |val|
      val.recursively_symbolize_keys! if val.is_a? Hash
    end
  end

  def recursively_symbolize_keys
    a = self.clone
    a.recursively_symbolize_keys!

    a
  end
end
