class Page < ActiveRecord::Base

  include PatchLog

  patch_log :body
  self.patch_log_delimiter = /[[:space:]]/

end
