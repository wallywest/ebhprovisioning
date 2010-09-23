#!/usr/local/bin/ruby
require_relative "init"

def login(nodepass)
@login=%!
<packet version="4.0.0" id="3"> 
<data>
<system>
<login>
<name>cm9vdA==</name>
<realm>00000000-0000-0000-0000-000000000000</realm>
<password>#{nodepass}</password>
</login>
</system>
</data>
</packet>
!
end
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
def info(eid)
@info=%!
<packet version="4.0.0" id="2">
<target>vzaenvm</target>
<data>
<vzaenvm>
<get_info>
<eid>#{eid}</eid>
<config/>
</get_info>
</vzaenvm>
</data>
</packet>
!
end
Virtuozzo::Log::create("sync.log")

@pass=Digest::MD5.hexdigest("#{@config['whmcspass'][0]}")
@query=Tblservers.find(:all, :conditions => "type='virtuozzo'", :select => "name,password,ipaddress")
@server={}
@query.each do |x|
	# CHANGE this TO LOCAL PATH
	c=Curl::Easy.http_post("http://localhost/whmcs/includes/api.php",Curl::PostField.content('username',"#{@config['whmcsuser'][0]}"),Curl::PostField.content('password',"#{@pass}"),Curl::PostField.content('action','decryptpassword'),Curl::PostField.content('password2',"#{x.password}"))
	if c.response_code==200
		 @server[x.name]=[x.ipaddress,c.body_str.split(';')[1].gsub(/password=/,"").chomp]
	end	
end
p @server
@ip_pool=[]
@server.each do |value|
	@@node=value[0]
	login(Base64.encode64(value[1][1]))
	#packet=Virtuozzo::PacketGenerator.new(Base64::encode64(value[1][1]).chomp)
	$streamSock = TCPSocket.new(value[1][0], 4433)
	
	$streamSock.write(@login)
        $streamSock.write("\0")

        $streamSock.write(@list)
        $streamSock.write("\0")

	@tosync={}
	while str=$streamSock.gets
		if str=~/<ns2:eid>/
                @eid=str.sub(/<\/.*>/,'').sub(/<.*>/,'').chomp
                #CHECKS TO SEE IF EID EXISTS IN DATABASE
		there=Sync::eids(@@node,@eid)
		if there=="save" then @tosync[@eid]="" end
                end
                if str=~/<\/ns2:vzaenvm>/ then flag=1 end
                if str=~/<\/packet>/ and flag==1
                        break
                end
		if str=~/<ns1:message>/
			Virtuozzo::Log::error(str)
			break
		end
        end
	p @tosync
	@tosync.each do |eid|
			info(eid[0])
			$streamSock.write(@info)
                        $streamSock.write("\0")
                while str=$streamSock.gets
			if str=~/<ns4:ip>/ 
				@ip=str.sub(/<\/.*>/,'').sub(/<.*>/,'').chomp
				@ip_pool << @ip
			end
			if str=~/<ns3:veid/ and str.chomp!="<ns3:veid>0</ns3:veid>"
			@vpsname=str.sub(/<\/.*>/,'').sub(/<.*>/,'').sub(/vps/,'').chomp
				if @vpsname.chomp=='1' || @vpsname=='101' || @vpsname.to_i > 30000
                                @tosync.delete(eid[0])
                                else
                                @tosync[eid[0]]=[@vpsname]
                                end
                        break
                        end
                end
        end
        if @tosync.empty?
                #Virtuozzo::Log::write("#{@@node} has no more changes")
        	
	else
                #Virtuozzo::Log::write("#{@@node} will be updated")
		#Sync::update(@@node,@tosync)
        end
        $streamSock.close
end
Sync::delete
p @ip_pool
