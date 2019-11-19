require 'pp'
require_relative 'graph'

module N3M2

module State

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

class FullState

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

  def state_from( player )
    case player
    when :A
      self.clone
    when :B
      FullState.new(@b_2,@b_1,@c_2,@c_1,@a_2,@a_1)
    when :C
      FullState.new(@c_2,@c_1,@a_2,@a_1,@b_2,@b_1)
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
    @strategy = Hash[ State::ALL_STATES.zip( actions ) ]
  end

  def to_bits
    State::ALL_STATES.map do |stat|
      @strategy[stat] == :c ? 'c' : 'd'
    end.join
  end

  def to_64a
    N.times.map do |i|
      fs = FullState.make_from_id(i)
      act = @strategy[fs.to_ss]
    end
  end

  def show_actions(io)
    State::ALL_STATES.each_with_index do |stat,idx|
      io.print "#{@strategy[stat]}|#{stat.join}\t"
      io.print "\n" if idx % 10 == 9
    end
  end

  def show_actions_using_full_state(io)
    N.times do |i|
      fs = FullState.make_from_id(i)
      act = @strategy[fs.to_ss]
      io.print "#{act}@#{fs}\t"
      io.print "\n" if i % 8 == 7
    end
  end

  def show_actions_latex(io)
    num_col = 4
    num_row = State::ALL_STATES.size / num_col
    num_row.times do |row|
      num_col.times do |col|
        idx = row + col * num_row
        stat = State::ALL_STATES[idx]
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
      fs = FullState.make_from_id(state)
      fs.to_ss
    when FullState
      fs.to_ss
    else
      state
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
    fs_b = FullState.new( fs.b_2, fs.b_1, fs.c_2, fs.c_1, fs.a_2, fs.a_1 )
    fs_c = FullState.new( fs.c_2, fs.c_1, fs.a_2, fs.a_1, fs.b_2, fs.b_1 )
    act_b = b_strategy.action( fs_b.to_ss )
    act_c = c_strategy.action( fs_c.to_ss )
    fs.next_state( act_a, act_b, act_c )
  end

  def transition_graph
    g = DirectedGraph.new(N)
    N.times do |i|
      fs = FullState.make_from_id(i)
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
      fs = FullState.make_from_id(i)
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
      s = FullState.make_from_id(i)
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
end
end

if __FILE__ == $0 and ARGV.size != 1
  require 'minitest/autorun'

  class StateTest < Minitest::Test

    include N3M2

    def test_alld
      fs = FullState.make_from_id(63)
      assert_equal [:d,:d,:d,:d,:d,:d], fs.to_a
      assert_equal [:d,:d,2,2], fs.to_ss
      assert_equal 0, fs.relative_payoff_against(:B)
      assert_equal 0, fs.relative_payoff_against(:C)
    end

    def test_allc
      fs = FullState.make_from_id(0)
      assert_equal [:c,:c,:c,:c,:c,:c], fs.to_a
      assert_equal [:c,:c,0,0], fs.to_ss
      assert_equal 0, fs.relative_payoff_against(:B)
      assert_equal 0, fs.relative_payoff_against(:C)
    end

    def test_state43
      fs = FullState.make_from_id(43)
      assert_equal [:d, :c, :d, :c, :d, :d], fs.to_a
      assert_equal [:d,:c,2,1], fs.to_ss
      assert_equal 0, fs.relative_payoff_against(:B)
      assert_equal -1, fs.relative_payoff_against(:C)
      assert_equal [:c,:c,:c,:d,:d,:d], fs.next_state(:c,:d,:d).to_a
    end

    def test_state44
      fs = FullState.make_from_id(44)
      assert_equal [:d, :c, :d, :d, :c, :c], fs.to_a
      assert_equal [:d,:c,1,-1], fs.to_ss
      assert_equal -1, fs.relative_payoff_against(:B)
      assert_equal 0, fs.relative_payoff_against(:C)
      assert_equal [:c,:d,:d,:d,:c,:d], fs.next_state(:d,:d,:d).to_a
    end

    def test_equality
      fs1 = FullState.make_from_id(15)
      fs2 = FullState.new(:c,:c,:d,:d,:d,:d)
      assert_equal true, fs1 == fs2

    end
  end

  class StrategyTest < Minitest::Test

    include N3M2

    def test_allD
      bits = "d"*40
      strategy = Strategy.make_from_bits(bits)
      assert_equal bits, strategy.to_bits
      assert_equal :d, strategy.action([:c,:c,0,0] )
      assert_equal :d, strategy.action([:d,:d,2,2] )

      s = FullState.new(:c,:c,:d,:c,:c,:d)
      nexts = strategy.possible_next_full_states(s).map(&:to_s)
      expected = ['cdccdc', 'cdccdd', 'cdcddc', 'cdcddd']
      assert_equal expected, nexts

      next_state = strategy.next_full_state_with_self(s)
      assert_equal 'cdcddd', next_state.to_s

      assert_equal true, strategy.defensible?
      assert_equal false, strategy.efficient?
      assert_equal true, strategy.distinguishable?
    end

    def test_allC
      bits = "c"*40
      strategy = Strategy.make_from_bits(bits)
      assert_equal bits, strategy.to_bits
      assert_equal :c, strategy.action([:c,:c,0,0] )
      assert_equal :c, strategy.action([:d,:d,2,2] )

      s = FullState.new(:c,:c,:d,:c,:c,:d)
      nexts = strategy.possible_next_full_states(s).map(&:to_s)
      expected = ['ccccdc', 'ccccdd', 'cccddc', 'cccddd']
      assert_equal expected, nexts

      next_state = strategy.next_full_state_with_self(s)
      assert_equal 'ccccdc', next_state.to_s

      assert_equal false, strategy.defensible?
      assert_equal true, strategy.efficient?
      assert_equal false, strategy.distinguishable?
    end

    def test_a_strategy
      bits = "ccccdddcdddccccddcdddccccddcddcccccddddd"
      strategy = Strategy.make_from_bits(bits)
      assert_equal bits, strategy.to_bits
      assert_equal :c, strategy.action([:c,:c,0,0] )
      assert_equal :d, strategy.action([:d,:d,2,2] )

      s = FullState.new(:c,:c,:d,:c,:c,:d)
      sid = State.index(s.to_ss)
      move_a = strategy.action([:c,:c,1,1])  #=> d
      nexts = strategy.possible_next_full_states(s).map(&:to_s)
      expected = ['cdccdc', 'cdccdd', 'cdcddc', 'cdcddd']
      assert_equal expected, nexts

      next_state = strategy.next_full_state_with_self(s)
      move_b = strategy.action([:d,:c,0,1])
      move_c = strategy.action([:c,:d,1,0])
      assert_equal "c#{move_a}c#{move_b}d#{move_c}", next_state.to_s

      assert_equal false, strategy.defensible?
      assert_equal false, strategy.efficient?
      assert_equal true, strategy.distinguishable?
    end

    def test_AON2
      bits = Array.new(40)
      Strategy::N.times do |i|
        s = FullState.make_from_id(i)
        if s.a_2 == s.b_2 and s.a_2 == s.c_2 and s.a_1 == s.b_1 and s.a_1 == s.c_1
          bits[State.index(s.to_ss)] = 'c'
        else
          bits[State.index(s.to_ss)] = 'd'
        end
      end
      strategy = Strategy.make_from_bits(bits.join)
      assert_equal "cdddddddddddcddddddddddddddcdddddddddddc", strategy.to_bits

      assert_equal :c, strategy.action([:c,:c,0,0] )
      assert_equal :c, strategy.action([:d,:d,2,2] )
      assert_equal :d, strategy.action([:d,:c,2,2] )

      assert_equal false, strategy.defensible?
      assert_equal true, strategy.efficient?
      assert_equal true, strategy.distinguishable?
    end

    def test_most_generous_PS2
      bits = "cddcdddcddcccdcddddddcccdddcccccddcddddd"
      strategy = Strategy.make_from_bits(bits)
      assert_equal bits, strategy.to_bits
      assert_equal :c, strategy.action([:c,:c,0,0] )
      assert_equal :d, strategy.action([:d,:d,2,2] )

      s = FullState.new(:c,:c,:d,:c,:c,:d)
      move_a = strategy.action([:c,:c,1,1]) #=> d
      nexts = strategy.possible_next_full_states(s).map(&:to_s)
      expected = ['cdccdc', 'cdccdd', 'cdcddc', 'cdcddd']
      assert_equal expected, nexts

      next_state = strategy.next_full_state_with_self(s)
      move_b = strategy.action([:d,:c,0,1])
      move_c = strategy.action([:c,:d,1,0])
      assert_equal "c#{move_a}c#{move_b}d#{move_c}", next_state.to_s
      assert_equal true, strategy.defensible?
      assert_equal false, strategy.efficient?
      assert_equal true, strategy.distinguishable?
    end
  end
end

if __FILE__ == $0 and ARGV.size == 1
  bits = ARGV[0]
  stra = N3M2::Strategy.make_from_bits(bits)
  stra.show_actions($stdout)
  stra.show_actions_using_full_state($stdout)
  pp stra.to_64a
  # puts stra.transition_graph.to_dot
  #stra.transition_graph_with_self.to_dot($stdout)
  #stra.show_actions_latex($stdout)
  #a1_b, a1_c = Strategy::AMatrix.construct_a1_matrix(stra)
  #pp a1_b
  #pp a1_b.has_negative_diagonal?
  #a1_b.update(a1_b)
  #pp a1_b
  #pp "def: #{stra.defensible?}"
end

