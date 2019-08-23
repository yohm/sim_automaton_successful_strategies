require_relative 'strategy'
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
        $stderr.puts "merging #{i} #{j}"
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
  str = Strategy.make_from_str(s)
  $stderr.puts str.inspect
  File.open('before.dot', 'w') do |io|
    io.puts str.transition_graph.to_dot(remove_isolated: true)
  end
  merge_idx, g = merge( str.transition_graph, str.to_a )
  $stderr.puts merge_idx.inspect
  File.open('after.dot', 'w') do |io|
    io.puts g.to_dot(remove_isolated: true)
  end
end

