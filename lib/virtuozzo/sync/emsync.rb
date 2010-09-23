module Virtuozzo
module Sync
module Establish

class Connection < EM::Connection
	attr_accessor :data
	def initialize
		@eid=[]
		@data={}
		@handlers={}
		@builtqueue=false
	
		handler(/<\/packet>/) { if @queue.empty? and @builtqueue then close_connection else sendpacket end }
		handler(/<ns2:eid>/) { @eid << @line.chomp;}
                handler (/<ns3:veid/) do |msg,builtqueue|
			if builtqueue
                        	@vps=@line.chomp
				if @vps < '10' 
					@data.delete(@keepeid)
					@skip=true 
				else
					@skip=false
					@data[@keepeid] = {@vps => ""} 
				end
			end
                end
                handler (/<ns4:ip_address>/) { |msg,builtqueue| if builtqueue then @saveip=true end}
                handler (/<\/ns4:ip_address>/) { |msg,builtqueue| if builtqueue then @saveip=false end}
		handler (/<ns4:ip>/) do |msg,builtqueue,skip| 
				if @saveip and !skip then @data[@keepeid][@vps] << "#{@line}\s" end
		end
		handler (/<ns1:message/) do |msg|
			Virtuozzo::Log::write("error on sync: #{@line}")
			close_connection		
		end
	end
	def handler(pattern,&block)
		@handlers[pattern]=block
	end
	def packet=(value)
		@packet=value
		@queue=[@packet.list,@packet.login]
	end
	def buildeidqueue
		@eid.each_index do |x|
			@packet.info="#{@eid[x]}"
			@queue << @packet.info
			@data[@eid[x]] = {}
		end
		@builtqueue=true
	end
	def sendpacket
		if !@eid.empty? and !@builtqueue then buildeidqueue end
		if @builtqueue then @keepeid=@eid.pop end
		send_data @queue.pop
		send_data "\0"
	end
	def receive_data data
		@buffer ||= BufferedTokenizer.new
		@buffer.extract(data).each do |line|
			@line=line.sub(/<\/.*>/,'').sub(/<.*>/,'').chomp
			@handlers.each do |pattern,block|
				msg=line.match(pattern)
                        	if !msg.nil?
                                	block.call(msg,@builtqueue,@skip)
                        	end
                	end
		end
	end
	def unbind
	#	puts "UNBINDING"
		EM::stop
	end
end
def self.go(node,value)
	#@packet=Virtuozzo::PacketGenerator::new("sync","#{value[1]}")
        @packet=Virtuozzo::PacketGenerator::new("#{value[1]}")
	EM.run do
                @data=EventMachine::connect "#{value[0]}",4433, Connection do |conn|
			conn.packet=@packet
		end
        end
        #puts "EXITING EM LOOP"
	@data.data
end
end
end
end
