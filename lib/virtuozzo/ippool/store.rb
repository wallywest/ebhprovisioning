module Ebhpool
module Store
	def self.run(pool)
	@redis=Redis.new
	pool.each do |cclass,iparray|
		unless @redis.exists "#{cclass}" then setupcclass(cclass,iparray) end
        	iparray.each do |value|
    	            	@redis.sadd "temp","#{value}"
    	 	end
        	@extractips=@redis.sdiff "#{cclass}", "temp"
        	@giveips=@redis.sdiff "temp", "#{cclass}"
        	@redis.del "temp"
        	if !@extractips.empty?
        	        @redis.decrby "ipcount","#{@extractips.length}"
			@extractips.each {|x| @redis.srem "#{cclass}","#{x}"}
        	        extractips(cclass)
        	elsif !@giveips.empty?
			@currentmem=@redis.smembers "#{cclass}"
			@redis.decrby "ipcount","#{@currentmem.length}"
			@giveips.each { |x| @redis.sadd "#{cclass}","#{x}"}
        	        mergeips(cclass)
        	end
	end
	end
	def self.setupcclass(cclass,iparray)
                @redis.sadd "cclasses","#{cclass}"
                @g=[]
                @counter=@redis.incr "next.#{cclass}:ip"
                @redis.incrby "ipcount", "#{iparray.length}"
                iparray.each do |dclass|
                @redis.sadd "#{cclass}", "#{dclass}"
                @g << dclass.to_i
                        unless @g.length==1
                                if dclass.to_i-@g[-2] !=1
                                        @save=@g.pop
                                        @g.each {|x| @redis.lpush "#{cclass}:ip:#{@counter}", "#{x}"}
                                        @redis.zadd "ippool","#{@g.length}","#{cclass}:ip:#{@counter}"
                                        @redis.sadd "#{cclass}:ids", "#{cclass}:ip:#{@counter}"
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
        	@cclassset.each do |set|
                	if (@redis.lrange "#{set}", "0", "-1").include?("#{@extractips.first}") then @lrange=set end
        	end
        	@iparray=@redis.lrange "#{@lrange}", "0","-1"
        	@offset= @extractips.last.to_i-@iparray.last.to_i+1
        	counter=@redis.incr "next.#{cclass}:ip"
        	@offset.times { @redis.rpoplpush "#{@lrange}","#{cclass}:ip:#{counter}"}
        	(@extractips.length).times { @redis.lpop "#{cclass}:ip:#{counter}" }
        	@newlrangelength=@redis.llen "#{cclass}:ip:#{counter}"
        	@lrangelength=@redis.llen "#{@lrange}"
        	@redis.sadd "#{cclass}:ids","#{cclass}:ip:#{counter}"
        	@redis.zadd "ippool", "#{@newlrangelength}","#{cclass}:ip:#{counter}"
       		@redis.zadd "ippool", "#{@lrangelength}","#{@lrange}"
	end
	def self.mergeips(cclass)
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
