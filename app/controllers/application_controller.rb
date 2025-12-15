class ApplicationController < ActionController::API
  include Rails.application.routes.url_helpers

  def authorize_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    decoded = JsonWebToken.decode(token)

    if decoded
      @current_admin = ::Admin.find_by(id: decoded[:admin_id])
    end

    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_admin
  end

  def current_admin
    @current_admin
  end

  def default_url_options
    { host: request.host, port: request.port }
  end
end
