require 'active_support/concern'
require 'tempfile'
require 'composite_primary_keys'

require 'patch_log/diff'

module PatchLog

  def self.to_timestamp(time)
    return unless time
    time.to_i * 1_000_000 + time.usec
  end

  def self.from_timestamp(timestamp)
    return unless timestamp
    Time.at(timestamp / 1_000_000, timestamp % 1_000_000)
  end

  def self.diff(before, after)
    before_file = Tempfile.open('patchlog_before') { |f| f << before }
    after_file = Tempfile.open('patchlog_after') { |f| f << after }
    `diff #{before_file.path} #{after_file.path}`
  end

  def self.restore(current_attributes, diffs)
    current_attributes.each_pair do |attr, value|
      File.open(tempfile_path(attr), 'w') { |f| f << value }
    end

    diffs.each do |diff|
      diff.each_patch do |attr, patch|
        IO.popen("patch -Rs #{tempfile_path(attr)} -", 'w') { |io| io << patch }
      end
    end

    {}.tap do |result|
      current_attributes.each_key do |attr|
        result[attr] = File.read(tempfile_path(attr))
      end
    end
  end

  def self.tempfile_path(attr)
    file_suffix = "#{Process.pid}_#{Thread.current.object_id}"
    filename = "patch_log_#{attr}_#{file_suffix}"
    File.join(Dir.tmpdir, filename)
  end
  private_class_method :tempfile_path

  extend ActiveSupport::Concern

  included do
    class_attribute :patch_log_columns
    class_attribute :patch_log_class
    class_attribute :patch_log_delimiter
    self.patch_log_columns = []

    id_name = "#{name.underscore}_id"
    class_name = "#{name.demodulize}Diff"
    namespace_name = name.deconstantize
    namespace = namespace_name.present? ? namespace_name.constantize : Object
    self.patch_log_class = Class.new(Diff) do
      self.primary_keys = [id_name, :version_id]
    end
    namespace.const_set class_name, patch_log_class

    has_many :diffs, :class_name => class_name
    before_create :initialize_version
    before_update :record_diffs
  end

  module ClassMethods

    def patch_log(*columns)
      self.patch_log_columns += columns
    end

  end

  def current_version_id
    timestamp = read_attribute(:current_version_id)
    PatchLog.from_timestamp(timestamp)
  end

  def current_version_id=(version)
    write_attribute(:current_version_id, PatchLog.to_timestamp(version))
  end

  def previous_versions
    diffs.
      pluck(:version_id).
      map(&PatchLog.method(:from_timestamp))
  end

  def restore_version(version)
    diff_range = diffs.between(version, current_version_id).entries
    if diff_range.empty? || diff_range.last.version_id != version
      raise ArgumentError, "No such version #{version}"
    end

    current_attributes = {}
    attributes.slice(*self.class.patch_log_columns.map(&:to_s)).
      each_pair { |attr, value| current_attributes[attr] = to_delimited(value) }
    restored = PatchLog.restore(current_attributes, diff_range)

    clone.tap do |version|
      restored.each_pair do |column, data|
        version.__send__("#{column}=", from_delimited(data))
      end
      version.readonly!
    end
  end

  private

  def initialize_version
    self.current_version_id = Time.now
  end

  def record_diffs
    patches = generate_patches
    if patches.any?
      new_version_id = Time.now
      diffs.create!({:version_id => current_version_id}.merge(patches))
      self.current_version_id = new_version_id
    end
  end

  def generate_patches
    {}.tap do |patches|
      self.class.patch_log_columns.each do |column|
        change = changes[column]
        if change.present?
          patches["#{column}_diff"] =
            PatchLog.diff(*change.map(&method(:to_delimited)))
        end
      end
    end
  end

  def to_delimited(text)
    delimiter = self.class.patch_log_delimiter
    return text if delimiter.nil?
    text = text.gsub("\n", "\n\u2028")
    text.gsub!(delimiter, "\\0\n")
    text
  end

  def from_delimited(text)
    return text if self.class.patch_log_delimiter.nil?
    text = text.gsub("\n", '')
    text.gsub!("\u2028", "\n")
    text
  end

end
