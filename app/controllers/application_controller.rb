class ApplicationController < ActionController::API
  before_action :authenticate!

  attr_reader :current_user, :current_organization

  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    render json: { error: "Unauthorized" }, status: :unauthorized and return unless token

    payload = JsonWebToken.decode(token)
    render json: { error: "Unauthorized" }, status: :unauthorized and return unless payload

    @current_user = User.find_by(id: payload["user_id"])
    render json: { error: "Unauthorized" }, status: :unauthorized and return unless @current_user

    if payload["organization_id"].present?
      @current_organization = Organization.find_by(id: payload["organization_id"])
      render json: { error: "Unauthorized" }, status: :unauthorized unless @current_organization
    else
      render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user.super_admin?
    end
  end

  def require_role!(*roles)
    unless current_user&.role&.to_sym.in?(roles)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def require_admin!
    require_role!(:admin, :super_admin)
  end

  def require_super_admin!
    require_role!(:super_admin)
  end

  DEFAULT_PAGE_SIZE = 25

  def paginate(collection)
    page    = [ (params[:page] || 1).to_i, 1 ].max
    limit   = [ (params[:limit] || DEFAULT_PAGE_SIZE).to_i, 100 ].min
    total   = collection.count
    pages   = (total.to_f / limit).ceil

    records = collection.offset((page - 1) * limit).limit(limit)
    meta    = { page: page, limit: limit, total: total, pages: pages,
                next: page < pages ? page + 1 : nil,
                prev: page > 1 ? page - 1 : nil }

    { records: records, meta: meta }
  end
end
