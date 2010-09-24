class PostSetup
	class << self
		include Virtuozzo
		def run
			@params=Virtuozzo.getparams
			self.send(@params["mode"].to_s)
		end
		def create
			PanelSetup::run
			#renable rev setup
			RevSetup::run(@params["mainip"],@params['domain'])
			self.write 
		end
		def suspend
			
		end
		
		def unsuspend
	
		end
		
		def destroy
			Vdspool.destroy(@params["id"])
		end
		
		def write
			Vdspool.create(:vdsid => "#{@params["node"]}", :veid => "#{@params["VE id"]}", :eid =>"#{@params["eid"]}",:ips => "#{@params["mainip"]}\s#{@params["remainingips"]}")
			Tblhosting.update(@params['accountid'],:dedicatedip => "#{@params["mainip"]}", :assignedips => "#{@params["remainingips"]}")
			#Tblcustomfieldsvalues.update_all("value=#{@params["veid"]}",{:relid=>"#{@params["serviceid"]}",:fieldid => "#{@params["packageid"]}"})
		end
	end
end
