module Ebhpool
module Store
	def self.run(pool)
	@redis=Redis.new
	pool.each do |cclass,iparray|
		unless @redis.exists "#{cclass}" then setupcclass(cclass,iparray) end
        	iparray.each do |value|
    	            	@redis.sadd "temp","#{value}"
    	 	end
		puts "DIFF VALUES"
        	puts "------------------"
        	@extractips=@redis.sdiff "#{cclass}", "temp"
        	@giveips=@redis.sdiff "temp", "#{cclass}"
        	p @extractips
        	p @giveips
        	@redis.del "temp"
        	if !@extractips.empty?
        	        p @extractips
        	        @redis.decrby "ipcount","#{@extractips.length}"
			@extractips.each {|x| @redis.srem "#{cclass}","#{x}"}
        	        extractips(cclass)
        	elsif !@giveips.empty?
        	        puts "adding ips back"
			@currentmem=@redis.smembers "#{cclass}"
			@redis.decrby "ipcount","#{@currentmem.length}"
			@giveips.each { |x| @redis.sadd "#{cclass}","#{x}"}
        	        mergeips(cclass)
        	end
	end
	end
	def self.setupcclass(cclass,iparray)
                p "#{cclass} does not exist"
                @redis.sadd "cclasses","#{cclass}"
                p "ip array going in is #{iparray}"
                @g=[]
                @counter=@redis.incr "next.#{cclass}:ip"
                p @counter
                puts "DOES NOT EXIST"
                @redis.incrby "ipcount", "#{iparray.length}"
                iparray.each do |dclass|
                @redis.sadd "#{cclass}", "#{dclass}"
                @g << dclass.to_i
                        unless @g.length==1
                                if dclass.to_i-@g[-2] !=1
                                        @save=@g.pop
                                        p @g
                                        @g.each {|x| @redis.lpush "#{cclass}:ip:#{@counter}", "#{x}"}
                                        @redis.zadd "ippool","#{@g.length}","#{cclass}:ip:#{@counter}"
                                        @redis.sadd "#{cclass}:ids", "#{cclass}:ip:#{@counter}"
                                        p "#{cclass}:ip:#{@counter}"
                                        @counter=@redis.incr "next.#{cclass}:ip"

                                        @g=[]
                                        @g<<@save
                                end
                        end
                end
                @g.each {|x| @redis.lpush "#{cclass}:ip:#{@counter}", "#{x}"}
                @redis.zadd "ippool","#{@g.length}","#{cclass}:ip:#{@counter}"
                @redis.sadd "#{cclass}:ids", "#{cclass}:ip:#{@counter}"

	end
	def self.extractips(cclass)
        	@cclassset=@redis.smembers "#{cclass}:ids"
        	p @cclassset
        	@cclassset.each do |set|
                	if (@redis.lrange "#{set}", "0", "-1").include?("#{@extractips.first}") then @lrange=set end
        	end
        	p @lrange
        	@iparray=@redis.lrange "#{@lrange}", "0","-1"
        	@offset= @extractips.last.to_i-@iparray.last.to_i+1
        	counter=@redis.incr "next.#{cclass}:ip"
        	p counter
        	@offset.times { @redis.rpoplpush "#{@lrange}","#{cclass}:ip:#{counter}"}
        	(@extractips.length).times { @redis.lpop "#{cclass}:ip:#{counter}" }
        	@newlrangelength=@redis.llen "#{cclass}:ip:#{counter}"
        	@lrangelength=@redis.llen "#{@lrange}"
        	@redis.sadd "#{cclass}:ids","#{cclass}:ip:#{counter}"
        	@redis.zadd "ippool", "#{@newlrangelength}","#{cclass}:ip:#{counter}"
       		@redis.zadd "ippool", "#{@lrangelength}","#{@lrange}"
	end
	def self.mergeips(cclass)
        	p cclass
		(@redis.smembers "#{cclass}:ids").each do |x|
                	@redis.zrem "ippool","#{x}"
        	        @redis.del "#{x}"
        	end
		@redis.del "next.#{cclass}:ip"
        	@redis.del "#{cclass}:ids"
        	iparray=@redis.sort "#{cclass}"
		@redis.del "#{cclass}"
		setupcclass(cclass,iparray)
	end
end
end
