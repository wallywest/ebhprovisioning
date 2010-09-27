require_relative "plesk"
@params={"accountid"=>"2", "serviceid"=>"2", "domain"=>"server.digthis.com", "username"=>"serverdi", "password"=>"dlcHXIvUNR", "packageid"=>"1", "pid"=>"1", "serverid"=>"39", "server"=>true, "serverip"=>"69.27.47.13", "serverusername"=>"root", "serverpassword"=>"zmqfgcfvdcg31aac", "mode"=>"create", "panel"=>"PLESK", "Double my RAM!"=>"0", "Choose control panel"=>"Parallels Plesk 10 domains", "Fantastico (TM)"=>"0", "Extra IP (in addition to included ones)"=>"0", "userid"=>"1", "id"=>"1", "firstname"=>"justin", "lastname"=>"e", "companyname"=>"eboundhost", "email"=>"justin@eboundhost.com", "address1"=>"ebound 123", "city"=>"gotham city", "state"=>"IL", "postcode"=>"60004", "country"=>"US", "countryname"=>"United States", "phonenumber"=>"317-802-1585", "node"=>"vds110", "package"=>"BIZ", "mainip"=>"216.14.120.253", "remainingips"=>"216.14.120.254", "VE id"=>"20179", "sampleid"=>"28e5a603-a595-df47-a134-e3f866f62bb4", "memup"=>"536870912"}
begin
Plesk::run(
   :mode => "setup",
   :params => @params
)
rescue Exception => e
	p e.backtrace
	p e
end
