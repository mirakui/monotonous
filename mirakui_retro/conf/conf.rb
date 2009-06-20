require 'rubygems'
require 'active_record'
require 'pit'

SCHEDULE_OFFSET = 91.days.ago # (4*3+1)weeks = about 3month

$pit = Pit.get(($DEBUG ? 'mirakui_retro_debug' : 'mirakui_retro'), :require => {
  'login' => 'mirakui_retro',
  'password' => ''
})

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
    var = Var.new :key => key.to_s, :value => value
    var.save
  end
end

