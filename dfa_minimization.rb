require_relative 'n2m2_strategy'
require_relative 'n3m2_strategy'
require_relative 'n3m3_strategy'
require_relative 'graph'

if ARGV.size == 0
  $stderr.puts "usage: ruby #{__FILE__} cccdcccdcccdcccd"
  raise "invalid number of arguments"
end

class UnionFind
  def initialize(n)
    @par  = Array.new(n) {|i| i}
  end

  def root(i)
    if @par[i] != i
      r = root(@par[i])
      @par[i] = r
    end
    @par[i]
  end

  def tree
    h = {}
    @par.size.times.each do |i|
      k = root(i)
      h[k] ||= []
      h[k].push(i)
    end
    h
  end

  def roots
    tree.keys.sort
  end

  def merge(i, j)
    ri = root(i)
    rj = root(j)
    return false if ri == rj  # already merged
    ri,rj = rj,ri if ri > rj
    @par[rj] = ri
  end

  def to_h
    @par.size.times.group_by {|i| root(i) }
  end
end

def mergeable(dest_i, dest_j, h2a, uf)
  # both action & next state must be identical
  di = dest_i.map {|x| [h2a.call(x), uf.root(x)] }.sort
  dj = dest_j.map {|x| [h2a.call(x), uf.root(x)] }.sort
  di == dj
end

def construct_AS_graph(g, h2a)
  uf = UnionFind.new(g.n)  # grouping

  updated = true
  while(updated)
    updated = false
    uf.roots.combination(2).each do |i,j|
      if mergeable(g.links[i], g.links[j], h2a, uf)
        # $stderr.puts "merging #{i} #{j}"
        uf.merge(i, j)
        updated = true
        break
      end
    end
  end

  g2 = DirectedGraph.new(g.n)
  g.for_each_link do |i,j|
    ri = uf.root(i)
    rj = uf.root(j)
    g2.add_link(ri,rj)
  end
  g2.remove_duplicated_links!

  return uf, g2
end


def equivalent(dest_i, dest_j, h2a, uf)
  # both action & next state must be identical
  di = dest_i.map {|x| [h2a.call(x), uf.root(x)] }.sort
  dj = dest_j.map {|x| [h2a.call(x), uf.root(x)] }.sort
  di == dj
end

def minimize_DFA(g, h2a)
  uf_0 = UnionFind.new(g.n)
  # initial grouping by the action c/d
  g.n.times do |i|
    act = h2a.call( g.links[i][0] )[0]
    if act == 'c'
      uf_0.merge(i, 0)
    else
      uf_0.merge(i, g.n-1)
    end
  end

  loop do
    uf_0_h = uf_0.to_h
    uf = UnionFind.new(g.n)
    uf_0_h.each do |r,s|  # refinint a set in uf_0
      s.combination(2).each do |i,j|
        if equivalent(g.links[i], g.links[j], h2a, uf_0)
          uf.merge(i,j)
        end
      end
    end
    break if uf.to_h == uf_0_h
    uf_0 = uf
  end

  g2 = DirectedGraph.new(g.n)
  g.for_each_link do |i,j|
    ri = uf_0.root(i)
    rj = uf_0.root(j)
    g2.add_link(ri,rj)
  end
  g2.remove_duplicated_links!

  return uf_0, g2
end

DEBUG = true

s = ARGV[0]
if s.length == 16
  $stderr.puts "loading n=2,m=2 strategy: #{s}" if DEBUG
  str = N2M2::Strategy.make_from_str(s)
  histo_to_action = lambda {|x| [4,1].map{|m| ((x&m)==m)?'d':'c'}.join }
elsif s.length == 40
  $stderr.puts "loading n=3,m=2 strategy: #{s}" if DEBUG
  str = N3M2::Strategy.make_from_bits(s)
  str.show_actions_using_full_state($stderr) if DEBUG
  histo_to_action = lambda {|x| [16,4,1].map{|m| ((x&m)==m)?'d':'c'}.join }
elsif s.length == 512
  $stderr.puts "loading n=3,m=3 strategy: #{s}" if DEBUG
  str = N3M3::Strategy.make_from_bits(s)
  str.show_actions($stderr) if DEBUG
  histo_to_action = lambda {|x| [64,8,1].map{|m| ((x&m)==m)?'d':'c'}.join }
else
  $stderr.puts "unsupported input format"
  raise "invalid argument"
end

$stderr.puts str.inspect if DEBUG
ata_g = str.transition_graph
# File.open('before.dot', 'w') do |io|
#   io.puts str.transition_graph.to_dot(remove_isolated: true)
# end
uf, as_g = minimize_DFA( ata_g, histo_to_action )
if DEBUG
  $stderr.print "comparing two methods : "
  uf2, as_g2 = construct_AS_graph( ata_g, histo_to_action )
  if uf.to_h == uf2.to_h
    $stderr.puts "OK"
  else
    $stderr.puts "NG"
    $stderr.puts uf.inspect, uf2.inspect
    raise "inconsistency is found"
  end
  exit
end

$stderr.puts uf.tree.inspect if DEBUG
#puts "#{s} #{uf.tree.size} #{s.count('c')}"
#exit
mapped = uf.roots.map do |n|
  [ n, {label: "#{str.action(n)}@#{n}"} ]
end
attr = Hash[mapped]
link_label = Hash.new {|h,k| h[k] = [] }
t = uf.tree
ata_g.for_each_link do |i,j|
  e = [uf.root(i), uf.root(j)]
  link_label[e].push( histo_to_action.call(j) )
end
link_label = link_label.map {|k,v| [k, v.sort.uniq.join(',')] }.to_h
$stderr.puts link_label.inspect if DEBUG

$stdout.puts as_g.to_dot(remove_isolated: true, node_attributes: attr, edge_labels: link_label)

