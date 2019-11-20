require_relative 'n3m2_strategy'

require 'minitest/autorun'

class StateTest < Minitest::Test

  include N3M2

  def test_alld
    fs = State.make_from_id(63)
    assert_equal [:d,:d,:d,:d,:d,:d], fs.to_a
    assert_equal [:d,:d,2,2], fs.to_ss
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal 0, fs.relative_payoff_against(:C)
  end

  def test_allc
    fs = State.make_from_id(0)
    assert_equal [:c,:c,:c,:c,:c,:c], fs.to_a
    assert_equal [:c,:c,0,0], fs.to_ss
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal 0, fs.relative_payoff_against(:C)
  end

  def test_state43
    fs = State.make_from_id(43)
    assert_equal [:d, :c, :d, :c, :d, :d], fs.to_a
    assert_equal [:d,:c,2,1], fs.to_ss
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal -1, fs.relative_payoff_against(:C)
    assert_equal [:c,:c,:c,:d,:d,:d], fs.next_state(:c,:d,:d).to_a
  end

  def test_state44
    fs = State.make_from_id(44)
    assert_equal [:d, :c, :d, :d, :c, :c], fs.to_a
    assert_equal [:d,:c,1,-1], fs.to_ss
    assert_equal -1, fs.relative_payoff_against(:B)
    assert_equal 0, fs.relative_payoff_against(:C)
    assert_equal [:c,:d,:d,:d,:c,:d], fs.next_state(:d,:d,:d).to_a
  end

  def test_equality
    fs1 = State.make_from_id(15)
    fs2 = State.new(:c,:c,:d,:d,:d,:d)
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

    s = State.new(:c,:c,:d,:c,:c,:d)
    nexts = strategy.possible_next_states(s).map(&:to_s)
    expected = ['cdccdc', 'cdccdd', 'cdcddc', 'cdcddd']
    assert_equal expected, nexts

    next_state = strategy.next_state_with_self(s)
    assert_equal 'cdcddd', next_state.to_s

    assert_equal true, strategy.defensible?
    assert_equal false, strategy.efficient?
    assert_equal true, strategy.distinguishable?

    uf,ga = strategy.minimize_DFA
    assert_equal ({0=>(0..63).to_a}), uf.to_h
    assert_equal 1, ga.links.size
  end

  def test_allC
    bits = "c"*40
    strategy = Strategy.make_from_bits(bits)
    assert_equal bits, strategy.to_bits
    assert_equal :c, strategy.action([:c,:c,0,0] )
    assert_equal :c, strategy.action([:d,:d,2,2] )

    s = State.new(:c,:c,:d,:c,:c,:d)
    nexts = strategy.possible_next_states(s).map(&:to_s)
    expected = ['ccccdc', 'ccccdd', 'cccddc', 'cccddd']
    assert_equal expected, nexts

    next_state = strategy.next_state_with_self(s)
    assert_equal 'ccccdc', next_state.to_s

    assert_equal false, strategy.defensible?
    assert_equal true, strategy.efficient?
    assert_equal false, strategy.distinguishable?

    uf,ga = strategy.minimize_DFA
    assert_equal ({0=>(0..63).to_a}), uf.to_h
    assert_equal 1, ga.links.size
  end

  def test_a_strategy
    bits = "ccccdddcdddccccddcdddccccddcddcccccddddd"
    strategy = Strategy.make_from_bits(bits)
    assert_equal bits, strategy.to_bits
    assert_equal :c, strategy.action([:c,:c,0,0] )
    assert_equal :d, strategy.action([:d,:d,2,2] )

    s = State.new(:c,:c,:d,:c,:c,:d)
    move_a = strategy.action([:c,:c,1,1])  #=> d
    nexts = strategy.possible_next_states(s).map(&:to_s)
    expected = ['cdccdc', 'cdccdd', 'cdcddc', 'cdcddd']
    assert_equal expected, nexts

    next_state = strategy.next_state_with_self(s)
    move_b = strategy.action([:d,:c,0,1])
    move_c = strategy.action([:c,:d,1,0])
    assert_equal "c#{move_a}c#{move_b}d#{move_c}", next_state.to_s

    assert_equal false, strategy.defensible?
    assert_equal false, strategy.efficient?
    assert_equal true, strategy.distinguishable?

    uf,ga = strategy.minimize_DFA
    expected = {0=>[0, 2, 8, 10, 34, 40, 42],
                1=>[1, 4, 5, 21, 33, 36, 37, 38, 41, 53],
                3=>[3, 9, 11, 19, 27, 35, 43, 51, 59],
                6=>[6, 12, 14, 28, 30, 44, 46, 60, 62],
                7=>[7, 13, 15, 39, 45, 47],
                16=>[16, 58],
                17=>[17, 25, 49, 57],
                18=>[18, 24, 26, 48, 50, 56],
                20=>[20, 22, 52, 54],
                23=>[23, 29, 31, 55, 61, 63],
                32=>[32]}
    assert_equal expected, uf.to_h
    assert_equal 11, ga.links.size
  end

  def test_AON2
    bits = Array.new(40)
    Strategy::N.times do |i|
      s = State.make_from_id(i)
      if s.a_2 == s.b_2 and s.a_2 == s.c_2 and s.a_1 == s.b_1 and s.a_1 == s.c_1
        bits[ShortState.index(s.to_ss)] = 'c'
      else
        bits[ShortState.index(s.to_ss)] = 'd'
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

    uf,ga = strategy.minimize_DFA
    expected = {0=>[0, 21, 42, 63],
                1=>[1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                    22, 24, 25, 26, 27, 28, 30, 33, 35, 36, 37, 38, 39, 41, 43,
                    44, 45, 46, 47, 48, 49, 50, 51, 52, 54, 56, 57, 58, 59, 60, 62],
                2=>[2, 8, 10, 23, 29, 31, 32, 34, 40, 53, 55, 61]}
    assert_equal expected, uf.to_h
    assert_equal 3, ga.links.size
  end

  def test_most_generous_PS2
    bits = "cddcdddcddcccdcddddddcccdddcccccddcddddd"
    strategy = Strategy.make_from_bits(bits)
    assert_equal bits, strategy.to_bits
    assert_equal :c, strategy.action([:c,:c,0,0] )
    assert_equal :d, strategy.action([:d,:d,2,2] )

    s = State.new(:c,:c,:d,:c,:c,:d)
    move_a = strategy.action([:c,:c,1,1]) #=> d
    nexts = strategy.possible_next_states(s).map(&:to_s)
    expected = ['cdccdc', 'cdccdd', 'cdcddc', 'cdcddd']
    assert_equal expected, nexts

    next_state = strategy.next_state_with_self(s)
    move_b = strategy.action([:d,:c,0,1])
    move_c = strategy.action([:c,:d,1,0])
    assert_equal "c#{move_a}c#{move_b}d#{move_c}", next_state.to_s
    assert_equal true, strategy.defensible?
    assert_equal false, strategy.efficient?
    assert_equal true, strategy.distinguishable?

    uf,ga = strategy.minimize_DFA
    expected = {0=>[0, 2, 8, 10, 17, 20, 22, 25, 33, 34, 36, 37, 40,
                    42, 43, 46, 47, 49, 52, 54, 57],
                1=>[1, 3, 9, 11, 19, 27, 35, 41, 51, 59],
                4=>[4, 6, 12, 14, 28, 30, 38, 44, 60, 62],
                5=>[5, 7, 13, 15, 23, 29, 31, 39, 45, 53, 55, 61, 63],
                16=>[16, 48],
                18=>[18, 24, 26, 50, 56, 58],
                21=>[21],
                32=>[32]}
    assert_equal expected, uf.to_h
    assert_equal 8, ga.links.size
  end
end

