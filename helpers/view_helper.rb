module ViewHelper
  def error_for?(object, key)
    if !object.nil? && !object.errors[key].empty?
      return true
    end
    return false
  end

  def render_error_message(object, key)
    if error_for?(object, key)
      return "<p class='error dismissible message'>#{key.to_s.capitalize}: #{object.errors[key].join(", ")}</p>"
    end
  end
end
