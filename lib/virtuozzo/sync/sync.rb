module Virtuozzo
module Sync
	def self.run(config)
		@serverdata={} 
		@serverips=[]
		@exclude=[]
		@iplist=""
                @pool=Virtuozzo::IPool::new
		Virtuozzo::Sync::Servers.list(config) do |server,login|
			@serverdata[server]=Virtuozzo::Sync::Establish::go(server,login)
			@serverips << login[0]
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
			@pool.sort(@iplist)
			@pool.buildpool(@serverips)
			@pool.delete
		end
		return 'success'
	end
end
end
