require_relative 'init'
require_relative 'iplib'
@avail={}
@iplist=Iprange.joins(:ippool).select("DISTINCT(ipranges.cblock),ippool.ip_group")
@iplist.each do |x|
	p x.attributes
	@avail[x.cblock] ||= []
	@avail[x.cblock] << x.ip_group.to_i
	@avail[x.cblock].sort!
end
p @avail
@total=0
1.upto(3) do |x|
	count=Ippool.where("ip_group=#{x}").count * x
	@total=count+@total
end
#p @totalips
#p Iprange.joins(:ippool).where("ipranges.cblock='69.27.47'").select("ipranges.cblock,ippool.ip_group").first.attributes
#p Iprange.joins(:ippool).where("ipranges.cblock='69.27.47' AND ippool.ip_group='3'").select("ippool.ips").first.attributes
#@q=Iprange.joins(:ippool).where("ipranges.cblock='69.27.47' AND ippool.ip_group='3'").select("ippool.id,ipranges.id AS cid,ippool.ips").first
#@ips=@q.ips.split(" ")
#p @q.attributes
#Virtuozzo::IP::Generator::buildips(3)
#Virtuozzo::IP::Generator::buildips(2)
#Virtuozzo::IP::Generator::buildips(1)
#Virtuozzo::IP::Generator::buildips(5)
#Virtuozzo::IP::Generator::buildips(4)
p Virtuozzo::IP::Generator::buildips(3)
#@p=Virtuozzo::IP::Generator::resultparser
