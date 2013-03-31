module PatchLog

  class Diff < ActiveRecord::Base

    @abstract_class = true
    default_scope order('version_id DESC')

    def self.between(first, last)
      where("version_id >= ? AND version_id <= ?",
            PatchLog.to_timestamp(first),
            PatchLog.to_timestamp(last))
    end

    def version_id
      PatchLog.from_timestamp(read_attribute(:version_id))
    end

    def version_id=(time)
      write_attribute(:version_id, PatchLog.to_timestamp(time))
    end

    def each_patch
      attributes.each_pair do |key, value|
        yield $1.to_sym, value if value && key =~ /^(.+)_diff$/
      end
    end

  end

end
