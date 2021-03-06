# Redmine - project management software
# Copyright (C) 2006-2011  See readme for details and license
#

require File.dirname(__FILE__) + '/../test_helper'
require 'watchers_controller'

# Re-raise errors caught by the controller.
class WatchersController; def rescue_action(e) raise e end; end

class WatchersControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules,
           :issues, :trackers, :projects_trackers, :issue_statuses, :enumerations, :watchers
  
  def setup
    @controller = WatchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_get_watch_should_be_invalid
    @request.session[:user_id] = 3
    get :watch, :object_type => 'issue', :object_id => '1'
    assert_response 405
  end
  
  def test_watch
    @request.session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, :object_type => 'issue', :object_id => '1'
      assert_response :success
      assert_select_rjs :replace_html, 'watcher'
    end
    assert Issue.find(1).watched_by?(User.find(3))
  end
  
  def test_watch_should_be_denied_without_permission
    Role.find(2).remove_permission! :view_issues
    @request.session[:user_id] = 3
    assert_no_difference('Watcher.count') do
      xhr :post, :watch, :object_type => 'issue', :object_id => '1'
      assert_response 403
    end
  end

  def test_watch_with_multiple_replacements
    @request.session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, :object_type => 'issue', :object_id => '1', :replace => ['watch_item_1','watch_item_2']
      assert_response :success
      assert_select_rjs :replace_html, 'watch_item_1'
      assert_select_rjs :replace_html, 'watch_item_2'
    end
  end
  
  def test_unwatch
    @request.session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, :object_type => 'issue', :object_id => '2'
      assert_response :success
      assert_select_rjs :replace_html, 'watcher'
    end
    assert !Issue.find(1).watched_by?(User.find(3))
  end

  def test_unwatch_with_multiple_replacements
    @request.session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, :object_type => 'issue', :object_id => '2', :replace => ['watch_item_1', 'watch_item_2']
      assert_response :success
      assert_select_rjs :replace_html, 'watch_item_1'
      assert_select_rjs :replace_html, 'watch_item_2'
    end
    assert !Issue.find(1).watched_by?(User.find(3))
  end

  def test_new_watcher
    @request.session[:user_id] = 2
    assert_difference('Watcher.count') do
      xhr :post, :new, :object_type => 'issue', :object_id => '2', :watcher => {:user_id => '4'}
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
    end
    assert Issue.find(2).watched_by?(User.find(4))
  end
  
  def test_remove_watcher
    @request.session[:user_id] = 2
    assert_difference('Watcher.count', -1) do
      xhr :post, :destroy, :object_type => 'issue', :object_id => '2', :user_id => '3'
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
    end
    assert !Issue.find(2).watched_by?(User.find(3))
  end
end
