class Api::V1::BaseController < ActionController::API
  # skip_before_action :verify_authenticity_token
  # skip_before_action :require_login
  before_action :authenticate_api_request

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from StandardError, with: :internal_server_error

  private

  def authenticate_api_request
    # Simple API authentication - in production, use proper API keys or JWT
    unless request.headers["Authorization"] == "Bearer demo-api-key"
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: {
      error: "Validation failed",
      details: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    render json: { error: "#{exception} Internal server error" }, status: :internal_server_error
  end

  def success_response(data, message = "Success")
    render json: {
      status: "success",
      message: message,
      data: data
    }
  end

  def error_response(message, status = :bad_request)
    render json: {
      status: "error",
      message: message
    }, status: status
  end
end
