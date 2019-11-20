require_relative 'n2m2_strategy'

require 'minitest/autorun'

class StateTest < Minitest::Test

  include N2M2

  def test_all
    assert_equal State::ALL_STATES.length, 16
  end

  def test_alld
    s = State.make_from_id(15)
    assert_equal [:d,:d,:d,:d], s.to_a
    assert_equal 0, s.relative_payoff
  end

  def test_allc
    s = State.make_from_id(0)
    assert_equal [:c,:c,:c,:c], s.to_a
    assert_equal 0, s.relative_payoff
    assert_equal State.make_from_str("cccc"), s
  end

  def test_state9
    s = State.make_from_id(9)
    assert_equal State.make_from_str("dccd"), s
    assert_equal -1, s.relative_payoff
  end
end

class StrategyTest < Minitest::Test

  include N2M2

  def test_allD
    s = Strategy.make_from_str("d"*16)
    assert_equal 'd'*16, s.to_s
    assert_equal :d, s.action(0)
    assert_equal 'cdcd', s.next_state_with_self( State.make_from_str('cccc') ).to_s
    assert_equal true, s.defensible?
    assert_equal false, s.efficient?
    assert_equal true, s.distinguishable?

    uf,ga = s.minimize_DFA
    assert_equal ({0=>[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}), uf.to_h
    assert_equal 1, ga.links.size
  end

  def test_allC
    s = Strategy.make_from_str("c"*16)
    assert_equal 'c'*16, s.to_s
    assert_equal :c, s.action(15)
    assert_equal 'dccc', s.next_state_with_self( State.make_from_str('cdcc') ).to_s
    assert_equal false, s.defensible?
    assert_equal true, s.efficient?
    assert_equal false, s.distinguishable?

    uf,ga = s.minimize_DFA
    assert_equal ({0=>[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}), uf.to_h
    assert_equal 1, ga.links.size
  end

  def test_TFT
    s = Strategy.make_from_str("cd"*8)
    assert_equal :c, s.action('cdcc')
    assert_equal :d, s.action('cccd')
    assert_equal 'dccd', s.next_state_with_self( State.make_from_str('cdcc') ).to_s
    assert_equal true, s.defensible?
    assert_equal false, s.efficient?
    assert_equal false, s.distinguishable?

    uf,ga = s.minimize_DFA
    assert_equal ({0=>[0,2,4,6,8,10,12,14], 1=>[1,3,5,7,9,11,13,15]}), uf.to_h
    assert_equal 2, ga.links.size
  end

  def test_WSLS
    s = Strategy.make_from_str("cdcddcdccdcddcdc")
    assert_equal :d, s.action('cdcc')
    assert_equal :d, s.action('cccd')
    assert_equal :c, s.action('dddd')
    assert_equal 'ddcd', s.next_state_with_self( State.make_from_str('cdcc') ).to_s
    assert_equal false, s.defensible?
    assert_equal true, s.efficient?
    assert_equal true, s.distinguishable?

    uf,ga = s.minimize_DFA
    assert_equal ({0=>[0,2,5,7,8,10,13,15], 1=>[1,3,4,6,9,11,12,14]}), uf.to_h
    assert_equal 2, ga.links.size
  end

  def test_TFT_ATFT
    s = Strategy.make_from_str("cdcddccdcdccdccd")
    assert_equal :d, s.action('cdcc')
    assert_equal :d, s.action('cccd')
    assert_equal :d, s.action('dddd')
    assert_equal 'ddcd', s.next_state_with_self( State.make_from_str('cdcc') ).to_s
    assert_equal true, s.defensible?
    assert_equal true, s.efficient?
    assert_equal true, s.distinguishable?

    uf,ga = s.minimize_DFA
    assert_equal ({0=>[0,2,6,8,10,11,14], 1=>[1,3,7,9,15], 4=>[4,12], 5=>[5,13]}), uf.to_h
    assert_equal 4, ga.links.size
  end
end

