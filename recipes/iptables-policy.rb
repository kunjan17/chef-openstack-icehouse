include_recipe "simple_iptables::default"

simple_iptables_rule "ssh" do
  rule "--proto tcp --dport 22"
  jump "ACCEPT"
end

simple_iptables_rule "established" do
  rule "-m state --state ESTABLISHED,RELATED"
  jump "ACCEPT"
end

simple_iptables_rule "ping" do
  rule " -p icmp --icmp-type 8"
  jump "ACCEPT"
end

# Reject packets other than those explicitly allowed
simple_iptables_policy "INPUT" do
  policy "DROP"
end
