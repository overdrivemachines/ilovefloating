module ApplicationHelper
  # https://gist.github.com/suryart/7418454#gistcomment-970347
  def bootstrap_class_for(flash_type)
    {
      success: 'alert-success',
      error: 'alert-danger',
      alert: 'alert-warning',
      notice: 'alert-primary'
    }[flash_type.to_sym] || flash_type.to_s
  end

  # https://rubyplus.com/articles/3321-Pretty-Page-Title-in-Rails-5
  def title(page_title)
    content_for(:title) { page_title }
  end
end
