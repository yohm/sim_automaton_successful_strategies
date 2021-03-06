require 'pp'
require_relative 'n3m2_strategy'

module N3M3

class State

  NUM_STATES = 512

  def self.make_from_id( id )
    raise "invalid arg: #{id}" if id < 0 or id >= NUM_STATES
    c_1 = ( ((id >> 0) & 1) == 1 ) ? :d : :c
    c_2 = ( ((id >> 1) & 1) == 1 ) ? :d : :c
    c_3 = ( ((id >> 2) & 1) == 1 ) ? :d : :c
    b_1 = ( ((id >> 3) & 1) == 1 ) ? :d : :c
    b_2 = ( ((id >> 4) & 1) == 1 ) ? :d : :c
    b_3 = ( ((id >> 5) & 1) == 1 ) ? :d : :c
    a_1 = ( ((id >> 6) & 1) == 1 ) ? :d : :c
    a_2 = ( ((id >> 7) & 1) == 1 ) ? :d : :c
    a_3 = ( ((id >> 8) & 1) == 1 ) ? :d : :c
    self.new(a_3,a_2,a_1, b_3,b_2,b_1, c_3,c_2,c_1)
  end

  def self.make_from_bits( bits )
    raise "invalid arg" unless bits.is_a?(String) and bits.length == 9 and bits.each_char.all? {|b| b=='c' or b=='d'}

    args = bits.each_char.map(&:to_sym)
    self.new(*args)
  end

  attr_reader :a_3,:a_2,:a_1,:b_3,:b_2,:b_1,:c_3,:c_2,:c_1

  def initialize(a_3,a_2,a_1,b_3,b_2,b_1,c_3,c_2,c_1)
    @a_3 = a_3
    @a_2 = a_2
    @a_1 = a_1
    @b_3 = b_3
    @b_2 = b_2
    @b_1 = b_1
    @c_3 = c_3
    @c_2 = c_2
    @c_1 = c_1
    unless to_a.all? {|a| a == :d or a == :c }
      raise "invalid state"
    end
  end

  def to_a
    [@a_3,@a_2,@a_1,@b_3,@b_2,@b_1,@c_3,@c_2,@c_1]
  end

  def to_id
    nums = to_a.each_with_index.map do |act,idx|
      act == :d ? 2**(8-idx) : 0
    end
    nums.inject(:+)
  end
  alias :to_i :to_id

  def ==(other)
    self.to_id == other.to_id
  end

  def to_m2_states
    fs1 = N3M2::State.new(@a_3,@a_2,@b_3,@b_2,@c_3,@c_2)
    fs2 = N3M2::State.new(@a_2,@a_1,@b_2,@b_1,@c_2,@c_1)
    [fs1,fs2]
  end

  def state_from( player )
    case player
    when :A
      self.clone
    when :B
      State.new(@b_3,@b_2,@b_1,@c_3,@c_2,@c_1,@a_3,@a_2,@a_1)
    when :C
      State.new(@c_3,@c_2,@c_1,@a_3,@a_2,@a_1,@b_3,@b_2,@b_1)
    else
      raise "must not happen"
    end
  end

  def next_state(act_a,act_b,act_c)
    self.class.new(@a_2,@a_1,act_a,@b_2,@b_1,act_b,@c_2,@c_1,act_c)
  end

  def neighbor_states
    act_a = (@a_1 == :c ? :d : :c)
    act_b = (@b_1 == :c ? :d : :c)
    act_c = (@c_1 == :c ? :d : :c)
    flip_a = self.class.new(@a_3,@a_2,act_a,@b_3,@b_2,@b_1,@c_3,@c_2,@c_1)
    flip_b = self.class.new(@a_3,@a_2,@a_1,@b_3,@b_2,act_b,@c_3,@c_2,@c_1)
    flip_c = self.class.new(@a_3,@a_2,@a_1,@b_3,@b_2,@b_1,@c_3,@c_2,act_c)
    [flip_a,flip_b,flip_c]
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

  def to_s
    a = to_a
    a[0..2].join('') + '-' + a[3..5].join('') + '-' + a[6..8].join('')
  end
end

class Strategy

  N = State::NUM_STATES

  def initialize( actions )
    raise "invalid arg" unless actions.all? {|act| act == :c or act == :d }
    raise "invalid arg" unless actions.size == N
    @actions = actions.dup
  end

  def to_bits
    @actions.join('')
  end

  def to_a
    @actions.dup
  end

  def show_actions(io)
    State::NUM_STATES.times do |i|
      act = @actions[i]
      stat = State.make_from_id(i)
      io.print "#{act}|#{stat}\t"
      io.print "\n" if i % 10 == 9
    end
    io.print "\n"
  end

  def show_actions_latex(io)
    a_states = 0..7
    bc_states = 0..63

    io.puts <<-'EOS'
\begin{tabular}{c|cccccccc}
\hline
& \multicolumn{8}{c}{$A_{t-3}A_{t-2}A_{t-1}$} \\
$B_{t-3}B_{t-2}B_{t-1}C_{t-3}C_{t-2}C_{t-1}$ & $ccc$ & $ccd$ & $cdc$ & $cdd$ & $dcc$ & $dcd$ & $ddc$ & $ddd$ \\
\hline
EOS

    bc_states.each do |bc|
      b = bc / 8
      c = bc % 8
      next if b > c
      acts = a_states.map do |a|
        i = a * 64 + bc
        @actions[i]
      end
      bits = State.make_from_id(bc).to_a # to make header
      header = "$#{bits[3..5].join}#{bits[6..8].join}$"
      if b != c
        header += " / $#{bits[6..8].join}#{bits[3..5].join}$"
      else
        header += "           "
      end
      io.puts header + " & " + acts.map{|x| "$#{x}$" }.join(' & ') + " \\\\"
    end

    io.puts <<-'EOS'
\hline
\end{tabular}
EOS
  end

  def self.make_from_bits( bits )
    actions = bits.each_char.map do |chr|
      chr.to_sym
    end
    self.new( actions )
  end

  def self.make_from_m2_strategy( m2_stra )
    acts = []
    N.times do |i|
      m3_stat = State.make_from_id(i)
      m2_stat = m3_stat.to_m2_states.last
      act = m2_stra.action( m2_stat.to_ss )
      acts << act
    end
    self.new(acts)
  end

  def modify_action( state, action )
    if state.is_a?(String)
      stat = State.make_from_bits(state)
      @actions[stat.to_id] = action
    elsif state.is_a?(State)
      @actions[state.to_id] = action
    else
      raise "invalid arg"
    end
  end

  def action( state )
    i =
      case state
      when Integer
        state
      when State
        state.to_id
      when Array
        State.new(*state).to_id
      when String
        State.make_from_bits(state).to_id
      else
        raise "invalid input"
      end
    @actions[i]
  end

  def valid?
    @actions.all? {|a| a == :c or a == :d }
  end

  def possible_next_states(current_fs)
    sid = current_fs.to_id
    act_a = action(sid)
    n1 = current_fs.next_state(act_a,:c,:c)
    n2 = current_fs.next_state(act_a,:c,:d)
    n3 = current_fs.next_state(act_a,:d,:c)
    n4 = current_fs.next_state(act_a,:d,:d)
    [n1,n2,n3,n4]
  end

  def next_state_with_self(s)
    next_state_with(s, self, self)
  end

  def next_state_with(s, b_strategy, c_strategy)
    act_a = action(s.to_id)
    state_b = State.new( s.b_3, s.b_2, s.b_1, s.c_3, s.c_2, s.c_1, s.a_3, s.a_2, s.a_1 )
    act_b = b_strategy.action(state_b.to_id)
    state_c = State.new( s.c_3, s.c_2, s.c_1, s.a_3, s.a_2, s.a_1, s.b_3, s.b_2, s.b_1 )
    act_c = c_strategy.action(state_c.to_id)
    s.next_state(act_a, act_b, act_c)
  end

  def transition_graph
    g = DirectedGraph.new(N)
    N.times do |i|
      s = State.make_from_id(i)
      next_ss = possible_next_states(s)
      next_ss.each do |ns|
        g.add_link(i, ns.to_id)
      end
    end
    g
  end

  def noisy_transition_graph
    g = DirectedGraph.new(N)
    N.times do |i|
      s = State.make_from_id(i)
      acts = [
        [:c,:c,:c],[:c,:c,:d],[:c,:d,:c],[:c,:d,:d],
        [:d,:c,:c],[:d,:c,:d],[:d,:d,:c],[:d,:d,:d]
      ]
      acts.each do |a|
        ns = s.next_state(*a)
        g.add_link(i, ns.to_i)
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
      current = State.make_from_id(i)
      j = next_state_with(current, b_strategy, c_strategy).to_id
      g.add_link( i, j )
    end
    g
  end

  def defensible?
    if symmetric_with_BC_swap?
      defensible_against(:B)
    else
      $stderr.puts "Warning: not symmetric with respect to the swap of BC"
      defensible_against(:B) and defensible_against(:C)
    end
  end

  def symmetric_with_BC_swap?
    checked = Array.new(N, false)
    N.times do |i|
      next if checked[i]
      s = State.make_from_id(i)
      swapped = State.new(s.a_3,s.a_2,s.a_1, s.c_3,s.c_2,s.c_1, s.b_3,s.b_2,s.b_1)
      return false unless action(s.to_id) == action(swapped.to_id)
      checked[s.to_id] = true
      checked[swapped.to_id] = true
    end
    true
  end

  def defensible_against(coplayer=:B)
    d = Array.new(N) { Array.new(N, Float::INFINITY) }
    N.times do |i|
      s = State.make_from_id(i)
      ns = possible_next_states(s)
      ns.each do |n|
        j = n.to_id
        d[i][j] = s.relative_payoff_against(coplayer)
      end
    end
    N.times do |k|
      $stderr.puts "#{k} / #{N}" if k % (N/8) == 0
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
    allc = Strategy.make_from_bits('c'*512)
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
    noised_states = lambda {|s| [s^1, s^8, s^64] }

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

  def minimize_DFA(noisy=false)
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
      uf_0_h.each do |r,s|  # refining a set in uf_0
        s.combination(2).each do |i,j|
          if _equivalent(i, j, uf_0, noisy)
            uf.merge(i,j)
          end
        end
      end
      break if uf.to_h == uf_0_h
      uf_0 = uf
    end

    g = DirectedGraph.new(N)
    org_g = noisy ? noisy_transition_graph : transition_graph
    org_g.for_each_link do |i,j|
      ri = uf_0.root(i)
      rj = uf_0.root(j)
      g.add_link(ri,rj)
    end
    g.remove_duplicated_links!

    return uf_0, g
  end

  def _equivalent(i, j, uf, noisy)
    # both action & next state must be identical
    raise unless action(i) == action(j)
    act_a = action(i)
    err_a = act_a == :c ? :d : :c
    acts_other = [[:c,:c],[:c,:d],[:d,:c],[:d,:d]]
    acts_other.each do |act_b,act_c|
      ni = State.make_from_id(i).next_state(act_a, act_b, act_c).to_id
      nj = State.make_from_id(j).next_state(act_a, act_b, act_c).to_id
      return false unless uf.root(ni) == uf.root(nj)
      if noisy
        ni2 = State.make_from_id(i).next_state(err_a, act_b, act_c).to_id
        nj2 = State.make_from_id(j).next_state(err_a, act_b, act_c).to_id
        return false unless uf.root(ni2) == uf.root(nj2)
      end
    end
    true
  end

  def trace_state_until_cycle(s)
    g = transition_graph_with_self
    traced = []
    g.dfs(s.to_id) do |x|
      traced.push(State.make_from_id(x))
    end
    traced
  end

  # overwrite actions to make PS2 fully successful
  def make_PS2_FUSS
    # noise on B&C (state 0->5)
    modify_action('ccdccdccc',:c) # (5->26)
    modify_action('ccdcccccd',:c) # (5->26)
    modify_action('cdccdcccd',:c) # (26->48)
    modify_action('cdcccdcdc',:c) # (26->48)
    # noise on B -> on B (state 4->29)
    modify_action('cddccdccd',:c) # (29->59) B
    modify_action('ddccddcdd',:c) # (59->34) B
    modify_action('cddddccdd',:c) # (59->34) A or C
    modify_action('cddcddddc',:c) # (59->34) A or C
    # noise on B -> on C (state 4->24)
    modify_action('cdcccdccc',:c) # (24->48)
    modify_action('cdccccccd',:c) # (24->48)
    modify_action('ccccdcccd',:c) # (24->48)
    modify_action('cccccdcdc',:c) # (24->48)
    # noise on B -> _ -> on B (state 25->38)
    modify_action('dcdcdccdc',:c) # (38->25)
    # noise on B -> _ -> on C (state25->35)
    modify_action('cdddcccdc',:c) # (35->48)
    modify_action('cddcdcdcc',:c) # (35->48)
  end
end
end

if __FILE__ == $0
  ARGV.each do |arg|
    pp N3M3::Strategy.make_from_bits(arg)
  end
end

