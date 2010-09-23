require 'eventmachine'
require_relative 'init'
require_relative '../packetgenerator'
module Sync
	class Connection < EM::Connection
	attr_accessor :data
	def initialize
		@eid=[]
		@data={}
		@builtqueue=false
	end
	def queue=(value)
            @queue=value
	end
	#def packet=(value)
	#	@packet=value
	#end
	def buildeidqueue
		puts "building eid queue"
		@eid.each_index do |x|
			@packet.info="#{@eid[x]}"
			@queue << @packet.info
			@data[@eid[x]] = {}
		end
		@builtqueue=true
	end
	def sendpacket
			#if !@eid.empty? and !@builtqueue then buildeidqueue end
			#if @builtqueue then @keepeid=@eid.pop end
			"SENDING PACKET"
			send_data @queue.pop
			send_data "\0"
	end
	def interpret(line)
		@line=line.sub(/<\/.*>/,'').sub(/<.*>/,'').chomp
		if line =~/<\/packet>/ 
			if @queue.empty? then close_connection end
			sendpacket 
		end
		#if line =~/<ns2:eid>/ then @eid << @line.chomp end
		#if @builtqueue
		#	if line=~/<ns3:veid/ and line.chomp!="<ns3:veid>0</ns3:veid>" 
		#		@vps=@line.sub(/vps/,'').chomp
		#		@data[@keepeid] = {@vps => []}
		#	end
                 #       if line =~/<ns4:ip_address>/ then @saveip=true end
		#	if line =~/<\/ns4:ip_address>/ then @saveip=false end
		#	if @saveip and line =~ /<ns4:ip>/ then @data[@keepeid][@vps] << @line end
	#	end
	end
	def receive_data data
		@buffer ||= BufferedTokenizer.new
		@buffer.extract(data).each do |line|
		p line 
		interpret(line)
		end
	end
	def unbind
		puts "UNBINDING"
		EM::stop
	end
	end
def self.run(config)
@servers={}
@config=config
p @config
@pass=Digest::MD5.hexdigest("#{@config['whmcspass'][0]}")
@query=Tblservers.find(:all, :conditions => "type='virtuozzo'", :select => "name,password,ipaddress")
@query.each do |x|
   c=Curl::Easy.http_post("http://localhost/whmcs/includes/api.php",Curl::PostField.content('username',"#{@config['whmcsuser'][0]}"),Curl::PostField.content('password',"#{@pass}"),Curl::PostField.content('action','decryptpassword'),Curl::PostField.content('password2',"#{x.password}"))
        if c.response_code==200
                  @servers[x.name]=[x.ipaddress,c.body_str.split(';')[1].gsub(/password=/,"").chomp]
        end
 end
@serverdata={}
@ip=@servers.first[1][0]
@pass=@servers.first[1][1]
@nodepass=Base64.encode64("#{@pass}").chomp
@login=%!
<packet version="4.0.0" id="3"> 
<data>
<system>
<login>
<name>cm9vdA==</name>
<realm>00000000-0000-0000-0000-000000000000</realm>
<password>#{@nodepass}</password>
</login>
</system>
</data>
</packet>
!
@list=%!
<packet version="4.0.0" id="4">
<target>vzaenvm</target>
<data>
<vzaenvm>
<get_list/>
</vzaenvm>
</data>
</packet>
!
@queue=[@list,@login]
		EM.run do
		        @data=EventMachine::connect "#{@ip}",4433, Connection do |conn|
			conn.queue=@queue
			end
		end
   end
end
