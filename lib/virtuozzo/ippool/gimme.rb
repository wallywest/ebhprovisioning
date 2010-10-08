module Ebhpool
def self.bestcase
     @listids=@redis.zrange "ippool","0","-1"
     @cclass=@listids.last.sub(/:.*/,'')
     if (@redis.smembers "#{@cclass}").length >= @iprequestnum.to_i 
		puts "USING ONE SINGLE CCLASS"
		@listids.map {|x| if !x.match(/#{@cclass}/) then @listids.delete("#{x}") end}
     end
     ipchoice do |ips|
	yield ips
     end
end
def self.ipchoice
	    	puts "taking from largest consecutive set"
                puts "using #{@largestid}"
                idlist=[]
		left=@ipcount
		ip={}
                @listids.reverse.each do |id|
			p id
			cclass=id.sub(/:.*/,'')
			ip["#{cclass}"] ||= []
			idlist << "#{id}"
			maxidips=@redis.llen "#{id}"
			if maxidips < @ipcount then left=maxidips end
			left.times do
                        	iptoadd=@redis.rpop "#{id}"
				p iptoadd
                        	ip["#{cclass}"] << iptoadd
                        	@redis.srem "#{cclass}", "#{iptoadd}"
				@ipcount-=1
                	end
                	@redis.zadd "ippool", "#{maxidips-left}", "#{id}"
			if (@redis.zscore "ippool","#{id}").to_i==0
        	            puts "deleting id #{id}"
			    @redis.zrem "ippool","#{id}"
			    @redis.del "#{id}"
	                    @redis.srem "#{cclass}:ids", "#{id}"
                	end
			if @ipcount==0 then break end
                end
		yield ip
end
def self.gimme(iprequestnum)
	@redis=Redis.new
	@ipcount=iprequestnum
	@ip={}
	if @ipcount > (@redis.get "ipcount").to_i then raise "not enough ips for request" end
	bestcase do |ips| 
		p ips
	end
	@redis.decrby "ipcount","#{iprequestnum}"	
end	
end
