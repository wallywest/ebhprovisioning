require 'xmlsimple'
require 'active_record'
        ActiveRecord::Base.establish_connection(
                :adapter  => "mysql2",
                :host     => 'localhost',
                :username => 'whmcs',
                :password => 'whmcsfinal123',
                :database => 'whmcs',
                :pool => 10
        )
        class Vdspool < ActiveRecord::Base
                set_table_name 'vdspool'
                validates_uniqueness_of :eid
		class << self
			def next_veid
				select("veid").order("veid DESC").limit(1).where("veid < 22000").first.veid.to_i + 1
			end
		end
        end
        class Ippool < ActiveRecord::Base
             set_table_name 'ippool'
             belongs_to :iprange, :class_name => 'Iprange'
        end
        class Iprange < ActiveRecord::Base
              has_many :ippool, :class_name => 'Ippool'
	      scope :get_all_cblock, lambda {|value|
			joins(:ippool).
			select("ippool.id,ipranges.cblock,ipranges.id AS cid,ippool.ips,ippool.ip_group").
			where("ipranges.cblock='#{value}'")
	      }
	      class << self
	      def get_by_ipgroup(cblock,ipgroup)
			get_all_cblock("#{cblock}").where("ippool.ip_group=#{ipgroup}").first
	      end
	      end
        end
#p Iprange.get_by_ipgroup("69.27.47","2")
@q=Iprange.joins(:ippool).select("ippool.id,ipranges.cblock,ipranges.id AS cid,ippool.ips,ippool.ip_group").order("ips ASC")
@test=Ippool.where("iprange_id='11'")
@ips=[]
@q.each do |x|
#	p x.attributes
end
@save=[]
@max=1
@ips.each do |value|
	@min ||= value
	if value - @min == 1 
		@save << value 
		@min=value
	end
	if value - @min > 1
		@min=value
		@save=[]
		@save << value
	end
	if @save.length==@max then break end
end
