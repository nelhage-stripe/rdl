module RDL::Type
  class SingletonType < Type
    attr_reader :val
    attr_reader :nominal

    @@cache = {}
    @@cache.compare_by_identity

    class << self
      alias :__new__ :new
    end

    def self.new(val)
      t = @@cache[val]
      return t if t
      t = self.__new__ val
      return (@@cache[val] = t) # assignment evaluates to t
    end

    def initialize(val)
      @val = val
      @nominal = NominalType.new(val.class)
    end

    def ==(other)
      return false if other.nil?
      other = other.canonical
      return (other.instance_of? self.class) && (other.val.equal? @val)
    end

    alias eql? ==

    def match(other)
      other = other.canonical
      other = other.type if other.instance_of? AnnotatedArgType
      return true if other.instance_of? WildQuery
      return self == other
    end

    def hash # :nodoc:
      return @val.hash
    end

    def to_s
      if @val.instance_of? Symbol
        ":#{@val}"
      elsif @val.nil?
        "nil"
      else
        @val.to_s
#        "Singleton(#{@val.to_s})"
      end
    end

    def <=(other)
      other = other.type if other.is_a? DependentArgType
      other = other.canonical
      other.instance_of?(TopType) ||
        (@val.nil? && (not (other.instance_of?(SingletonType)))) ||
        (other.instance_of?(SingletonType) && other.val == @val) ||
        (other.instance_of?(UnionType) && other.types.any? { |ot| self <= ot }) ||
        (@nominal <= other)
    end

    def leq_inst(other, inst=nil, ileft=true)
      other = other.type if other.is_a? DependentArgType
      other = other.canonical
      if inst && !ileft && other.is_a?(VarType)
        return leq_inst(inst[other.name], inst, ileft) if inst[other.name]
        inst.merge!(other.name => self)
        return true
      end
      return true if other.is_a?(TopType)
      return true if (@val.nil? && (not (other.is_a?(SingletonType))))
      return true if (other.is_a?(SingletonType) && other.val == @val)
      if other.is_a? UnionType
        # TODO same logic as nominal...
      end
      return @nominal.leq_inst(other, inst, ileft)
    end

    def member?(obj, *args)
      t = RDL::Util.rdl_type obj
      return t <= self if t
      obj.equal?(@val)
    end

    def instantiate(inst)
      return self
    end
  end
end
