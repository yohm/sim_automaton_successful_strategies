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

  def initialize( actions )
    @strategy = Hash[ State::ALL_STATES.zip( actions ) ]
  end

  def to_bits
    State::ALL_STATES.map do |stat|
      @strategy[stat] == :c ? 'c' : 'd'
    end.join
  end

  def to_64a
    64.times.map do |i|
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
    64.times do |i|
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
    @strategy[state]
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

  def next_full_state_with_self(fs)
    act_a = action( fs.to_ss )
    fs_b = FullState.new( fs.b_2, fs.b_1, fs.c_2, fs.c_1, fs.a_2, fs.a_1 )
    act_b = action( fs_b.to_ss )
    fs_c = FullState.new( fs.c_2, fs.c_1, fs.b_2, fs.b_1, fs.a_2, fs.a_1 )
    act_c = action( fs_c.to_ss )
    next_fs = fs.next_state( act_a, act_b, act_c )
    next_fs
  end

  def transition_graph
    g = DirectedGraph.new(64)
    64.times do |i|
      fs = FullState.make_from_id(i)
      next_fss = possible_next_full_states(fs)
      next_fss.each do |next_fs|
        g.add_link(i,next_fs.to_id)
      end
    end
    g
  end

  def transition_graph_with_self
    g = DirectedGraph.new(64)
    64.times do |i|
      fs = FullState.make_from_id(i)
      next_fs = next_full_state_with_self(fs)
      g.add_link( i, next_fs.to_id )
    end
    g
  end

  def self.node_attributes
    node_attributes = {}
    64.times do |i|
      fs = FullState.make_from_id(i)
      node_attributes[i] = {}
      node_attributes[i][:label] = "#{i}_#{fs.to_s}"
    end
    node_attributes
  end

  def defensible?
    a1_b, a1_c = AMatrix.construct_a1_matrix(self) # construct_a1_matrix
    a_b, a_c = AMatrix.construct_a1_matrix(self)
    return false if( a_b.has_negative_diagonal? or a_c.has_negative_diagonal? )

    63.times do |t|
      a_b.update( a1_b )
      a_c.update( a1_c )
      return false if( a_b.has_negative_diagonal? or a_c.has_negative_diagonal? )
    end
    true
  end

  class AMatrix  # class used for judging defensibility

    N=64

    def self.construct_a1_matrix(stra)
      a_b = self.new
      a_c = self.new

      N.times do |i|
        fs = FullState.make_from_id(i)
        N.times do |j|
          a_b.a[i][j] = :inf
          a_c.a[i][j] = :inf
        end
        next_fss = stra.possible_next_full_states(fs)
        next_fss.each do |ns|
          j = ns.to_id
          a_b.a[i][j] = ns.relative_payoff_against(:B)
          a_c.a[i][j] = ns.relative_payoff_against(:C)
        end
      end
      [a_b, a_c]
    end

    attr_reader :a

    def initialize
      @a = Array.new(64) {|i| Array.new(64,0) }
    end

    def inspect
      sio = StringIO.new
      @a.size.times do |i|
        @a[i].size.times do |j|
          if @a[i][j] == :inf
            sio.print(" ##,")
          else
            sio.printf("%3d,", @a[i][j])
          end
        end
        sio.print "\n"
      end
      sio.string
    end

    def has_negative_diagonal?
      @a.size.times do |i|
        if @a[i][i] != :inf and @a[i][i] < 0
          return true
        end
      end
      false
    end

    def update( a1 )
      temp = Array.new(64) {|i| Array.new(64,:inf) }

      @a.size.times do |i|
        @a.size.times do |j|
          @a.size.times do |k|
            x = @a[i][k]
            y = a1.a[k][j]
            next if x == :inf or y == :inf
            temp[i][j] = x+y if temp[i][j] == :inf or x+y < temp[i][j]
          end
        end
      end
      @a = temp
    end
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

