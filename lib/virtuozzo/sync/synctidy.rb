class Synctidy
	class<<self 
	def eids(node,eid,veid,ips)
		@@tnode,@@teid,@@veid,@@ips=node,eid,veid,ips
                if Vdspool.exists?(:eid => "#{@@teid}")
			#@@query=Vdspool.first(:select => "id,veid,vdsid,exist", :conditions => "eid = '#{@@teid}'")
			@@query=Vdspool.where("eid='#{@@teid}'").select("id,veid,vdsid,exist").first
			Vdspool.update("#{@@query.id}",:exist =>'1')
			 ##UPDATE DB if VEID IS MIGRATED
                	if @@query.vdsid != @@tnode 
				Vdspool.update("#{@@query.id}",:vdsid => "#{@@tnode}")
                      		Virtuozzo::Log::write("veid #{@@query[:veid]} is on node #{@@tnode}, changed")
                	end
                	
			#UPDATE WHMCS SETTINGS TO SET SERVER SCROLLDOWN IF UNSET OR WRONG
                	@currentnode=Tblhosting.first(:select => "id,server",:from =>"tblhosting,tblcustomfieldsvalues",:conditions => "tblhosting.id=tblcustomfieldsvalues.relid AND tblcustomfieldsvalues.value='#{@@query.veid}'")
               		@referencenode=Tblservers.first(:select => "id",:conditions =>"name='#{@@tnode}'")

                	if !@currentnode.nil? and !@referencenode.nil?
                        	        if @currentnode.server !=@referencenode.id
                                		Virtuozzo::Log::write("UPDATING WHMCS SERVER VALUE #{@@teid} to server id #{@referencenode.id}")
                               			Tblhosting.update("#{@currentnode.id}" ,:server => "#{@referencenode.id}")
                			end
			end
		else
			Vdspool.create(:eid => "#{@@teid}", :veid => "#{@@veid}", :vdsid => "#{@@tnode}", :ips => "#{@@ips}",:exist => "1")
		end
	end
	def delete(exclude)
		unless exclude.empty?
			exclude.each {|x| Vdspool.where(:vdsid => "#{x}").update_all(:exist => "1")}
		end
		Vdspool.where(:exist => "0").delete_all
        	Vdspool.update_all(:exist => "0")	
	end
	end
end
