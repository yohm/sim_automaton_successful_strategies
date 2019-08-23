require_relative 'n2m2_strategy'
require_relative 'n3m2_strategy'
require_relative 'n3m3_strategy'
require_relative 'graph'

if ARGV.size == 0
  $stderr.puts "usage: ruby #{__FILE__} cccdcccdcccdcccd"
  raise "invalid number of arguments"
end

def mergeable(g, i, j)
  di = g.links[i].map {|x| x == j ? i : x }.sort
  dj = g.links[j].map {|x| x == j ? i : x }.sort
  di == dj
end

def merge(g, actions)
  merged = {}  # merged nodes  {0=>[], 1=>[2,3,4], 5=>[7], 6=>[]}
  g.n.times {|i| merged[i] = [] }

  updated = true
  while(updated)
    updated = false
    merged.keys.sort.combination(2).each do |i,j|
      if actions[i] == actions[j] and mergeable(g,i,j)
        # $stderr.puts "merging #{i} #{j}"
        # j is merged into i
        merged[i] += merged[j] + [j]
        merged.delete(j)
        # links going to j are rewired to i
        g.parent_nodes(j).each do |k|
          g.links[k].map! {|x| x == j ? i : x }
        end
        g.links[j] = []  # links from j are removed
        g.remove_duplicated_links!
        # pp g
        updated = true
        break
      end
    end
  end
  return merged, g
end

ARGV.each do |s|
  if s.length == 16
    $stderr.puts "loading n=2,m=2 strategy: #{s}"
    str = N2M2::Strategy.make_from_str(s)
    actions = str.to_a
  elsif s.length == 40
    $stderr.puts "loading n=3,m=2 strategy: #{s}"
    str = N3M2::Strategy.make_from_bits(s)
    actions = str.to_64a
    str.show_actions_using_full_state($stderr)
  elsif s.length == 512
    $stderr.puts "loading n=3,m=3 strategy: #{s}"
    str = N3M3::Strategy.make_from_bits(s)
    actions = str.to_a
    str.show_actions($stderr)
  else
    $stderr.puts "unsupported input format"
    raise "invalid argument"
  end

  $stderr.puts str.inspect
  # File.open('before.dot', 'w') do |io|
  #   io.puts str.transition_graph.to_dot(remove_isolated: true)
  # end
  merge_idx, g = merge( str.transition_graph, actions )
  $stderr.puts merge_idx.inspect
  mapped = merge_idx.map do |n,sub|
    [ n, {label: "#{actions[n]}@#{([n]+sub).sort.join(',')}"} ]
  end
  attr = Hash[mapped]
  $stdout.puts g.to_dot(remove_isolated: true, node_attributes: attr)
end

