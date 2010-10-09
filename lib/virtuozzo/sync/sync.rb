module Virtuozzo
module Sync
	def self.run(config)
		@serverdata={} 
		@serverips=[]
		@exclude=[]
		@iplist=""
		@skippool=false
		Virtuozzo::Sync::Servers.list(config) do |server,login|
			@serverdata[server]=Virtuozzo::Sync::Establish::go(server,login)
			@iplist << login[0]+"\s"
		end
		@serverdata.each_pair do |server,key|
			if key.empty? 
			@exclude << "#{server}" 
			@skippool=true
			end
			key.each_pair do |eid,values|
				values.each_pair do |veid,ips|
				Synctidy::eids(server,eid,veid,ips)
				@iplist << ips
				end
			end
		end
		Synctidy::delete(@exclude)
		unless @skippool
			Ebhpool::Build::pool(@iplist) do |iplist|
				Ebhpool::Store::run(iplist)
			end
		end
		return 'success'
	end
end
end
