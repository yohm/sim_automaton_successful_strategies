class UnionFind
  def initialize(n)
    @par = Array.new(n) {|i| i}
  end

  def root(i)
    if @par[i] != i
      r = root(@par[i])
      @par[i] = r
    end
    @par[i]
  end

  def roots
    to_h.keys.sort
  end

  def merge(i, j)
    ri = root(i)
    rj = root(j)
    return false if ri == rj  # already merged
    ri,rj = rj,ri if ri > rj
    @par[rj] = ri
  end

  def to_h
    @par.size.times.group_by {|i| root(i) }
  end
end

