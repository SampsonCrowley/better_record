<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= class_name %>Controller < ApplicationController
  # == Modules ============================================================

  # == Class Methods ======================================================

  # == Pre/Post Flight Checks =============================================

  # == Actions ============================================================
<% actions.each do |action| -%>
  def <%= action %>
  end

<% end -%>
  # == Cleanup ============================================================

  # == Utilities ==========================================================

end
<% end -%>
