
class ErrorsPage < Page
  singleton :errors

  # Automatically populate the errors list with a 404 & 500 page
  prototype { |errors|
    error404 = ErrorPage.new(slug: '404', code: '404', title: 'Not Found')
    errors.errors << error404
    error500 = ErrorPage.new(slug: '500', code: '500', title: 'Internal Server Error')
    errors.errors << error500
    error404.save
    error500.save
    errors.save
  }

  box :errors do
    allow :ErrorPage
  end
end

class ErrorPage < Page
  field :code
end
