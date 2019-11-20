require_relative 'n3m3_strategy'

require 'minitest/autorun'

include N3M3

class StateM3Test < Minitest::Test

  def test_alld
    fs = State.make_from_id(511)
    assert_equal [:d,:d,:d,:d,:d,:d,:d,:d,:d], fs.to_a
    assert_equal 'ddd-ddd-ddd', fs.to_s
    assert_equal 511, fs.to_id
    assert_equal 0, fs.relative_payoff_against(:C)
    assert_equal 0, fs.relative_payoff_against(:B)
  end

  def test_allc
    fs = State.make_from_id(0)
    assert_equal [:c,:c,:c,:c,:c,:c,:c,:c,:c], fs.to_a
    assert_equal 'ccc-ccc-ccc', fs.to_s
    assert_equal 0, fs.to_id
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal 0, fs.relative_payoff_against(:C)
  end

  def test_state273
    fs = State.make_from_id(273)
    assert_equal [:d, :c, :c, :c, :d, :c, :c, :c, :d], fs.to_a
    assert_equal 'dcc-cdc-ccd', fs.to_s
    assert_equal 273, fs.to_id
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal -1, fs.relative_payoff_against(:C)
    assert_equal 'ccc-dcd-cdd', fs.next_state(:c,:d,:d).to_s
  end

  def test_equality
    fs1 = State.make_from_id(273)
    fs2 = State.new(:d,:c,:c,:c,:d,:c,:c,:c,:d)
    assert_equal true, fs1==fs2
  end

  def test_neighbor_states
    fs = State.make_from_id(511)
    neighbors = fs.neighbor_states.map(&:to_s).sort
    assert_equal ['ddc-ddd-ddd','ddd-ddc-ddd','ddd-ddd-ddc'], neighbors
  end
end

class StrategyTest < Minitest::Test

  PS2_bits = "cdcdcdcdddddddddcdcdcdcdddddddddcdcdcdcdddddddddcdcdc"+
             "dcdddddddddccddccddcccdcccddcdddcddddddddddccddccddcc"+
             "cdcccddcdddcdddddddddddccddccdccddccddcdcccdccddccddc"+
             "cdccddccdccddccddcdcccdccddccddccccddccddcdcdcdcddcdd"+
             "dcddddddddddccddccddcdcdcdcddcdddcddddddddddcdcdcdcdd"+
             "dddddddcdcdcdcdddddddddcdcdcdcdddddddddcdcdcdcddddddd"+
             "ddccddccddcccdcccddcdddcddddddddddccddccddcccdcccddcd"+
             "ddcdddddddddddccddccdccddccddcdcccdccddccddccdccddccd"+
             "ccddccddcdcccdccddccddccccddccddcdcdcdcddcdddcddddddd"+
             "dddccddccddcdcdcdcddcdddcdddddddddd"
  SS_bits = "cdcdcdcdddcdddddcccdcdcdddddddddcdcdcdcdddddddddcdcdcd"+
            "cdddddddddccddccddcccdcccddcdddcddddddddddccddccddcccd"+
            "cccddcdddcdddddddddddccddccdcccdccddcccccdccddccddccdc"+
            "cddccdccddccddcdcccdccddccddccccddccddcccdcdcddcddccdd"+
            "ddddddcdcccdccddcdcdcdcddcdcdcddddddddddcdcdcdcddddddd"+
            "ddcdcdcdcdddddddddcdcdcdcdddddddddcdcdcdcdddddddddccdd"+
            "ccddcccdcccddccddcddddddddddccddccddcccdcccddcdddcdddd"+
            "dddddddccddccdccddccddcdcccdccddccddccdccddccdccddccdd"+
            "cdcccdccddccddccccddccddcdcdcdcddcdddcddddddddddccddcc"+
            "ddcdcdcdcddcdddcdddddddddd"

  def test_allD
    bits = "d"*512
    stra = Strategy.make_from_bits(bits)
    assert_equal bits, stra.to_bits
    assert_equal :d, stra.action(0)
    assert_equal :d, stra.action(511)
    assert_equal true, stra.valid?

    s = State.new(:d,:c,:c,:c,:c,:d,:d,:d,:c)
    nexts = stra.possible_next_full_states(s).map(&:to_s)
    expected = ['ccd-cdc-dcc', 'ccd-cdc-dcd', 'ccd-cdd-dcc', 'ccd-cdd-dcd']
    assert_equal expected, nexts

    next_state = stra.next_full_state_with_self(s)
    assert_equal 'ccd-cdd-dcd', next_state.to_s

    assert_equal true, stra.defensible?  # it takes long time
    assert_equal false, stra.efficient?
    assert_equal true, stra.distinguishable?
  end

  def test_allC
    bits = "c"*512
    stra = Strategy.make_from_bits(bits)
    assert_equal bits, stra.to_bits
    assert_equal :c, stra.action(0)
    assert_equal :c, stra.action(511)
    assert_equal true, stra.valid?

    s = State.new(:d,:c,:c,:c,:c,:d,:d,:d,:c)
    nexts = stra.possible_next_full_states(s).map(&:to_s)
    expected = ['ccc-cdc-dcc', 'ccc-cdc-dcd', 'ccc-cdd-dcc', 'ccc-cdd-dcd']
    assert_equal expected, nexts

    next_state = stra.next_full_state_with_self(s)
    assert_equal 'ccc-cdc-dcc', next_state.to_s

    assert_equal false, stra.defensible?
    assert_equal true, stra.efficient?
    assert_equal false, stra.distinguishable?
  end

  def test_make_from_m2_strategy
    bits = "cddcdddcddcccdcddddddcccdddcccccddcddddd"
    m2_stra = N3M2::Strategy.make_from_bits(bits)
    m3_stra = Strategy.make_from_m2_strategy(m2_stra)

    assert_equal :c, m3_stra.action(0)
    assert_equal :d, m3_stra.action(511)

    m3_stra.modify_action('ddddddddd', :c)
    assert_equal :c, m3_stra.action(511)
  end

  def test_SS
    # the most generous successful strategy
    stra = Strategy.make_from_bits(SS_bits)

    assert_equal :c, stra.action(0)
    assert_equal :d, stra.action(511)

    assert_equal true, stra.defensible?
    assert_equal true, stra.efficient?
    assert_equal true, stra.distinguishable?
  end

  def test_PS2
    stra = Strategy.make_from_bits(PS2_bits)
    assert_equal true, stra.defensible?
    assert_equal false, stra.efficient?
    assert_equal true, stra.distinguishable?
  end

  def test_trace_states
    # transition to fully cooperative state from defective state by two-bit error
    s = State.make_from_bits("ddcddcddd")

    stra = Strategy.make_from_bits(PS2_bits)
    trace = stra.trace_state_until_cycle(s)
    assert_equal 'ccc-ccc-ccc', trace.last.to_s

    stra = Strategy.make_from_bits(SS_bits)
    trace = stra.trace_state_until_cycle(s)
    assert_equal 'ccc-ccc-ccc', trace.last.to_s
  end
end

