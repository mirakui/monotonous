require 'rubygems'
require 'active_record'
require 'active_support/core_ext'
require 'optparse'
require 'yaml'
require 'pathname'

#SCHEDULE_OFFSET = 91.days.ago # (4*3+1)weeks = about 3month
SCHEDULE_OFFSET = 1.year.ago

OPTS = OptionParser.getopts('v', 'pit:', 'notweet', 'noprogress')
OPTS['pit'] ||= 'mirakui_retro'

$pit = YAML.load Pathname(__FILE__).dirname.join("secret.yml").read

base_dir = File.join(File.dirname(__FILE__), '..')
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => File.join(base_dir, 'db', 'mirakui.db')
)

class Schedule < ActiveRecord::Base
  validates_uniqueness_of :status_id
end

class Var < ActiveRecord::Base
  validates_uniqueness_of :key

  def self.[](key)
    var = self.find :first, :conditions => { :key => key.to_s }
    var ? var.value : nil
  end

  def self.[]=(key, value)
    var = self.find(:first, :conditions => { :key => key.to_s })|| Var.new(:key => key.to_s)
    var.value = value
    var.save
  end
end

