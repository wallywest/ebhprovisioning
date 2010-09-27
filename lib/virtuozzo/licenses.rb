module Virtuozzo
class LicenseSetup
include Virtuozzo
	class << self 
		def run
			Virtuozzo::Log::write('setting panel')
			@params=Virtuozzo.getparams
			self.send(@params["panel"].downcase)
			return 'success'
		end
		#CPANEL LICENSE SETUP
		def cpanel
		
		end
		
		def webmin
		    raise "WEBMIN IS FREE FOOL"
		end
	
		def plesk
			Plesk::run(
				:mode => "license",
				:params => @params
			)
			Tblcustomfieldsvalues.update_all("value='#{@params['plesk_key']}'",{:relid=>"#{@params["serviceid"]}",:fieldid => [11,13]})
		end	
	end
end
end
