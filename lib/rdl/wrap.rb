module RDL
  class Wrap
    def self.wrapped?(klass, meth)
      RDL.method_defined?(klass, wrapped_name(klass, meth))
    end
  
    def self.add_contract(klass, meth, kind, val)
      klass = klass.to_s
      meth = meth.to_sym
      # $__rdl_contracts is defined in RDL
      $__rdl_contracts[klass] = {} unless $__rdl_contracts[klass]
      $__rdl_contracts[klass][meth] = {} unless $__rdl_contracts[klass][meth]
      $__rdl_contracts[klass][meth][kind] = [] unless $__rdl_contracts[klass][meth][kind]
      $__rdl_contracts[klass][meth][kind] << val
    end

    def self.has_contracts(klass, meth, kind)
      klass = klass.to_s
      meth = meth.to_sym
      return ($__rdl_contracts.has_key? klass) &&
             ($__rdl_contracts[klass].has_key? meth) &&
             ($__rdl_contracts[klass][meth].has_key? kind)
    end

    def self.get_contracts(klass, meth, kind)
      klass = klass.to_s
      meth = meth.to_sym
      return $__rdl_contracts[klass][meth][kind]
    end
    
    # [+klass+] may be a Class, String, or Symbol
    # [+meth+] may be a String or Symbol
    #
    # Wraps klass#method to check contracts and types. Does not rewrap
    # if already wrapped.

    def self.wrap(klass, meth)
      # Check RDL
      klass = RDL.to_class klass
      raise ArgumentError, "Attempt to wrap #{klass.to_s}\##{meth.to_s}" if klass.to_s =~ /^RDL::/
      meth_old = wrapped_name(klass, meth) # meth_old is a symbol
      return if klass.method_defined? meth_old  # Don't rewrap
      
      klass.class_eval <<-RUBY, __FILE__, __LINE__
      alias_method meth_old, meth
      def #{meth}(*args, &blk)
        klass = self.class
#        puts "Intercepted #{meth_old}(\#{args.join(", ")}) { \#{blk} }"
        if RDL::Wrap.has_contracts(klass, #{meth.inspect}, :pre) then
          RDL::Contract::AndContract.check_array(RDL::Wrap.get_contracts(klass, #{meth.inspect}, :pre),
                                                 *args, &blk)
        end
        ret = send(#{meth_old.inspect}, *args, &blk)
        if RDL::Wrap.has_contracts(klass, #{meth.inspect}, :post) then
          RDL::Contract::AndContract.check_array(RDL::Wrap.get_contracts(klass, #{meth.inspect}, :post),
                                                 ret, *args, &blk)
        end
        return ret
      end
RUBY
    end

    # [+default_class+] should be a class
    # [+name+] is the name to give the block as a contract
    def self.process_pre_post_args(default_class, name, *args, &blk)
      klass = meth = contract = nil
      if args.size == 3
        klass = class_to_string args[0]
        meth = meth_to_sym args[1]
        contract = args[2]
      elsif args.size == 2 && blk
        klass = class_to_string args[0]
        meth = meth_to_sym args[1]
        contract = RDL::Contract::FlatContract.new(name, &blk)
      elsif args.size == 2
        klass = default_class.to_s
        meth = meth_to_sym args[0]
        contract = args[1]
      elsif args.size == 1 && blk
        klass = default_class.to_s
        meth = meth_to_sym args[0]
        contract = RDL::Contract::FlatContract.new(name, &blk)
      elsif args.size == 1
        klass = default_class.to_s
        contract = args[0]
      elsif blk
        klass = default_class.to_s
        contract = RDL::Contract::FlatContract.new(name, &blk)        
      else
        raise ArgumentError, "No arguments received"
      end
      raise ArgumentError, "#{contract.class} received where Contract expected" unless contract.class < RDL::Contract::Contract
      return [klass, meth, contract]
    end
    
    private

    def self.wrapped_name(klass, meth)
      # TODO: []_old is not a valid method name. Need to translate []
      # and other special method names, and ? and !, specially
      "__rdl_#{meth.to_s}_old".to_sym
    end

    def self.class_to_string(klass)
      case klass
      when Class
        return klass.to_s
      when String
        return klass
      when Symbol
        return klass.to_s
      else
        raise ArgumentError, "#{klass.class} received where klass (Class, Symbol, or String) expected"
      end
    end

    def self.meth_to_sym(meth)
      case meth
      when String
        return meth.to_sym
      when Symbol
        return meth
      else
        raise ArgumentError, "#{meth.class} received where method (Symbol or String) expected"
      end
    end
  end
end

class Object

  # [+klass+] may be Class, Symbol, or String
  # [+method+] may be Symbol or String
  # [+contract+] must be a Contract
  #
  # Add a precondition to a method. Possible invocations:
  # pre(klass, meth, contract)
  # pre(klass, meth) { block } = pre(klass, meth, FlatContract.new { block })
  # pre(meth, contract) = pre(self, meth, contract)
  # pre(meth) { block } = pre(self, meth, FlatContract.new { block })
  # pre(contract) = pre(self, next method, contract)
  # pre { block } = pre(self, next method, FlatContract.new { block })
  def pre(*args, &blk)
    klass, meth, contract = RDL::Wrap.process_pre_post_args(self.class, "Precondition", *args, &blk)
    if meth
      if RDL.method_defined?(klass, meth)
        RDL::Wrap.wrap(klass, meth)
      else
        # $__rdl_to_wrap is initialized in rdl.rb
        $__rdl_to_wrap << [klass, meth]
      end
    else
      # TODO: Associate with next method definition
    end
    RDL::Wrap.add_contract(klass, meth, :pre, contract)
  end

  # Add a postcondition to a method. Same possible invocations as pre.
  def post(*args, &blk)
    klass, meth, contract = RDL::Wrap.process_pre_post_args(self.class, "Postcondition", *args, &blk)
    if meth
      if RDL.method_defined?(klass, meth)
        RDL::Wrap.wrap(klass, meth)
      else
        # $__rdl_to_wrap is initialized in rdl.rb
        $__rdl_to_wrap << [klass, meth]
      end
    else
      # TODO: Associate with next method definition
    end
    RDL::Wrap.add_contract(klass, meth, :post, contract)
  end

  # def type(klass, meth, type)
  #   wrap(klass, meth)
  #   add_contract(klass, meth, :type, contract)
  # end

  def self.method_added(meth)
    klass = self.to_s
    if $__rdl_to_wrap.member? [klass, meth]
      $__rdl_to_wrap.delete [klass, meth]
      RDL::Wrap.wrap(klass, meth)
    end
  end
  
end