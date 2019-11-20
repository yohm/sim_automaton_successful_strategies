require 'pp'
require 'stringio'

class DirectedGraph

  attr_reader :n, :links

  def initialize(size)
    @n = size
    @links = Hash.new {|hsh,key| hsh[key] = Array.new }
  end

  def add_link( from, to )
    raise "invalid index: #{from}->#{to}" unless from < @n and to < @n
    @links[from].push(to)
  end

  def sccs
    f = ComponentFinder.new(self)
    s = f.strongly_connected_components
    has_self_loops = s.select {|scc| scc.size == 1}.flatten.select do |n|
      @links[n].include?(n)
    end
    s.select {|scc| scc.size > 1} + has_self_loops.map {|n| [n]}
  end

  def transient_nodes
    (0..(@n-1)).to_a - sccs.flatten
  end

  def non_transient_nodes
    sccs.flatten
  end

  def remove_duplicated_links!
    @links.values.each {|ns| ns.uniq! }
  end

  def to_dot(node_attributes: {}, remove_isolated: false, node_ranks: [], edge_labels: {})
    io = StringIO.new
    io.puts "digraph \"\" {"
    @n.times do |ni|
      next if remove_isolated and @links[ni].empty?
      label = node_attributes.dig(ni,:label) || ni.to_s
      fontcolor = node_attributes.dig(ni,:fontcolor) || "black"
      io.puts "  #{ni} [ label=\"#{label}\"; fontcolor = #{fontcolor} ];"
    end
    @n.times do |ni|
      next if remove_isolated and @links[ni].empty?
      @links[ni].each do |nj|
        io.puts "  #{ni} -> #{nj} [label=\"#{edge_labels[[ni,nj]]}\"];"
      end
    end
    if node_ranks.size > 0
      ranks = node_ranks.map.with_index {|_,i| "rank_#{i}"}
      io.puts "  #{ranks.join(' -> ')}"
      node_ranks.each_with_index do |nodes,i|
        io.puts "  {rank=same; #{ranks[i]}; #{nodes.join(';')};}"
      end
    end
    io.puts "}"
    io.flush
    io.string
  end

  def is_accessible?(from, to)
    found = false
    dfs(from) {|n|
      found = true if n == to
    }
    found
  end

  def for_each_link
    @n.times do |ni|
      @links[ni].each do |nj|
        yield ni, nj
      end
    end
  end

  # nodes having a link to n
  def parent_nodes(n)
    ans = []
    for_each_link do |i,j|
      ans << i if j == n
    end
    ans
  end

  def dfs(start, &block)
    stack=[]
    dfs_impl = lambda do |n|
      block.call(n)
      stack.push(n)
      @links[n].each do |nj|
        next if stack.include?(nj)
        dfs_impl.call(nj)
      end
    end
    dfs_impl.call(start)
  end

  def self.common_subgraph(g1,g2)
    g = self.new( g1.n )
    links1 = []
    g1.for_each_link {|ni,nj| links1.push( [ni,nj] ) }
    links2 = []
    g2.for_each_link {|ni,nj| links2.push( [ni,nj] ) }
    common_links = links1 & links2
    common_links.each {|l| g.add_link(*l) }
    g
  end
end

class ComponentFinder

  def initialize( graph )
    @g = graph
    @t = 0

    @desc =  Array.new(@g.n, nil)
    @low  =  Array.new(@g.n, nil)
    @stack = []
    @on_stack  =  Array.new(@g.n, false)
  end

  def strongly_connected_components
    @sccs = []
    @g.n.times do |v|
      if @desc[v].nil?
        strong_connect(v)
      end
    end
    @sccs
  end

  private
  def strong_connect(v)
    @desc[v] = @t
    @low[v] = @t
    @t += 1

    @stack.push(v)
    @on_stack[v] = true

    @g.links[v].each do |w|
      if @desc[w].nil?
        strong_connect(w)
        @low[v] = @low[w] if @low[w] < @low[v]
      elsif @on_stack[w]
        @low[v] = @desc[w] if @desc[w] < @low[v]
      end
    end

    # if v is a root node, pop the stack and generate an scc
    scc = []
    if @low[v] == @desc[v]
      loop do
        w = @stack.pop
        @on_stack[w] = false
        scc.push(w)
        break if v == w
      end
      @sccs.push( scc )
    end
  end
end

