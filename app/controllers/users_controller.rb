# coding: utf-8
class UsersController < ApplicationController
  after_filter :verify_authorized, except: %i[reactivate]
  inherit_resources
  defaults finder: :find_active!
  actions :show, :update, :update_password, :unsubscribe_notifications, :credits, :destroy
  respond_to :json, only: [:contributions, :projects]

  before_action :update_staffs, only: :update

  def destroy
    authorize resource
    resource.deactivate
    sign_out(current_user) if current_user == resource
    flash[:notice] = t('users.current_user_fields.deactivate_notice', name: resource.name)
    redirect_to root_path
  end

  def unsubscribe_notifications
    authorize resource
    redirect_to user_path(current_user, anchor: 'unsubscribes')
  end

  def credits
    authorize resource
    redirect_to user_path(current_user, anchor: 'credits')
  end

  def show
    authorize resource
    show!{
      fb_admins_add(@user.facebook_id) if @user.facebook_id
      @title = "#{@user.display_name}"
      @credits = @user.contributions.can_refund
      @subscribed_to_posts = @user.posts_subscription
      @unsubscribes = @user.project_unsubscribes
      @credit_cards = @user.credit_cards
      @projects = projects
      build_bank_account
    }
  end

  def approve
    @user = User.find(params[:id])
    authorize @user
    @user.update_attribute(:approved_at, Time.now)
    @user.save
    redirect_to user_path(@user)
  end

  def reactivate
    user = params[:token].present? && User.find_by(reactivate_token: params[:token])
    if user
      user.reactivate
      sign_in user
      flash[:notice] = t('users.reactivated')
    else
      flash[:error] = t('users.failed_reactivation')
    end
    redirect_to root_path
  end

  def update
    authorize resource
    update! do |success,failure|
      success.html do
        flash[:notice] = t('users.current_user_fields.updated')
      end
      failure.html do
        flash[:error] = @user.errors.full_messages.to_sentence
      end
    end
    return redirect_to user_path(@user, anchor: 'settings')
  end

  def update_password
    authorize resource
    if @user.update_with_password(params[:user])
      flash[:notice] = t('users.current_user_fields.updated')
    else
      flash[:error] = @user.errors.full_messages.to_sentence
    end
    return redirect_to user_path(@user, anchor: 'settings')
  end

  protected

  def policy_scope(scope)
    @_policy_scoped = true
    ProjectPolicy::UserScope.new(current_user, resource, scope).resolve
  end

  def projects
    @projects ||= policy_scope(resource.projects)
  end

  private

  def build_bank_account
    @user.build_bank_account unless @user.bank_account
  end

  def permitted_params
    params.permit(policy(resource).permitted_attributes)
  end

  def update_staffs
    unless params[:user].blank? || params[:user][:staffs].blank?
      params[:user][:staffs] = params[:user][:staffs].reject(&:blank?)
    end
  end
end
