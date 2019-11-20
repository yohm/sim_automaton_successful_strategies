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

    s = State.new(:c,:c,:d,:c,:c,:d)
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

    s = State.new(:c,:c,:d,:c,:c,:d)
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
  end

  def test_most_generous_PS2
    bits = "cddcdddcddcccdcddddddcccdddcccccddcddddd"
    strategy = Strategy.make_from_bits(bits)
    assert_equal bits, strategy.to_bits
    assert_equal :c, strategy.action([:c,:c,0,0] )
    assert_equal :d, strategy.action([:d,:d,2,2] )

    s = State.new(:c,:c,:d,:c,:c,:d)
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

