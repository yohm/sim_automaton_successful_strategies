require_relative 'n3m3_strategy'

require 'minitest/autorun'

include N3M3

class StateM3Test < Minitest::Test

  def test_alld
    fs = FullState.make_from_id(511)
    assert_equal [:d,:d,:d,:d,:d,:d,:d,:d,:d], fs.to_a
    assert_equal 'ddd-ddd-ddd', fs.to_s
    assert_equal 511, fs.to_id
    assert_equal 0, fs.relative_payoff_against(:C)
    assert_equal 0, fs.relative_payoff_against(:B)
  end

  def test_allc
    fs = FullState.make_from_id(0)
    assert_equal [:c,:c,:c,:c,:c,:c,:c,:c,:c], fs.to_a
    assert_equal 'ccc-ccc-ccc', fs.to_s
    assert_equal 0, fs.to_id
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal 0, fs.relative_payoff_against(:C)
  end

  def test_state273
    fs = FullState.make_from_id(273)
    assert_equal [:d, :c, :c, :c, :d, :c, :c, :c, :d], fs.to_a
    assert_equal 'dcc-cdc-ccd', fs.to_s
    assert_equal 273, fs.to_id
    assert_equal 0, fs.relative_payoff_against(:B)
    assert_equal -1, fs.relative_payoff_against(:C)
    assert_equal 'ccc-dcd-cdd', fs.next_state(:c,:d,:d).to_s
  end

  def test_equality
    fs1 = FullState.make_from_id(273)
    fs2 = FullState.new(:d,:c,:c,:c,:d,:c,:c,:c,:d)
    assert_equal true, fs1==fs2
  end

  def test_neighbor_states
    fs = FullState.make_from_id(511)
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

    s = FullState.new(:d,:c,:c,:c,:c,:d,:d,:d,:c)
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

    s = FullState.new(:d,:c,:c,:c,:c,:d,:d,:d,:c)
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

  def test_recovery_allC
    bits = "c"*512
    stra = Strategy.make_from_bits(bits)

    assert_equal ['ccc-ccc-ccc'], stra.recovery_path_nodes(0).map(&:to_s)

    path = stra.recovery_path_nodes(1)
    path_a = ['ccd-ccc-ccc','cdc-ccc-ccc','dcc-ccc-ccc','ccc-ccc-ccc']
    path_b = swap_players(path_a,0,1)
    path_c = swap_players(path_a,0,2)
    assert_equal (path_a+path_b+path_c).uniq.sort, path.map(&:to_s).sort

    path = stra.recovery_path_nodes(2)
    path_ab = ['ccd-ccd-ccc','cdc-cdc-ccc','dcc-dcc-ccc','ccc-ccc-ccc']
    path_ac = swap_players(path_ab,1,2)
    path_bc = swap_players(path_ab,0,2)

    path_a_a = ['ccd-ccc-ccc','cdd-ccc-ccc','ddc-ccc-ccc','dcc-ccc-ccc','ccc-ccc-ccc']
    path_a_b = ['ccd-ccc-ccc','cdc-ccd-ccc','dcc-cdc-ccc','ccc-dcc-ccc','ccc-ccc-ccc']
    path_a_c = swap_players(path_a_b,1,2)
    path_b_a = swap_players(path_a_b,0,1)
    path_b_b = swap_players(path_a_a,0,1)
    path_b_c = swap_players(path_b_a,0,2)
    path_c_a = swap_players(path_a_c,0,2)
    path_c_b = swap_players(path_c_a,0,1)
    path_c_c = swap_players(path_a_a,0,2)

    path_a__a = ['ccd-ccc-ccc','cdc-ccc-ccc','dcd-ccc-ccc','cdc-ccc-ccc','dcc-ccc-ccc','ccc-ccc-ccc']
    path_a__b = ['ccd-ccc-ccc','cdc-ccc-ccc','dcc-ccd-ccc','ccc-cdc-ccc','ccc-dcc-ccc','ccc-ccc-ccc']
    path_a__c = swap_players(path_a__b,1,2)
    path_b__a = swap_players(path_a__b,0,1)
    path_b__b = swap_players(path_a__a,0,1)
    path_b__c = swap_players(path_b__a,0,2)
    path_c__a = swap_players(path_b__a,1,2)
    path_c__b = swap_players(path_c__a,0,1)
    path_c__c = swap_players(path_a__a,0,2)

    all = path_ab+path_ac+path_bc+path_a_a+path_a_b+path_a_c+path_b_a+path_b_b+path_b_c+
        path_c_a+path_c_b+path_c_c+path_a__a+path_a__b+path_a__c+path_b__a+path_b__b+path_b__c+path_c__a+path_c__b+path_c__c
    assert_equal all.uniq.sort, path.map(&:to_s).sort
  end

  def test_recovery_PS2
    # most generous version of PS2 extended to m=3
    stra = Strategy.make_from_bits(PS2_bits)

    assert_equal ['ccc-ccc-ccc'], stra.recovery_path_nodes(0).map(&:to_s)

    path = stra.recovery_path_nodes(1)
    path_a = ['ccd-ccc-ccc','cdc-ccd-ccd','dcc-cdc-cdc','ccc-dcc-dcc','ccc-ccc-ccc']
    path_b = swap_players(path_a,0,1)
    path_c = swap_players(path_a,0,2)
    assert_equal (path_a+path_b+path_c).uniq.sort, path.map(&:to_s).sort

    assert_equal false, stra.recovery_path_nodes(2)
  end

  def test_recovery_SS
    # most generous successful m=3 strategy
    stra = Strategy.make_from_bits(SS_bits)

    assert_equal ['ccc-ccc-ccc'], stra.recovery_path_nodes(0).map(&:to_s)
    path = stra.recovery_path_nodes(1)
    path_a = ['ccd-ccc-ccc','cdc-ccd-ccd','dcc-cdc-cdc','ccc-dcc-dcc','ccc-ccc-ccc']
    path_b = swap_players(path_a,0,1)
    path_c = swap_players(path_a,0,2)
    assert_equal (path_a+path_b+path_c).uniq.sort, path.map(&:to_s).sort

    path = stra.recovery_path_nodes(2)
    path_bc = ['ccc-ccd-ccd','ccd-cdc-cdc','cdd-dcc-dcc','ddc-ccd-ccd','dcc-cdc-cdc','ccc-dcc-dcc','ccc-ccc-ccc']
    path_ab = swap_players(path_bc,0,2)
    path_ac = swap_players(path_ab,1,2)

    path_b_b = ['ccc-ccd-ccc','ccd-cdd-ccd','cdd-ddc-cdd','ddc-dcc-ddc','dcc-ccc-dcc','ccc-ccc-ccc']
    path_b_c = ['ccc-ccd-ccc','ccd-cdc-ccc','cdd-dcc-ccc','ddc-ccd-ccd','dcc-cdc-cdc','ccc-dcc-dcc','ccc-ccc-ccc']
    path_a_a = swap_players(path_b_b,0,1)
    path_a_b = swap_players(swap_players(path_b_c,0,1),1,2)
    path_a_c = swap_players(path_a_b,1,2)
    path_b_a = swap_players(path_a_b,0,1)
    #path_b_b = swap_players(path_a_a,0,1)
    #path_b_c = swap_players(path_b_a,0,2)
    path_c_a = swap_players(path_a_c,0,2)
    path_c_b = swap_players(path_c_a,0,1)
    path_c_c = swap_players(path_a_a,0,2)

    path_b__b = ['ccc-ccd-ccc','ccd-cdc-ccd','cdc-dcd-cdc','dcd-cdc-dcd','cdc-dcc-cdc','dcc-ccc-dcc','ccc-ccc-ccc']
    path_b__c = ['ccc-ccd-ccc','ccd-cdc-ccd','cdc-dcc-cdd','dcd-ccd-ddc','cdc-cdc-dcc','dcc-dcc-ccc','ccc-ccc-ccc']
    path_a__a = swap_players(path_b__b,0,1)
    path_a__b = swap_players(swap_players(path_b__c,1,2), 0,2)
    path_a__c = swap_players(path_a__b,1,2)
    path_b__a = swap_players(path_a__b,0,1)
    #path_b__b = swap_players(path_a__a,0,1)
    #path_b__c = swap_players(path_b__a,0,2)
    path_c__a = swap_players(path_b__a,1,2)
    path_c__b = swap_players(path_c__a,0,1)
    path_c__c = swap_players(path_a__a,0,2)

    path_b___b = ['ccc-ccd-ccc','ccd-cdc-ccd','cdc-dcc-cdc','dcc-ccd-dcc','ccd-cdc-ccd','cdc-dcc-cdc','dcc-ccc-dcc','ccc-ccc-ccc']
    path_a___a = swap_players(path_b___b,0,1)
    path_c___c = swap_players(path_a___a,0,2)
    path_b___c = ['ccc-ccd-ccc','ccd-cdc-ccd','cdc-dcc-cdc','dcc-ccc-dcd','ccd-ccd-cdc','cdc-cdc-dcc','dcc-dcc-ccc','ccc-ccc-ccc']
    path_b___a = swap_players(path_b___c,0,2)
    path_a___c = swap_players(path_b___c,0,1)
    path_a___b = swap_players(path_a___c,1,2)
    path_c___a = swap_players(path_b___a,1,2)
    path_c___b = swap_players(path_c___a,0,1)

    all = (path_a+path_b+path_c+
        path_ab+path_ac+path_bc+path_a_a+path_a_b+path_a_c+path_b_a+path_b_b+path_b_c+
        path_c_a+path_c_b+path_c_c+path_a__a+path_a__b+path_a__c+path_b__a+path_b__b+path_b__c+path_c__a+path_c__b+path_c__c+
        path_a___a+path_a___b+path_a___c+path_b___a+path_b___b+path_b___c+path_c___a+path_c___b+path_c___c).uniq
    assert_equal all.uniq.sort, path.map(&:to_s).uniq.sort

    assert_equal false, stra.recovery_path_nodes(3)
  end

  def swap_players(states, p1 = 0, p2 = 1)
    states.map {|state|
      splitted = state.split('-')
      splitted[p1], splitted[p2] = splitted[p2], splitted[p1]
      splitted.join('-')
    }
  end

  def test_trace_states
    # transition to fully cooperative state from defective state by two-bit error
    s = FullState.make_from_bits("ddcddcddd")

    stra = Strategy.make_from_bits(PS2_bits)
    trace = stra.trace_state_until_cycle(s)
    assert_equal 'ccc-ccc-ccc', trace.last.to_s

    stra = Strategy.make_from_bits(SS_bits)
    trace = stra.trace_state_until_cycle(s)
    assert_equal 'ccc-ccc-ccc', trace.last.to_s
  end
end

