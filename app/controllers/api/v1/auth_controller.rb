module Api
  module V1
    class AuthController < ApplicationController
      def login
        admin = ::Admin.find_by(email: params[:email])

        if admin&.active? && admin&.authenticate(params[:password])
          token = JsonWebToken.encode(admin_id: admin.id)
          render json: {
            token: token,
            admin: {
              id: admin.id,
              email: admin.email,
              name: admin.name,
              role: admin.role
            }
          }, status: :ok
        else
          render json: { error: 'Email hoặc mật khẩu không đúng' }, status: :unauthorized
        end
      end

      def me
        authorize_request
        return unless @current_admin

        render json: {
          id: @current_admin.id,
          email: @current_admin.email,
          name: @current_admin.name,
          role: @current_admin.role
        }
      end
    end
  end
end
