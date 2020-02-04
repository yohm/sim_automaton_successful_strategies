require_relative 'n2m2_strategy'
require_relative 'n3m2_strategy'
require_relative 'n3m3_strategy'
require_relative 'graph'
require_relative 'union_find'

unless ARGV.size == 1
  $stderr.puts "usage: ruby #{__FILE__} cccdcccdcccdcccd"
  raise "invalid number of arguments"
end

DEBUG = true

s = ARGV[0]
if s.length == 16
  $stderr.puts "loading n=2,m=2 strategy: #{s}" if DEBUG
  str = N2M2::Strategy.make_from_bits(s)
  to_last_actions = lambda {|i| _s = N2M2::State.make_from_id(i); [_s.a_1,_s.b_1].join }
elsif s.length == 40
  $stderr.puts "loading n=3,m=2 strategy: #{s}" if DEBUG
  str = N3M2::Strategy.make_from_bits(s)
  to_last_actions = lambda {|i| _s = N3M2::State.make_from_id(i); [_s.a_1,_s.b_1,_s.c_1].join }
elsif s.length == 512
  $stderr.puts "loading n=3,m=3 strategy: #{s}" if DEBUG
  str = N3M3::Strategy.make_from_bits(s)
  to_last_actions = lambda {|i| _s = N3M3::State.make_from_id(i); [_s.a_1,_s.b_1,_s.c_1].join }
else
  $stderr.puts "unsupported input format"
  raise "invalid argument"
end

noisy = false
uf, min_g = str.minimize_DFA(noisy)

$stderr.puts uf.to_h.inspect if DEBUG
$stderr.puts "size: #{uf.to_h.size}" if DEBUG
node_attr = {}
uf.roots.each do |n|
  node_attr[n] = {label: "#{str.action(n)}@#{n}"}
end
link_label = Hash.new {|h,k| h[k] = [] }
link_style = Hash.new
org_g = noisy ? str.noisy_transition_graph : str.transition_graph
org_g.for_each_link do |i,j|
  e = [uf.root(i), uf.root(j)]
  acts = to_last_actions.call(j)
  link_label[e].push( acts )
  if str.action(i).to_s == acts[0]
    link_style[e] = "solid"
  else
    link_style[e] ||= "dashed"
  end
end

link_attrs = link_label.map {|k,v| [k, {label: v.sort.uniq.join(',')}] }.to_h
link_style.each {|k,v| link_attrs[k][:style] = v }

$stdout.puts min_g.to_dot(remove_isolated: true, node_attributes: node_attr, edge_attributes: link_attrs)

