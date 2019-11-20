require 'pp'
require_relative 'graph'
require_relative 'union_find'

module N3M2

module ShortState

  A_STATES = [
      [:c,:c],
      [:c,:d],
      [:d,:c],
      [:d,:d]
  ]

  BC_STATES = [
      [0,0],
      [0,1],
      [0,2],
      [1,0],
      [1,1],
      [1,-1],
      [1,2],
      [2,0],
      [2,1],
      [2,2]
  ]

  ALL_STATES = A_STATES.product(BC_STATES).map {|a,bc| (a+bc).freeze }.freeze

  def self.valid?(state)
    ALL_STATES.include?( state )
  end

  def self.index( state )
    ALL_STATES.index( state )
  end
end

class State

  def self.make_from_id( id )
    raise "invalid arg: #{id}" if id < 0 or id > 63
    c_1 = ( ((id >> 0) & 1) == 1 ) ? :d : :c
    c_2 = ( ((id >> 1) & 1) == 1 ) ? :d : :c
    b_1 = ( ((id >> 2) & 1) == 1 ) ? :d : :c
    b_2 = ( ((id >> 3) & 1) == 1 ) ? :d : :c
    a_1 = ( ((id >> 4) & 1) == 1 ) ? :d : :c
    a_2 = ( ((id >> 5) & 1) == 1 ) ? :d : :c
    self.new(a_2, a_1, b_2, b_1, c_2, c_1)
  end

  def self.make_from_bits( s )
    raise "invalid arg: #{s}" unless s =~ /[cd]{6}/
    self.new( *s.each_char.map(&:to_sym) )
  end

  attr_reader :a_2,:a_1,:b_2,:b_1,:c_2,:c_1

  def initialize(a_2,a_1,b_2,b_1,c_2,c_1)
    @a_2 = a_2
    @a_1 = a_1
    @b_2 = b_2
    @b_1 = b_1
    @c_2 = c_2
    @c_1 = c_1
    unless [@a_2,@a_1,@b_2,@b_1,@c_2,@c_1].all? {|a| a == :d or a == :c }
      raise "invalid state"
    end
  end

  def to_a
    [@a_2,@a_1,@b_2,@b_1,@c_2,@c_1]
  end

  def to_s
    to_a.join('')
  end

  def ==(other)
    self.to_id == other.to_id
  end

  def to_id
    id = 0
    id += 32 if @a_2 == :d
    id += 16 if @a_1 == :d
    id += 8  if @b_2 == :d
    id += 4  if @b_1 == :d
    id += 2  if @c_2 == :d
    id += 1  if @c_1 == :d
    id
  end
  alias :to_i :to_id

  def state_from( player )
    case player
    when :A
      self.clone
    when :B
      State.new(@b_2,@b_1,@c_2,@c_1,@a_2,@a_1)
    when :C
      State.new(@c_2,@c_1,@a_2,@a_1,@b_2,@b_1)
    else
      raise "must not happen"
    end
  end

  def to_ss
    ss = []
    ss[0] = @a_2
    ss[1] = @a_1

    if @b_2 == :d and @c_2 == :d
      bc_2 = 2
    elsif @b_2 == :d or @c_2 == :d
      bc_2 = 1
    else
      bc_2 = 0
    end

    if @b_1 == :d and @c_1 == :d
      bc_1 = 2
    elsif @b_1 == :d or @c_1 == :d
      if bc_2 == 1 and @b_2 == @b_1
        bc_1 = -1
      else
        bc_1 = 1
      end
    else
      bc_1 = 0
    end
    ss[2] = bc_2
    ss[3] = bc_1
    ss
  end

  def next_state(act_a,act_b,act_c)
    self.class.new(@a_1,act_a,@b_1,act_b,@c_1,act_c)
  end

  def relative_payoff_against(other)
    if other == :B
      act = @b_1
    elsif other == :C
      act = @c_1
    else
      raise "must not happen"
    end

    if @a_1 == act
      return 0
    elsif @a_1 == :c and act == :d
      return -1
    elsif @a_1 == :d and act == :c
      return 1
    else
      raise "must not happen"
    end
  end

end

class Strategy

  N = 64

  def initialize( actions )
    @strategy = Hash[ ShortState::ALL_STATES.zip( actions ) ]
  end

  def to_bits
    ShortState::ALL_STATES.map do |stat|
      @strategy[stat] == :c ? 'c' : 'd'
    end.join
  end

  def to_64a
    N.times.map do |i|
      fs = State.make_from_id(i)
      act = @strategy[fs.to_ss]
    end
  end

  def show_actions(io)
    ShortState::ALL_STATES.each_with_index do |stat,idx|
      io.print "#{@strategy[stat]}|#{stat.join}\t"
      io.print "\n" if idx % 10 == 9
    end
  end

  def show_actions_using_full_state(io)
    N.times do |i|
      fs = State.make_from_id(i)
      act = @strategy[fs.to_ss]
      io.print "#{act}@#{fs}\t"
      io.print "\n" if i % 8 == 7
    end
  end

  def show_actions_latex(io)
    num_col = 4
    num_row = ShortState::ALL_STATES.size / num_col
    num_row.times do |row|
      num_col.times do |col|
        idx = row + col * num_row
        stat = ShortState::ALL_STATES[idx]
        s = stat.map do |c|
          if c == -1
            '\bar{1}'
          elsif c.is_a?(Integer)
            c.to_s
          else
            c.capitalize
          end
        end
        s.insert(2,',')
        io.print "$(#{s.join})$ & $#{@strategy[stat].capitalize}$ "
        io.print "& " unless col == num_col - 1
      end
      io.puts "\\\\"
    end
  end

  def self.make_from_bits( bits )
    actions = bits.each_char.map do |chr|
      chr.to_sym
    end
    self.new( actions )
  end

  def action( state )
    s = case state
    when Integer
      fs = State.make_from_id(state)
      fs.to_ss
    when Array    # such as [:c,:c,0,2]
      raise "invalid input" unless state.size == 4
      state
    when State
      fs.to_ss
    when String
      ShortState.make_from_bits(state).to_ss
    else
      raise "invalid input"
    end
    @strategy[s]
  end

  def valid?
    @strategy.values.all? {|a| a == :c or a == :d }
  end

  def possible_next_full_states(current_fs)
    ss = current_fs.to_ss
    act_a = action(ss)
    n1 = current_fs.next_state(act_a,:c,:c)
    n2 = current_fs.next_state(act_a,:c,:d)
    n3 = current_fs.next_state(act_a,:d,:c)
    n4 = current_fs.next_state(act_a,:d,:d)
    [n1,n2,n3,n4]
  end

  def next_full_state_with_self(current_fs)
    next_full_state_with(current_fs, self, self)
  end

  def next_full_state_with( fs, b_strategy, c_strategy )
    act_a = action( fs.to_ss )
    fs_b = State.new( fs.b_2, fs.b_1, fs.c_2, fs.c_1, fs.a_2, fs.a_1 )
    fs_c = State.new( fs.c_2, fs.c_1, fs.a_2, fs.a_1, fs.b_2, fs.b_1 )
    act_b = b_strategy.action( fs_b.to_ss )
    act_c = c_strategy.action( fs_c.to_ss )
    fs.next_state( act_a, act_b, act_c )
  end

  def transition_graph
    g = DirectedGraph.new(N)
    N.times do |i|
      fs = State.make_from_id(i)
      next_fss = possible_next_full_states(fs)
      next_fss.each do |next_fs|
        g.add_link(i,next_fs.to_id)
      end
    end
    g
  end

  def transition_graph_with_self
    transition_graph_with(self, self)
  end

  def transition_graph_with(b_strategy, c_strategy)
    g = DirectedGraph.new(N)
    N.times do |i|
      fs = State.make_from_id(i)
      j = next_full_state_with(fs, b_strategy, c_strategy).to_id
      g.add_link( i, j )
    end
    g
  end

  def defensible?
    defensible_against(:B) and defensible_against(:C)
  end

  def defensible_against(coplayer=:B)
    d = Array.new(N) { Array.new(N, Float::INFINITY) }
    N.times do |i|
      s = State.make_from_id(i)
      ns = possible_next_full_states(s)
      ns.each do |n|
        j = n.to_id
        d[i][j] = s.relative_payoff_against(coplayer)
      end
    end
    N.times do |k|
      N.times do |i|
        N.times do |j|
          if d[i][j] > d[i][k] + d[k][j]
            d[i][j] = d[i][k] + d[k][j]
          end
        end
        return false if d[i][i] < 0
      end
    end
    true
  end

  def efficient?
    g0 = transition_graph_with_self

    judged = Array.new(N, false)
    judged[0] = true

    g = g0

    while true
      # l -> 0
      judged.each_with_index do |b,l|
        next if b
        judged[l] = true if g.is_accessible?(l, 0)
      end
      return true if judged.all?

      # update gn
      update_gn(g)

      # 0 -> l
      judged.each_with_index do |b,l|
        next if b
        return false if g.is_accessible?(0, l)
      end
    end
  end

  def distinguishable?
    allc = Strategy.make_from_bits('c'*40)
    g = transition_graph_with(allc, allc)

    judged = Array.new(N, false)
    judged[0] = true

    while true
      # l -> 0
      judged.each_with_index do |b,l|
        next if b
        judged[l] = true if g.is_accessible?(l, 0)
      end
      return false if judged.all?

      # update gn
      update_gn(g)

      # 0 -> l
      judged.each_with_index do |b,l|
        next if b
        return true if g.is_accessible?(0, l)
      end
    end
  end

  def update_gn(gn)
    noised_states = lambda {|s| [s^1, s^4, s^16] }

    # find sink sccs
    sink_sccs = gn.sccs.select do |c|
      c.all? do |n|
        gn.links[n].all? do |d|
          c.include?(d)
        end
      end
    end

    sink_sccs.each do |sink|
      sink.each do |from|
        noised_states.call(from).each do |to|
          unless gn.links[from].include?(to)
            gn.add_link(from, to)
          end
        end
      end
    end
    gn
  end

  def minimize_DFA
    uf_0 = UnionFind.new(N)
    # initial grouping by the action c/d
    c_rep = N.times.find {|i| action(i) == :c}
    d_rep = N.times.find {|i| action(i) == :d}
    N.times do |i|
      t = (action(i)==:c ? c_rep : d_rep)
      uf_0.merge(i, t)
    end

    loop do
      uf_0_h = uf_0.to_h
      uf = UnionFind.new(N)
      uf_0_h.each do |r,s|  # refinint a set in uf_0
        s.combination(2).each do |i,j|
          if _equivalent(i, j, uf_0)
            uf.merge(i,j)
          end
        end
      end
      break if uf.to_h == uf_0_h
      uf_0 = uf
    end

    g = DirectedGraph.new(N)
    transition_graph.for_each_link do |i,j|
      ri = uf_0.root(i)
      rj = uf_0.root(j)
      g.add_link(ri,rj)
    end
    g.remove_duplicated_links!

    return uf_0, g
  end

  def _equivalent(i, j, uf)
    # both action & next state must be identical
    raise unless action(i) == action(j)
    act_a = action(i)
    acts_other = [[:c,:c],[:c,:d],[:d,:c],[:d,:d]]
    acts_other.all? do |act_b,act_c|
      ni = State.make_from_id(i).next_state(act_a, act_b, act_c).to_id
      nj = State.make_from_id(j).next_state(act_a, act_b, act_c).to_id
      uf.root(ni) == uf.root(nj)
    end
  end
end
end

if __FILE__ == $0
  ARGV.each do |arg|
    stra = N3M2::Strategy.make_from_bits(arg)
    stra.show_actions($stdout)
    stra.show_actions_using_full_state($stdout)
    pp stra.to_64a
  end
end

