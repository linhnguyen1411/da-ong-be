module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authorize_request
      end
    end
  end
end
