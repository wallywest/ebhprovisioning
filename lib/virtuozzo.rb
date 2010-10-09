require 'xmlsimple'
require 'active_record'
require 'openssl'
require 'socket'
require 'net/ssh'
require 'net/sftp'
require 'net/ping'
require 'base64'
require 'ipaddress'
require 'eventmachine'
require 'ipaddr'
require 'curb'
require 'xmlrpc/client'
require 'redis'

dir=File.expand_path("virtuozzo")
%w{log packetgenerator connection panel postsetup setup params revsetup licenses}.each do |file|
        require "#{dir}/#{file}"
end
%w{servers emsync synctidy sync}.each do |file|
        require "#{dir}/sync/#{file}"
end
%w{plesk}.each do |file|
	require "#{dir}/panel/#{file}"
end
%w{gimme build store}.each do |file|
	require "#{dir}/ippool/#{file}"
end
#begin

@file=File.join(File.expand_path(".."),'config.xml')
@config=XmlSimple.xml_in(@file)
	ActiveRecord::Base.establish_connection(
                :adapter  => "mysql2",
                :host     => @config['host'][0],
                :username => @config['user'][0],
                :password => @config['pass'][0],
                :database => @config['db'][0],
        	:pool => 10
	)
        class Vdspool < ActiveRecord::Base
                set_table_name 'vdspool'
		validates_uniqueness_of :eid
		  class << self
                        def next_veid
                                select("veid").order("veid DESC").limit(1).where("veid < 22000").first.veid.to_i + 1
                        end
			def get_veid(veid,node)
				select("id,eid").where("veid='#{veid}' and vdsid='#{node}'").first
			end
                end

        end
        class Tblproducts < ActiveRecord::Base
                set_primary_key :id
        end
        class Tblhosting < ActiveRecord::Base
                set_primary_key :id
                set_table_name 'tblhosting'
                has_many :tblclients
 	        def self.updateips(id,mainip,assignedips)
                        @user=where(:id => "#{id}").first
                        @user.dedicatedip=mainip
			@assignedips=assignedips.gsub(/\s/,"\n")
			@user.assignedips=@assignedips
                        @user.save
                end

	end
        class Tblservers < ActiveRecord::Base
                set_primary_key :id
        end
        class Tblclients < ActiveRecord::Base
                belongs_to :tblhosting
                scope :name_clients,
                            :joins => :tblhosting,
                            :conditions => "tblclients.id=tblhosting.userid"
        end
        class Tblcustomfieldsvalues < ActiveRecord::Base
                set_primary_key :relid
        end
        class Tblhostingconfigoptions < ActiveRecord::Base
        end
        class Ippool < ActiveRecord::Base
             set_table_name 'ippool'
             belongs_to :iprange, :class_name => 'Iprange'
        end
        class Iprange < ActiveRecord::Base
              has_many :ippool, :class_name => 'Ippool'
        end

Virtuozzo::Log::create('vzctl.log')
Virtuozzo::Log::write("running module with mode #{ARGV[0]}")
print Virtuozzo::setup(ARGV[0],@config)
#rescue Exception => e
#	Virtuozzo::Log::error("#{e.backtrace}")
#	puts "Error in virtuozzo: #{e}"
#end
